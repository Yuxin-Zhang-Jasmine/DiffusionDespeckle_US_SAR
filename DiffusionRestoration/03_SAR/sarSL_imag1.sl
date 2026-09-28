#!/bin/bash
set -euo pipefail

#SBATCH --job-name=sarSL1
#SBATCH --qos=short
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=30
#SBATCH --output=sarSL1.out
#SBATCH --error=sarSL1.err
#SBATCH --time=200

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

# activate micromamba
source ~/.bashrc
micromamba activate ddrm

cd "$PROJECT_ROOT"
python -u main.py \
  --runner urban-sar \
  --config imagenet_256_1c.yml \
  --doc image1c \
  --ckpt model005000.pt \
  --expeType 03_SAR \
  --deg Deconv \
  --gamma 0.045 \
  --sigma 0.95 \
  --ni
