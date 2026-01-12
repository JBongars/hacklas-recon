#!/bin/bash
set -euo pipefail

if [ -d /usr/share/wordlists ] && [ ! -L /usr/share/wordlists ]; then 
  echo "Fixing wordlists package configuration..."; 
  sudo mv /usr/share/wordlists /usr/share/parrot-wordlists; 
  (cd /usr/share && sudo ln --symbolic parrot-wordlists wordlists); 
fi

if [ -d /usr/share/wordlists/seclists ] && [ ! -L /usr/share/wordlists/seclists ]; then 
  echo "Fixing wordlists/seclists package configuration..."; 
  sudo mv /usr/share/wordlists/seclists /usr/share/wordlists/seclists-parrot; 
  (cd /usr/share/wordlists && sudo ln --symbolic seclists-parrot seclists); 
fi

if [ -d /usr/share/seclists ] && [ ! -L /usr/share/seclists ]; then 
  echo "Fixing seclists package configuration..."; 
  sudo mv /usr/share/seclists /usr/share/seclists.bak; 
  (cd /usr/share && sudo ln --symbolic seclists.bak seclists); 
fi
