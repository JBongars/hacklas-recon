#!/bin/bash
set -euo pipefail

if command -v feroxbuster &> /dev/null; then 
  echo "feroxbuster is already installed."; 
  exit 0
fi

# Detect OS
if [ -f /etc/os-release ]; then 
  . /etc/os-release
fi

if [ "$ID" = "kali" ]; then 
  echo "Installing feroxbuster from Kali repositories..."
  sudo apt install -y feroxbuster
else 
  echo "Non-Kali OS detected ($ID). Installing feroxbuster from .deb..."
  curl -sLO https://github.com/epi052/feroxbuster/releases/latest/download/feroxbuster_amd64.deb.zip && 
    unzip -q feroxbuster_amd64.deb.zip && 
    sudo apt install -y ./feroxbuster_*_amd64.deb && 
    rm -f feroxbuster_amd64.deb.zip feroxbuster_*_amd64.deb
fi
