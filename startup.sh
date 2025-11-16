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
# 2. Install AWS CLI v2
########################################
wget https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip
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
# 4. Create required folders
########################################
mkdir -p models/diffusion_models
mkdir -p models/loras
mkdir -p models/text_encoders
mkdir -p user/default/workflows
mkdir -p custom_nodes

########################################
# 5. Install PyTorch (CUDA 12 compatible)
########################################
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

########################################
# 6. Download models from RunPod S3 storage
########################################
ENDPOINT="https://s3api-eu-ro-1.runpod.io"
BUCKET="s3://8v3x4ixqu5"

# Diffusion model
aws s3 cp $BUCKET/consolidated_s6700.safetensors models/diffusion_models/ --endpoint-url $ENDPOINT || true

# Loras
aws s3 cp $BUCKET/FluxRealismLora.safetensors models/loras/ --endpoint-url $ENDPOINT || true
aws s3 cp $BUCKET/FLUX.1-Turbo-Alpha.safetensors models/loras/ --endpoint-url $ENDPOINT || true
aws s3 cp $BUCKET/flux_realism_lora.safetensors models/loras/ --endpoint-url $ENDPOINT || true
aws s3 cp $BUCKET/my_first_lora_v1_000002500.safetensors models/loras/ --endpoint-url $ENDPOINT || true
aws s3 cp $BUCKET/openflux1-v0.1.0-fast-lora.safetensors models/loras/ --endpoint-url $ENDPOINT || true

# Text encoders
aws s3 cp $BUCKET/t5xxl_fp16.safetensors models/text_encoders/ --endpoint-url $ENDPOINT || true
aws s3 cp $BUCKET/clip_g.safetensors models/text_encoders/ --endpoint-url $ENDPOINT || true
aws s3 cp $BUCKET/ViT-L-14-BEST-smooth-GmP-ft.safetensors models/text_encoders/ --endpoint-url $ENDPOINT || true

# Workflow
aws s3 cp $BUCKET/workflow-flux-dev-de-distilled-ultra-realistic-detailed-portraits-at-only-8-steps-turbo-jlUGbGhkafepByeJPeV9-caiman_thirsty_60-openart.ai.json \
    user/default/workflows/ --endpoint-url $ENDPOINT || true

# Custom nodes
aws s3 sync $BUCKET/custom_nodes/ custom_nodes/ --endpoint-url $ENDPOINT || true

########################################
# 7. Start ComfyUI
########################################
nohup python main.py --listen --port 8188 > comfyui.log 2>&1 &

echo "ComfyUI started on port 8188"
