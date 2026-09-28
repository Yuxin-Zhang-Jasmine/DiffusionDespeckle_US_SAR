# Diffusion restoration experiments for ultrasound and SAR

This repository contains diffusion-restoration experiments and MATLAB
post-analysis code for numerical images, ultrasound (US), and synthetic
aperture radar (SAR) data.

## Repository layout

- `DiffusionRestoration/`: Python diffusion inference, experiment runners,
  input observations, and the reproducible Conda environment.
- `PostAnalysis/02_US/`: ultrasound baseline methods, evaluation, and figure
  scripts.
- `PostAnalysis/03_SAR/`: SAR baseline methods, evaluation, and figure
  scripts.
- `PostAnalysis/src/`: shared MATLAB utilities and redistributable
  third-party implementations.
- `mdls/`: fitted empirical models used during post-analysis.

Generated `results/` directories are normally not versioned. Two selected
result sets are included: SAR spotlight patch 388 and ultrasound 11pw/ER.
MATLAB `.fig` files, IDE metadata, and the large diffusion checkpoint are
intentionally not versioned.

## Python environment

Create the environment without installing it into any machine-specific path:

```bash
cd DiffusionRestoration
conda env create -f environment.yml
conda activate ddrm
```

The removed Conda `prefix` only specified the original author's local
installation directory; removing it does not change the dependency list.

## Diffusion checkpoint

Download `model005000.pt` from the public
[Google Drive folder](https://drive.google.com/drive/folders/1P6SJsx2ASRMGTloIONNcag8Ae8tFDEUy?usp=sharing)
and place it at:

```text
DiffusionRestoration/exp/logs/image1c/model005000.pt
```

Expected size: `2,211,352,679` bytes  
Expected SHA-256:
`385f8fe9302c5b45ed451e2969de4ae930e7c92d20e794eb0ab18409afac27e8`

Verify it with:

```bash
sha256sum DiffusionRestoration/exp/logs/image1c/model005000.pt
```

## Running diffusion inference

Run commands from `DiffusionRestoration/`. Select the experiment explicitly
with `--runner`:

| Runner | Data |
| --- | --- |
| `numerical` | numerical sensitivity experiment |
| `vitro-us` | ultrasound phantom |
| `vivo-us` | in-vivo ultrasound |
| `urban-sar` | SAR patches 11, 12, and 14 |
| `seaside-sar-50` | SAR patch 50 |
| `seaside-sar-388` | SAR patch 388 |

Example:

```bash
cd DiffusionRestoration
python main.py \
  --runner urban-sar \
  --config imagenet_256_1c.yml \
  --doc image1c \
  --ckpt model005000.pt \
  --expeType 03_SAR \
  --deg Deconv \
  --gamma 0.045 \
  --sigma 0.95 \
  --ni
```

Portable Slurm examples are included under `01_nume/`, `02_US/`, and
`03_SAR/`. The second SAR script accepts
`SAR_RUNNER=seaside-sar-388 sbatch 03_SAR/sarSL_imag2.sl` to select patch
388; its default is patch 50.

## MATLAB post-analysis

The main baseline runners are:

- `PostAnalysis/02_US/a_methodsApply1.m`
- `PostAnalysis/03_SAR/a_methodsApply.m`

Both scripts contain the original machine-specific `ddrmPython` path.
Before reproducing the experiments, edit that variable to point to the Python
executable in your own `ddrm` environment.

FANS, OBNLM, and DNN-lambda are not distributed for licensing reasons. The
MATLAB runners now warn and continue when those optional methods are absent.
Speckle2Speckle source code is included, but its pretrained weight must be
downloaded separately using the instructions in
`PostAnalysis/src/SOTApython/Speckle2Speckle/README.md`.

Only the SCUNet `scunet_color_real_gan.pth` weight used by the project is
versioned. The unused gray-model weights are omitted and can be downloaded
with SCUNet's upstream `main_download_pretrained_models.py` utility if
needed.

Run the diffusion stage first, then the `a_*.m` method scripts, followed by
the `b_*.m` evaluation scripts. Evaluation skips methods whose result files
are absent. The later `c_*.m` through `f_*.m` publication-figure scripts
retain the paper's fixed method lists; exact original figures therefore
require results from the optional excluded baselines.

## Licensing

Project-authored software is released under the MIT License. Bundled
third-party components retain their own licenses; see
`THIRD_PARTY_NOTICES.md`. Datasets, pretrained weights, and other non-code
assets are not automatically relicensed under MIT.
