#!/bin/bash
set -euo pipefail

#SBATCH --job-name=001Deno
#SBATCH --qos=short
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=20
#SBATCH --output=001Deno.out
#SBATCH --error=001Deno.err
#SBATCH --time=1200

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"

# activate micromamba
source ~/.bashrc
micromamba activate ddrm

cd "$PROJECT_ROOT"
python -u main.py \
  --runner numerical \
  --config imagenet_256_1c.yml \
  --doc image1c \
  --ckpt model005000.pt \
  --expeType 01_nume \
  --timesteps 50 \
  --deg Deno \
  --nratio 0.011 \
  --phansType Phans-exp4x \
  --ni
