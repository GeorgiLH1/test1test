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
./aws/install --update --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --clean
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
mkdir -p /workspace/ComfyUI/models/diffusion_models

echo "=== Download models from RunPod S3 ==="
cd /workspace/ComfyUI/models/diffusion_models
aws s3 cp s3://8v3x4ixqu5/consolidated_s6700.safetensors ./consolidated_s6700.safetensors --endpoint-url https://s3api-eu-ro-1.runpod.io

cd /workspace/ComfyUI/models/loras
aws s3 cp://8v3x4ixqu5/FluxRealismLora.safetensors ./FluxRealismLora.safetensors --endpoint-url https://s3api-eu-ro-1.runpod.io
aws s3 cp://8v3x4ixqu5/FLUX.1-Turbo-Alpha.safetensors ./FLUX.1-Turbo-Alpha.safetensors --endpoint-url https://s3api-eu-ro-1.runpod.io
aws s3 cp://8v3x4ixqu5/flux_realism_lora.safetensors ./flux_realism_lora.safetensors --endpoint-url https://s3api-eu-ro-1.runpod.io
aws s3 cp://8v3x4ixqu5/my_first_lora_v1_000002500.safetensors ./my_first_lora_v1_000002500.safetensors --endpoint-url https://s3api-eu-ro-1.runpod.io
aws s3 cp://8v3x4ixqu5/openflux1-v0.1.0-fast-lora.safetensors ./openflux1-v0.1.0-fast-lora.safetensors --endpoint-url https://s3api-eu-ro-1.runpod.io
aws s3 cp://8v3x4ixqu5/perfection_style_v2d.safetensors ./perfection_style_v2d.safetensors --endpoint-url https://s3api-eu-ro-1.runpod.io

cd /workspace/ComfyUI/models/text_encoders
aws s3 cp://8v3x4ixqu5/t5xxl_fp16.safetensors ./t5xxl_fp16.safetensors --endpoint-url https://s3api-eu-ro-1.runpod.io
aws s3 cp://8v3x4ixqu5/clip_g.safetensors ./clip_g.safetensors --endpoint-url https://s3api-eu-ro-1.runpod.io
aws s3 cp://8v3x4ixqu5/ViT-L-14-BEST-smooth-GmP-ft.safetensors ./ViT-L-14-BEST-smooth-GmP-ft.safetensors --endpoint-url https://s3api-eu-ro-1.runpod.io

cd /workspace/ComfyUI/user/default/workflows
aws s3 cp://8v3x4ixqu5/workflow-flux-dev-de-distilled-ultra-realistic-detailed-portraits-at-only-8-steps-turbo-jlUGbGhkafepByeJPeV9-caiman_thirsty_60-openart.ai.json ./workflow-flux-dev-de-distilled-ultra-realistic-detailed-portraits-at-only-8-steps-turbo-jlUGbGhkafepByeJPeV9-caiman_thirsty_60-openart.ai.json --endpoint-url https://s3api-eu-ro-1.runpod.io

echo "=== DONE: Starting ComfyUI ==="
cd /workspace/ComfyUI
python3 main.py --listen 0.0.0.0 --port 8188
