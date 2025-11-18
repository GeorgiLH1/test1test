#!/bin/bash

########################################
# 1. System packages
########################################
apt-get update -qq && apt-get install -yq \
    python3 python3-pip git git-lfs unzip wget curl vim nano \
    build-essential ca-certificates libgl1 libglib2.0-0 ffmpeg \
    libsm6 libxext6 libxrender-dev && apt-get clean

pip install --upgrade pip

########################################
# 2. Clone or update ComfyUI
########################################
if [ ! -d "/workspace/ComfyUI" ]; then
    git clone https://github.com/comfyanonymous/ComfyUI.git /workspace/ComfyUI
fi

cd /workspace/ComfyUI

git config --global --add safe.directory /workspace/ComfyUI
git pull
git lfs install
git lfs pull

########################################
# 3. Install PyTorch (CUDA 12.1)
########################################
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

########################################
# 4. Install ComfyUI Python dependencies
########################################
pip install -r requirements.txt

########################################
# 5. Start ComfyUI
########################################
python main.py --listen --port 8188
