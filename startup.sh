#!/bin/bash

set -e

echo "=== Updating system packages ==="
apt-get update -qq
apt-get install -yq \
    python3 python3-pip python3-venv \
    git git-lfs \
    unzip wget curl \
    ffmpeg libgl1 libglib2.0-0 \
    build-essential \
    ca-certificates \
    && apt-get clean

echo "=== Install AWS CLI v2 ==="
cd /tmp
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -qq awscliv2.zip
./aws/install
rm -rf aws awscliv2.zip
echo "AWS version: $(aws --version)"

echo "=== Prepare workspace ==="
cd /workspace
if [ ! -d "ComfyUI" ]; then
    git clone https://github.com/comfyanonymous/ComfyUI.git
fi

echo "=== Install ComfyUI dependencies ==="
pip install --upgrade pip
pip install -r /workspace/ComfyUI/requirements.txt

echo "=== Prepare custom_nodes folder ==="
mkdir -p /workspace/ComfyUI/custom_nodes

echo "=== DONE: Starting ComfyUI ==="
cd /workspace/ComfyUI
python3 main.py --listen 0.0.0.0 --port 8188

