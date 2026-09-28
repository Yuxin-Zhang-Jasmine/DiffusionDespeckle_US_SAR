#!/bin/bash
set -euo pipefail

#SBATCH --job-name=us11pw
#SBATCH --qos=short
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=30
#SBATCH --output=us11pw.out
#SBATCH --error=us11pw.err
#SBATCH --time=100

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

# activate micromamba
source ~/.bashrc
micromamba activate ddrm

cd "$PROJECT_ROOT"
python -u main.py \
  --runner vivo-us \
  --config imagenet_256_1c.yml \
  --doc image1c \
  --ckpt model005000.pt \
  --expeType 02_US \
  --deg Deconv \
  --nPW 11 \
  --sigma 1.2 \
  --gamma 0.015 \
  --ni
