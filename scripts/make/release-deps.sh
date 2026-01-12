#!/bin/bash
set -euo pipefail

# Set default values (assume Kali/Debian amd64)
ARCH="${ARCH:-$(dpkg --print-architecture 2>/dev/null || echo "amd64")}"
APP_NAME="${APP_NAME:-hacklas-recon}"
RELEASE_DIR="${RELEASE_DIR:-release/$ARCH}"

echo "Creating dependencies release package for $ARCH..."
mkdir -p "$RELEASE_DIR/deps-tmp"

# Download all .deb packages
echo "Downloading APT packages..."
cd "$RELEASE_DIR/deps-tmp" && apt-get download \
  $(grep -Ev "^\s*#|^\s*$" ../../apt-requirements.txt) \
  2>/dev/null || true

# Download dependencies recursively
echo "Downloading dependencies..."
cd "$RELEASE_DIR/deps-tmp" && \
  for pkg in $(grep -Ev "^\s*#|^\s*$" ../../apt-requirements.txt); do
    apt-cache depends "$pkg" | \
      grep "Depends:" | \
      awk '{print $2}' | \
      xargs -I {} apt-get download {} 2>/dev/null || true
  done

# Create installation script
cat > "$RELEASE_DIR/deps-tmp/install-deps.sh" <<'EOF'
#!/bin/bash
set -e

echo "Installing dependencies from .deb packages..."
sudo dpkg -i *.deb 2>/dev/null || true
sudo apt-get install -f -y
echo "Dependencies installed!"
EOF
chmod +x "$RELEASE_DIR/deps-tmp/install-deps.sh"

# Create README
cat > "$RELEASE_DIR/deps-tmp/README.txt" <<'EOF'
APT Dependencies Package
========================

To install on an airgapped machine:
1. Extract this archive
2. Run: ./install-deps.sh
EOF

# Create zip
cd "$RELEASE_DIR" && zip -r "${APP_NAME}-deps-${ARCH}.zip" deps-tmp/
rm -rf "$RELEASE_DIR/deps-tmp"
echo "Dependencies package created: $RELEASE_DIR/${APP_NAME}-deps-${ARCH}.zip"
