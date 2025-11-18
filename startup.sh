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
# 4. Install PyTorch (CUDA 12.1)
########################################
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

########################################
# 5. WAIT FOR RUNPOD STORAGE CREDS
########################################
echo "Waiting for AWS credentials from RunPod..."

while [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ] || [ -z "$AWS_ENDPOINT_URL" ]; do
    echo "Still waiting for AWS credentials..."
    sleep 1
done

echo "AWS credentials detected."

ENDPOINT="$AWS_ENDPOINT_URL"
BUCKET="s3://8v3x4ixqu5"

########################################
# 6. Download models from S3
########################################
aws s3 cp "$BUCKET/consolidated_s6700.safetensors" models/diffusion_models/ --endpoint-url "$ENDPOINT"

aws s3 cp "$BUCKET/FluxRealismLora.safetensors" models/loras/ --endpoint-url "$ENDPOINT"
aws s3 cp "$BUCKET/FLUX.1-Turbo-Alpha.safetensors" models/loras/ --endpoint-url "$ENDPOINT"
aws s3 cp "$BUCKET/flux_realism_lora.safetensors" models/loras/ --endpoint-url "$ENDPOINT"
aws s3 cp "$BUCKET/my_first_lora_v1_000002500.safetensors" models/loras/ --endpoint-url "$ENDPOINT"
aws s3 cp "$BUCKET/openflux1-v0.1.0-fast-lora.safetensors" models/loras/ --endpoint-url "$ENDPOINT"

aws s3 cp "$BUCKET/t5xxl_fp16.safetensors" models/text_encoders/ --endpoint-url "$ENDPOINT"
aws s3 cp "$BUCKET/clip_g.safetensors" models/text_encoders/ --endpoint-url "$ENDPOINT"
aws s3 cp "$BUCKET/ViT-L-14-BEST-smooth-GmP-ft.safetensors" models/text_encoders/ --endpoint-url "$ENDPOINT"

aws s3 cp "$BUCKET/workflow-flux-dev-de-distilled-ultra-realistic-detailed-portraits-at-only-8-steps-turbo-jlUGbGhkafepByeJPeV9-caiman_thirsty_60-openart.ai.json" \
    user/default/workflows/ --endpoint-url "$ENDPOINT"

########################################
# 7. Download custom_nodes (NO LOOP FIX)
########################################
aws s3 cp "$BUCKET/custom_nodes" custom_nodes/ \
    --recursive \
    --exclude ".git/*" \
    --exclude ".git*" \
    --endpoint-url "$ENDPOINT"

########################################
# 8. Start ComfyUI
########################################
python main.py --listen --port 8188
