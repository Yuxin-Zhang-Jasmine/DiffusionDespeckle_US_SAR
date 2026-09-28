# Speckle2Speckle

This directory contains the minimal Speckle2Speckle inference code used by
`PostAnalysis/02_US/a_methodsApply1.m`.

The implementation is based on:

- Rüdiger Göbl's Speckle2Speckle repository:
  https://github.com/goeblr/Speckle2Speckle
- Joey Litalien's Noise2Noise PyTorch implementation:
  https://github.com/joeylitalien/noise2noise-pytorch

## Included files

- `src/apply.py`: project-specific inference entry point
- `src/noise2noise.py`, `src/unet.py`, and `src/utils.py`: required model code
- `requirements.txt`: Python dependencies

The upstream evaluation code, example datasets, generated images, plotting
code, and training/testing utilities are intentionally omitted because they
are not used by this project's inference workflow.

## Model checkpoint

The pretrained `data/network.pt` checkpoint is not distributed in this
repository because it is not covered by the MIT license applied to the
upstream `src` directory. Download the checkpoint directly from the
[upstream Speckle2Speckle repository](https://github.com/goeblr/Speckle2Speckle)
before running inference:

```bash
mkdir -p data
curl -L \
  https://media.githubusercontent.com/media/goeblr/Speckle2Speckle/main/data/network.pt \
  -o data/network.pt
```

Expected file:

- Size: `2,801,923` bytes
- SHA-256: `84f89e90fcc3a129cce96b12c91a480f0b908d205f3a72d1136c57f224b753ff`

## Usage

The project MATLAB script invokes `src/apply.py` automatically. A direct
invocation has the following form:

```bash
python src/apply.py \
  --input-data /path/to/input.png \
  --output-data /path/to/output-directory/ \
  --load-ckpt data/network.pt \
  --cuda
```

Omit `--cuda` when running on CPU.

## License

The Python source files derived from the upstream Speckle2Speckle project are
distributed under the upstream MIT license. See the upstream repository for
the original copyright and license notice. The pretrained checkpoint is not
included and remains subject to the upstream repository's research-use terms.
