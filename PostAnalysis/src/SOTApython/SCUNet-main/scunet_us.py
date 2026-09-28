import os.path
import logging
import argparse

import numpy as np
from datetime import datetime
from collections import OrderedDict

import torch
from pkg_resources import require

from utils import utils_logger
from utils import utils_model
from utils import utils_image as util


def main():
    # ----------------------------------------
    # Preparation
    # ----------------------------------------
    parser = argparse.ArgumentParser()
    parser.add_argument('--model_name', type=str, required=True)
    parser.add_argument(
        '--model_zoo',
        type=str,
        default=os.path.join(os.path.dirname(os.path.abspath(__file__)), 'model_zoo')
    )
    parser.add_argument('--input_data', type=str, required=True)
    parser.add_argument('--output_data', type=str, required=True)
    args = parser.parse_args()
    device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
    model_path = os.path.join(args.model_zoo, args.model_name+'.pth')
    L_path = args.input_data   # L_path, for Low-quality images
    E_path = args.output_data  # E_path, for Estimated images

    # ------------------------------------
    # load model
    # ------------------------------------
    n_channels = 3
    if 'gray' in args.model_name.lower():
        n_channels = 1
    from models.network_scunet import SCUNet as net
    model = net(in_nc=n_channels,config=[4,4,4,4,4,4,4],dim=64)
    model.load_state_dict(torch.load(model_path), strict=True)
    model.eval()
    for k, v in model.named_parameters():
        v.requires_grad = False
    model = model.to(device)

    img = L_path + '/' + L_path.split('/')[-2] + '_1.png'
    # ------------------------------------
    # (1) img_L
    # ------------------------------------
    ## if load .png
    img_L = util.imread_uint(img, n_channels=n_channels)
    img_L = util.uint2tensor4(img_L)
    img_L = img_L.to(device)
    ## if load .mat
    # img_L = util.imread_mat2tensor(img, n_channels=n_channels)
    # img_L = img_L.to(device)

    # ------------------------------------
    # (2) img_E
    # ------------------------------------
    img_E = model(img_L)

    # ------------------------------------
    # save results
    # ------------------------------------
    util.imsavemat(img_E, os.path.join(E_path, 'result.mat'))

    img_Epng = util.tensor2uint(img_E)  # 0-255 (H, W ,C)
    util.imsave(img_Epng, os.path.join(E_path, 'pic.png'))
    print(args.model_name)
    print(n_channels)
if __name__ == '__main__':

    main()
