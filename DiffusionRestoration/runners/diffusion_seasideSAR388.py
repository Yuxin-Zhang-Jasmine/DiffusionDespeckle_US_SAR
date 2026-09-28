import os
from math import sqrt, pi, ceil
import numpy as np
import torch
from functions.ckpt_util import download
from functions.denoising import efficient_generalized_steps
from guided_diffusion.script_util import create_model
import mat73
from scipy.io import savemat


def get_beta_schedule(beta_schedule, *, beta_start, beta_end, num_diffusion_timesteps):
    def sigmoid(x):
        return 1 / (np.exp(-x) + 1)

    if beta_schedule == "quad":
        betas = (
                np.linspace(
                    beta_start ** 0.5,
                    beta_end ** 0.5,
                    num_diffusion_timesteps,
                    dtype=np.float64,
                )
                ** 2
        )
    elif beta_schedule == "linear":
        betas = np.linspace(
            beta_start, beta_end, num_diffusion_timesteps, dtype=np.float64
        )
    elif beta_schedule == "const":
        betas = beta_end * np.ones(num_diffusion_timesteps, dtype=np.float64)
    elif beta_schedule == "jsd":  # 1/T, 1/(T-1), 1/(T-2), ..., 1
        betas = 1.0 / np.linspace(
            num_diffusion_timesteps, 1, num_diffusion_timesteps, dtype=np.float64
        )
    elif beta_schedule == "sigmoid":
        betas = np.linspace(-6, 6, num_diffusion_timesteps)
        betas = sigmoid(betas) * (beta_end - beta_start) + beta_start
    else:
        raise NotImplementedError(beta_schedule)
    assert betas.shape == (num_diffusion_timesteps,)
    return betas


class Diffusion(object):
    def __init__(self, args, config, device=None):
        self.args = args
        self.config = config
        if device is None:
            device = (
                torch.device("cuda")
                if torch.cuda.is_available()
                else torch.device("cpu")
            )
        self.device = device

        self.model_var_type = config.model.var_type
        betas = get_beta_schedule(
            beta_schedule=config.diffusion.beta_schedule,
            beta_start=config.diffusion.beta_start,
            beta_end=config.diffusion.beta_end,
            num_diffusion_timesteps=config.diffusion.num_diffusion_timesteps,
        )
        betas = self.betas = torch.from_numpy(betas).float().to(self.device)
        self.num_timesteps = betas.shape[0]

        alphas = 1.0 - betas
        alphas_cumprod = alphas.cumprod(dim=0)
        alphas_cumprod_prev = torch.cat(
            [torch.ones(1).to(device), alphas_cumprod[:-1]], dim=0
        )
        self.alphas_cumprod_prev = alphas_cumprod_prev
        posterior_variance = (
                betas * (1.0 - alphas_cumprod_prev) / (1.0 - alphas_cumprod)
        )
        if self.model_var_type == "fixedlarge":
            self.logvar = betas.log()
            # torch.cat(
            # [posterior_variance[1:2], betas[1:]], dim=0).log()
        elif self.model_var_type == "fixedsmall":
            self.logvar = posterior_variance.clamp(min=1e-20).log()

    def sample(self):
        cls_fn = None
        config_dict = vars(self.config.model)
        model = create_model(**config_dict)
        if self.config.model.use_fp16:
            model.convert_to_fp16()
        ckpt = os.path.join(self.args.log_path, self.args.ckpt)
        print('Path of the current ckpt: ' + ckpt)
        model.load_state_dict(torch.load(ckpt, map_location=self.device))
        model.to(self.device)
        model.eval()
        model = torch.nn.DataParallel(model)
        self.sample_sequence(model, cls_fn)

    def sample_sequence(self, model, cls_fn=None):
        args, config = self.args, self.config

        # ** get SVD results of the model matrix **
        scale1 = 1
        print(f'Loading the degradation function/matrix  and it\'s svd ({self.args.deg})')
        if self.args.deg == "Deno":
            from functions.svd_replacement import Denoising
            H_funcs = Denoising(config.data.channels, self.config.data.image_size, self.device)
        elif self.args.deg == 'Deconv':
            from functions.svd_replacement import Deblurring2D
            sigmaLat = self.args.sigma   # default 1.2
            kerHalfLen = ceil(2 * sigmaLat)
            pdf = lambda x: torch.exp(torch.Tensor([-0.5 * (x / sigmaLat) ** 2]))
            kernel2 = torch.Tensor([pdf(i) for i in range(-kerHalfLen, 0, 1)] + [pdf(i) for i in range(kerHalfLen + 1)]).to(self.device)

            sigmaAxi = self.args.sigma  #  vivo uses  0.2
            kerHalfLen = ceil(2 * sigmaAxi)
            # pdf = lambda x: torch.cos(torch.Tensor([2*pi*0.5*x])) * torch.exp(torch.Tensor([-0.5 * (x/sigma)**2]))
            pdf = lambda x: torch.exp(torch.Tensor([-0.5 * (x / sigmaAxi) ** 2]))
            kernel1 = torch.Tensor([pdf(i) for i in range(-kerHalfLen, 0, 1)] + [pdf(i) for i in range(kerHalfLen + 1)]).to(self.device)

            H_funcs = Deblurring2D(kernel1 / kernel1.sum(), kernel2 / kernel2.sum(), config.data.channels, self.config.data.image_size, self.device)
            if args.sigma == 1.2:
                scale1 = 0.85  # to compensating the effects of the inverse of H     =0.85 for vivo with sigmaAxi=0.2
            else:
                scale1 = 1

        else:
            print("ERROR: problem_model (--deg) type not supported")
            quit()
        print("data channels : " + str(config.data.channels))
        print("model in_channels : " + str(config.model.in_channels))

        gamma = args.gamma  # default is 0.1
        scale2 = 0.65   # 0.87 used in US   # to avoid the bounding effects (values close to -1 and 1 have low uncertainty)
        scale = scale1 * scale2
        repeat = 200  # 20 used in US
        timestepsLst = [50] * repeat
        for phaname in ['388']:
            # if it already exists, the code proceeds without any errors.
            observsPath = os.path.join(args.expeType, 'observs/spotlight', phaname)
            print('Observation loaded from: ' + observsPath)  # .../01_SAR/observs/spotlight/50/
            resultsPath = os.path.join(args.expeType, 'results/spotlight', phaname)
            print('Results will be saved to: ' + resultsPath)  # .../01_SAR/results/spotlight/50/
            os.makedirs(resultsPath, exist_ok=True)

            print('----------------------------------------------------------------------------')
            print('Load observations (the real and the imaginary maps)')
            print('----------------------------------------------------------------------------')
            Ireal = scale * torch.from_numpy(mat73.loadmat(observsPath + '/observI.mat')['observ'])
            Iimag = scale * torch.from_numpy(mat73.loadmat(observsPath + '/observQ.mat')['observ'])
            print("Original shape of Ireal:", Ireal.shape)
            print("Maximum value of Ireal:", Ireal.max())
            print("Minimum value of Ireal:", Ireal.min())

            Ireal = Ireal.reshape(1, -1).to(self.device)
            Iimag = Iimag.reshape(1, -1).to(self.device) # (1,65536)

            print('----------------------------------------------------------------------------')
            print('Start restoration')
            print(f"repeat {repeat} times for each observation")
            print('----------------------------------------------------------------------------')
            idx_so_far = 0
            for _ in range(repeat):
                timesteps = timestepsLst[idx_so_far]
                x = torch.randn(
                    1,
                    config.data.channels,
                    config.data.image_size,
                    config.data.image_size,
                    device=self.device,
                )
                print('restore the REAL part')
                with torch.no_grad():
                    Ix, _ = self.sample_image(x, model, H_funcs, Ireal, float(gamma), last=False, cls_fn=cls_fn, timesteps=timesteps)
                savemat(os.path.join(resultsPath, f"I{idx_so_far + 1}_{-1}.mat"),
                        {'Ix': Ix[-1][0].detach().cpu().numpy()})

                print('restore the IMAGINARY part')
                with torch.no_grad():
                    Qx, _ = self.sample_image(x, model, H_funcs, Iimag, float(gamma), last=False, cls_fn=cls_fn, timesteps=timesteps)
                savemat(os.path.join(resultsPath, f"Q{idx_so_far + 1}_{-1}.mat"),
                        {'Qx': Qx[-1][0].detach().cpu().numpy()})

                idx_so_far += 1  # iterate multiple images
                print(f'Finish {idx_so_far}')

    def sample_image(self, x, model, H_funcs, y_0, gamma, last=False, cls_fn=None, classes=None, timesteps=50):
        skip = self.num_timesteps // timesteps
        seq = range(0, self.num_timesteps, skip)
        x = efficient_generalized_steps(x, seq, model, self.betas, H_funcs, y_0, gamma, etaB=self.args.etaB,
                                        etaA=self.args.eta, etaC=self.args.eta, cls_fn=cls_fn, classes=classes)
        if last:
            x = x[0][-1]
        return x
