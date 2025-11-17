#!/bin/bash

########################################
# 1. Install system dependencies
########################################
apt-get update -qq && apt-get install -yq \
    python3 python3-pip git git-lfs unzip wget curl vim nano \
    build-essential ca-certificates libgl1 libglib2.0-0 ffmpeg \
    libsm6 libxext6 libxrender-dev && apt-get clean

pip install --upgrade pip

########################################
# 2. Install AWS CLI v2
########################################
wget -q https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip
unzip -q awscli-exe-linux-x86_64.zip
./aws/install
export PATH=$PATH:/usr/local/bin
rm -rf aws awscli-exe-linux-x86_64.zip

########################################
# 3. Clone or update ComfyUI
########################################
if [ ! -d "/workspace/ComfyUI" ]; then
    git clone https://github.com/comfyanonymous/ComfyUI.git /workspace/ComfyUI
fi

cd /workspace/ComfyUI
git pull

########################################
# 4. Create required folders (INSIDE ComfyUI)
########################################
mkdir -p models/diffusion_models
mkdir -p models/loras
mkdir -p models/text_encoders
mkdir -p user/default/workflows
mkdir -p custom_nodes

########################################
# 5. Install PyTorch (CUDA 12.1 wheels)
########################################
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

########################################
# 6. Wait for RunPod AWS credentials to become active
########################################
ENDPOINT="https://s3api-eu-ro-1.runpod.io"
BUCKET="s3://8v3x4ixqu5"

echo "Waiting for AWS credentials..."
until aws sts get-caller-identity --endpoint-url "$ENDPOINT" >/dev/null 2>&1; do
    sleep 2
done
echo "AWS credentials detected."

########################################
# 7. Download files (only if missing)
########################################

# Diffusion model
if [ ! -f models/diffusion_models/consolidated_s6700.safetensors ]; then
    aws s3 cp "$BUCKET/consolidated_s6700.safetensors" models/diffusion_models/ --endpoint-url "$ENDPOINT"
fi

# Loras
[ -f models/loras/FluxRealismLora.safetensors ] || aws s3 cp "$BUCKET/FluxRealismLora.safetensors" models/loras/ --endpoint-url "$ENDPOINT"
[ -f models/loras/FLUX.1-Turbo-Alpha.safetensors ] || aws s3 cp "$BUCKET/FLUX.1-Turbo-Alpha.safetensors" models/loras/ --endpoint-url "$ENDPOINT"
[ -f models/loras/flux_realism_lora.safetensors ] || aws s3 cp "$BUCKET/flux_realism_lora.safetensors" models/loras/ --endpoint-url "$ENDPOINT"
[ -f models/loras/my_first_lora_v1_000002500.safetensors ] || aws s3 cp "$BUCKET/my_first_lora_v1_000002500.safetensors" models/loras/ --endpoint-url "$ENDPOINT"
[ -f models/loras/openflux1-v0.1.0-fast-lora.safetensors ] || aws s3 cp "$BUCKET/openflux1-v0.1.0-fast-lora.safetensors" models/loras/ --endpoint-url "$ENDPOINT"

# Text encoders
[ -f models/text_encoders/t5xxl_fp16.safetensors ] || aws s3 cp "$BUCKET/t5xxl_fp16.safetensors" models/text_encoders/ --endpoint-url "$ENDPOINT"
[ -f models/text_encoders/clip_g.safetensors ] || aws s3 cp "$BUCKET/clip_g.safetensors" models/text_encoders/ --endpoint-url "$ENDPOINT"
[ -f models/text_encoders/ViT-L-14-BEST-smooth-GmP-ft.safetensors ] || aws s3 cp "$BUCKET/ViT-L-14-BEST-smooth-GmP-ft.safetensors" models/text_encoders/ --endpoint-url "$ENDPOINT"

# Workflow
[ -f user/default/workflows/workflow-flux-dev-de-distilled-ultra-realistic-detailed-portraits-at-only-8-steps-turbo.json ] || \
aws s3 cp "$BUCKET/workflow-flux-dev-de-distilled-ultra-realistic-detailed-portraits-at-only-8-steps-turbo-jlUGbGhkafepByeJPeV9-caiman_thirsty_60-openart.ai.json" \
    user/default/workflows/ --endpoint-url "$ENDPOINT"

########################################
# 8. Sync custom nodes (safe, no duplicate downloads)
########################################
aws s3 sync "$BUCKET/custom_nodes/" custom_nodes/ --endpoint-url "$ENDPOINT"

########################################
# 9. Start ComfyUI
########################################
nohup python main.py --listen --port 8188 > comfyui.log 2>&1 &
echo "ComfyUI started on port 8188"
