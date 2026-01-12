.PHONY: help install install-deps install-poetry install-app uninstall clean release release-app release-deps

ARCH := $(shell dpkg --print-architecture)
RELEASE_DIR := release/$(ARCH)
APP_NAME := hacklas_recon
PROJECT_FOLDER := $(shell pwd)
MAKE_SCRIPTS_FOLDER := $(PROJECT_FOLDER)/scripts/make

# Check if --no-support flag is present
NO_SUPPORT := $(filter --no-support,$(MAKECMDGOALS))
ifneq ($(NO_SUPPORT),)
	SKIP_OS_CHECK := true
	MAKECMDGOALS := $(filter-out --no-support,$(MAKECMDGOALS))
endif

help:
	@echo "Available targets:"
	@echo "  make install              - Full installation (detect OS, install deps, Poetry, and app)"
	@echo "  make install --no-support - Install on unsupported OS (use at your own risk)"
	@echo "  make install-deps         - Install system dependencies only"
	@echo "  make install-poetry       - Install Poetry only"
	@echo "  make install-app          - Install Python app with Poetry only"
	@echo "  make release              - Create release packages for airgapped machines"
	@echo "  make release-app          - Create application release package only"
	@echo "  make release-deps         - Create dependencies release package only"
	@echo "  make uninstall            - Uninstall the application"
	@echo "  make clean                - Clean Poetry cache and virtual environments"

# Detect OS
detect-os:
ifndef SKIP_OS_CHECK
	@if [ -f /etc/os-release ]; then \
		. /etc/os-release; \
		if [ "$$ID" = "kali" ] || [ "$$ID" = "parrot" ] || [ "$$ID" = "debian" ]; then \
			echo "Detected: $$ID"; \
		else \
			echo "Error: Unsupported OS (detected: $$ID)"; \
			echo "Only Kali Linux and Parrot OS are officially supported."; \
			echo "To install anyway, use: make install --no-support"; \
			exit 1; \
		fi \
	else \
		echo "Error: Cannot detect OS. /etc/os-release not found."; \
		echo "To install anyway, use: make install --no-support"; \
		exit 1; \
	fi
else
	@if [ -f /etc/os-release ]; then \
		. /etc/os-release; \
		echo "WARNING: Installing on unsupported OS: $$ID"; \
		echo "This may not work correctly. Proceed at your own risk."; \
	else \
		echo "WARNING: Cannot detect OS, but proceeding anyway (--no-support flag used)"; \
	fi
endif

fix-broken-wordlists: detect-os
	@bash $(MAKE_SCRIPTS_FOLDER)/fix-broken-wordlists.sh

install-deps: detect-os
	@echo "Installing system dependencies..."
	sudo apt update -y
	sudo dpkg --configure -a || true
	sudo apt --fix-broken install -y || true
	sudo apt install -y $$(grep -Ev "^\s*#|^\s*$$" apt-requirements.txt)
	$(MAKE) install-feroxbuster

install-feroxbuster: detect-os fix-broken-wordlists
	@bash $(MAKE_SCRIPTS_FOLDER)/install-feroxbuster.sh

# Install Poetry
install-poetry:
	@echo "Installing Poetry..."
	@if ! command -v poetry &> /dev/null; then \
		curl -sSL https://install.python-poetry.org | python3 -; \
		grep -o 'export PATH="$$HOME/.local/bin:$$PATH"' ~/.bashrc &>/dev/null || echo 'export PATH="$$HOME/.local/bin:$$PATH"' >> ~/.bashrc; \
		echo "Poetry installed. Please run 'source ~/.bashrc' or restart your terminal."; \
	else \
		echo "Poetry is already installed."; \
	fi

# Install the application
install-app:
	@echo "Installing application with Poetry..."
	poetry config virtualenvs.create true
	poetry config virtualenvs.in-project true
	poetry install --no-interaction --no-ansi

# Full installation
install: detect-os install-deps install-feroxbuster install-poetry install-app
	@echo ""
	@echo "Installation complete!"
	@echo "You may need to run 'source ~/.bashrc' to update your PATH."
	@echo "Run 'python3 -m hacklas_recon' to start the application."

# Dummy target for --no-support flag
--no-support:
	@:

# Create application release package
release-app: detect-os
	@ARCH=$(ARCH) RELEASE_DIR=$(RELEASE_DIR) APP_NAME=$(APP_NAME) \
		bash $(MAKE_SCRIPTS_FOLDER)/r
