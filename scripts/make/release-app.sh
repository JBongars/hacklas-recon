#!/bin/bash
set -euo pipefail

# Set default values (assume Kali/Debian amd64)
ARCH="${ARCH:-$(dpkg --print-architecture 2>/dev/null || echo "amd64")}"
APP_NAME="${APP_NAME:-hacklas-recon}"
RELEASE_DIR="${RELEASE_DIR:-release/$ARCH}"

echo "Creating application release package for $ARCH..."
mkdir -p "$RELEASE_DIR/app-tmp"

# Build the application with Poetry
poetry build

# Export dependencies as requirements.txt and download all wheels
poetry export -f requirements.txt --output "$RELEASE_DIR/app-tmp/requirements.txt" --without-hashes

# Download all dependency wheels
pip3 download -r "$RELEASE_DIR/app-tmp/requirements.txt" -d "$RELEASE_DIR/app-tmp/wheels/"

# Copy built wheel to wheels directory
cp dist/*.whl "$RELEASE_DIR/app-tmp/wheels/"

# Create installation script
cat > "$RELEASE_DIR/app-tmp/install.sh" <<'EOF'
#!/bin/bash
set -e

echo "Installing hacklas-recon and dependencies..."
pip3 install --user --no-index --find-links=wheels/ wheels/*.whl

echo "Installation complete!"
echo "Run: python3 -m hacklas-recon"
echo ""
echo "Note: Make sure ~/.local/bin is in your PATH"
echo "Add this to your ~/.bashrc if needed:"
echo '  export PATH="$HOME/.local/bin:$PATH"'
EOF
chmod +x "$RELEASE_DIR/app-tmp/install.sh"

# Create README
cat > "$RELEASE_DIR/app-tmp/README.txt" <<'EOF'
Application Package (Airgapped Installation)
=============================================

This package contains all Python dependencies as wheel files.
No internet connection or Poetry required.

Installation (no root required):
1. Extract this archive
2. Run: ./install.sh

Manual installation:
  pip3 install --user --no-index --find-links=wheels/ wheels/*.whl

Run the application:
  python3 -m hacklas-recon
EOF

# Create zip
cd "$RELEASE_DIR" && zip -r "${APP_NAME}-app-${ARCH}.zip" app-tmp/
rm -rf "$RELEASE_DIR/app-tmp"
echo "Application package created: $RELEASE_DIR/${APP_NAME}-app-${ARCH}.zip"
