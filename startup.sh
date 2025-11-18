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
# 2. Install AWS CLI v2 (does nothing now)
########################################
wget -q https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip
unzip -q awscli-exe-linux-x86_64.zip
./aws/install
rm -rf aws awscli-exe-linux-x86_64.zip

########################################
# 3. Clone or update ComfyUI
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
# 4. Install PyTorch (CUDA 12.1 — your current choice)
########################################
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

########################################
# 5. Install missing Python modules ComfyUI uses
########################################
pip install tqdm pillow numpy

########################################
# 6. Run ComfyUI
########################################
python main.py --listen --port 8188
