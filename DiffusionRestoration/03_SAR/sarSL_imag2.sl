#!/bin/bash
set -euo pipefail

#SBATCH --job-name=sarSL2
#SBATCH --qos=short
#SBATCH --partition=gpu
#SBATCH --gres=gpu:1
#SBATCH --cpus-per-task=30
#SBATCH --output=sarSL2.out
#SBATCH --error=sarSL2.err
#SBATCH --time=500

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
SAR_RUNNER="${SAR_RUNNER:-seaside-sar-50}"

# activate micromamba
source ~/.bashrc
micromamba activate ddrm

cd "$PROJECT_ROOT"
python -u main.py \
  --runner "$SAR_RUNNER" \
  --config imagenet_256_1c.yml \
  --doc image1c \
  --ckpt model005000.pt \
  --expeType 03_SAR \
  --deg Deconv \
  --gamma 0.011 \
  --sigma 0.8 \
  --ni
