#!/bin/bash
set -e

# Script to package Python dependencies for Lambda Layer
# Usage: ./package-layer.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LAYER_DIR="$PROJECT_ROOT/layers"
PYTHON_DIR="$LAYER_DIR/python"
ZIP_FILE="$LAYER_DIR/python-dependencies.zip"

echo "[INFO] Packaging Lambda Layer dependencies..."

# Create directories
mkdir -p "$PYTHON_DIR"

# Install dependencies
echo "[INFO] Installing Python dependencies..."
pip install PyPDF2 docx2txt boto3 -t "$PYTHON_DIR" --upgrade

# Create zip file
echo "[INFO] Creating zip file..."
cd "$LAYER_DIR"
rm -f python-dependencies.zip
zip -r python-dependencies.zip python/

echo "[INFO] Layer package created at: $ZIP_FILE"
echo "[INFO] Size: $(du -h "$ZIP_FILE" | cut -f1)"
echo "[INFO] Done!"
