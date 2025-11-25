#!/bin/bash

# --- CONFIGURATION ---
RUNPOD_S3_ENDPOINT="https://s3api-eu-ro-1.runpod.io"
BUCKET_NAME="8v3x4ixqu5"

# Function to handle errors without crashing the pod loop
handle_error() {
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    echo "ERROR OCCURRED: $1"
    echo "Sleeping forever so you can debug inside the Web Terminal..."
    echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
    sleep infinity
}

echo "=== 1. Updating system packages ==="
apt-get update -qq || handle_error "Apt-get update failed"
apt-get install -yq \
    python3 python3-pip python3-venv \
    git git-lfs \
    unzip wget curl \
    ffmpeg libgl1 libglib2.0-0 \
    build-essential \
    ca-certificates \
    && apt-get clean || handle_error "Package installation failed"

echo "=== 2. Install AWS CLI v2 ==="
if ! command -v aws &> /dev/null; then
    curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -qq awscliv2.zip
    ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update || handle_error "AWS CLI Install Failed"
    rm -rf aws awscliv2.zip
else
    echo "AWS CLI already installed."
fi

echo "=== 3. Prepare workspace ==="
cd /workspace
if [ ! -d "ComfyUI" ]; then
    git clone https://github.com/comfyanonymous/ComfyUI.git || handle_error "Git Clone Failed"
else
    echo "ComfyUI already cloned."
fi

echo "=== 4. Install ComfyUI dependencies ==="
pip install --upgrade pip
if [ -f "/workspace/ComfyUI/requirements.txt" ]; then
    pip install -r /workspace/ComfyUI/requirements.txt --no-cache-dir || echo "Warning: Some pip requirements failed, continuing..."
fi

#=====Install Nodes=======
cd /workspace/ComfyUI/custom_nodes
git clone https://github.com/Acly/comfyui-tooling-nodes.git
git clone https://github.com/Comfy-Org/ComfyUI-Manager.git

# --- HELPER FUNCTION FOR DOWNLOADS ---
download_if_missing() {
    local filename=$1
    local s3_key=$2
    local target_dir=$3

    mkdir -p "$target_dir"
    cd "$target_dir"

    if [ -f "$filename" ]; then
        echo "   [SKIP] $filename already exists."
    else
        echo "   [DOWNLOADING] $filename from bucket $BUCKET_NAME..."
        
        # This is the critical command. If credentials are wrong, this will print the error.
        aws s3 cp "s3://${BUCKET_NAME}/${s3_key}" "./${filename}" --endpoint-url "$RUNPOD_S3_ENDPOINT"
        
        # Check if the download actually worked
        if [ $? -ne 0 ]; then
            echo "   [ERROR] Failed to download $filename. Check your AWS_ACCESS_KEY_ID!"
            # We do NOT stop the script here, we let it try the next file.
        fi
    fi
}

echo "=== 5. Download models from RunPod S3 ==="

# --- VAE ---
echo "--- Checking vaes ---"
VAE_DIR="/workspace/ComfyUI/models/vae"

download_if_missing "ae.safetensors" "ae.safetensors" "$VAE_DIR"

# --- Checkpoints ---
echo "--- Checking Checkpoints ---"
download_if_missing \
    "consolidated_s6700.safetensors" \
    "consolidated_s6700.safetensors" \
    "/workspace/ComfyUI/models/diffusion_models"

# --- Loras ---
echo "--- Checking Loras ---"
LORA_DIR="/workspace/ComfyUI/models/loras"

download_if_missing "FluxRealismLora.safetensors" "FluxRealismLora.safetensors" "$LORA_DIR"
download_if_missing "FLUX.1-Turbo-Alpha.safetensors" "FLUX.1-Turbo-Alpha.safetensors" "$LORA_DIR"
download_if_missing "flux_realism_lora.safetensors" "flux_realism_lora.safetensors" "$LORA_DIR"
download_if_missing "my_first_lora_v1_000002500.safetensors" "my_first_lora_v1_000002500.safetensors" "$LORA_DIR"
download_if_missing "openflux1-v0.1.0-fast-lora.safetensors" "openflux1-v0.1.0-fast-lora.safetensors" "$LORA_DIR"
download_if_missing "perfection_style_v2d.safetensors" "perfection_style_v2d.safetensors" "$LORA_DIR"

# --- Text Encoders ---
echo "--- Checking Text Encoders ---"
TE_DIR="/workspace/ComfyUI/models/text_encoders"

download_if_missing "t5xxl_fp16.safetensors" "t5xxl_fp16.safetensors" "$TE_DIR"
download_if_missing "clip_g.safetensors" "clip_g.safetensors" "$TE_DIR"
download_if_missing "ViT-L-14-BEST-smooth-GmP-ft.safetensors" "ViT-L-14-BEST-smooth-GmP-ft.safetensors" "$TE_DIR"

# --- Workflows ---
echo "--- Checking Workflows ---"
WORKFLOW_DIR="/workspace/ComfyUI/user/default/workflows"
WORKFLOW_FILE="workflow-flux-dev-de-distilled-ultra-realistic-detailed-portraits-at-only-8-steps-turbo-jlUGbGhkafepByeJPeV9-caiman_thirsty_60-openart.ai.json"
download_if_missing "$WORKFLOW_FILE" "$WORKFLOW_FILE" "$WORKFLOW_DIR"

echo "=== DONE: Starting ComfyUI ==="
cd /workspace/ComfyUI
# We use 'python3' and ensure it doesn't exit immediately
python3 main.py --listen 0.0.0.0 --port 8188
