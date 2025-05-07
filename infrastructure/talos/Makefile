# Makefile for Talos Cluster Management

# Variables
WORKSPACE := /workspace/infrastructure/talos
OUT_DIR := $(WORKSPACE)/_out
TALOSCONFIG := $(OUT_DIR)/talosconfig
KUBECONFIG := $(WORKSPACE)/kubeconfig
CLUSTER_NAME := rotterdam
ENDPOINT := rotterdam.my.vadue.de
ENDPOINT_URL := https://$(ENDPOINT):6443
SECRETS_FILE := $(WORKSPACE)/secrets.yaml
ENV_FILE := $(WORKSPACE)/env.sh

# Default target - shows help
.PHONY: help
help:
	@echo "Talos Cluster Management"
	@echo ""
	@echo "Available commands:"
	@echo "  make help            - Shows this help message"
	@echo "  make talos-init      - Initializes the Talos cluster for the first time"
	@echo "  make talos-update    - Updates the Talos cluster with new configuration"
	@echo "  make talos-clean     - Deletes generated configuration files"
	@echo ""
	@echo "After running 'make talos-init' or 'make talos-update',"
	@echo "run 'source $(ENV_FILE)' to load the environment variables."
	@echo ""

# Initial cluster setup
.PHONY: talos-init
talos-init: talos-gen-secrets talos-gen-config talos-apply-config-insecure talos-set-env talos-bootstrap

# Cluster update
.PHONY: talos-update
talos-update: talos-gen-config-update talos-apply-config talos-set-env

# Generate secrets (only for init)
.PHONY: talos-gen-secrets
talos-gen-secrets:
	@echo "Generating Talos secrets..."
	cd $(WORKSPACE) && talosctl gen secrets -o $(SECRETS_FILE)

# Generate configuration with new secrets (for init)
.PHONY: talos-gen-config
talos-gen-config:
	@echo "Generating Talos configuration..."
	@mkdir -p $(OUT_DIR)
	cd $(WORKSPACE) && talosctl gen config --with-secrets $(SECRETS_FILE) $(CLUSTER_NAME) $(ENDPOINT_URL) --output-dir _out --force
	cd $(WORKSPACE) && talosctl machineconfig patch $(OUT_DIR)/controlplane.yaml --patch @0_0_master.patch.yaml --output $(OUT_DIR)/controlplane_0_0.yaml
	cd $(WORKSPACE) && talosctl machineconfig patch $(OUT_DIR)/controlplane_0_0.yaml --patch @1_0_cp.patch.yaml --output $(OUT_DIR)/controlplane_1_0.yaml
	cd $(WORKSPACE) && talosctl machineconfig patch $(OUT_DIR)/controlplane_1_0.yaml --patch @1_1_cp01.patch.yaml --output $(OUT_DIR)/controlplane_1_1.yaml
	cd $(WORKSPACE) && talosctl machineconfig patch $(OUT_DIR)/controlplane_1_0.yaml --patch @1_2_cp02.patch.yaml --output $(OUT_DIR)/controlplane_1_2.yaml
	cd $(WORKSPACE) && talosctl machineconfig patch $(OUT_DIR)/controlplane_1_0.yaml --patch @1_3_cp03.patch.yaml --output $(OUT_DIR)/controlplane_1_3.yaml
	cd $(WORKSPACE) && talosctl machineconfig patch $(OUT_DIR)/worker.yaml --patch @0_0_master.patch.yaml --output $(OUT_DIR)/worker_0_0.yaml
	cd $(WORKSPACE) && talosctl machineconfig patch $(OUT_DIR)/worker_0_0.yaml --patch @2_0_wk.patch.yaml --output $(OUT_DIR)/worker_2_0.yaml
	cd $(WORKSPACE) && talosctl machineconfig patch $(OUT_DIR)/worker_2_0.yaml --patch @2_1_wk01.patch.yaml --output $(OUT_DIR)/worker_2_1.yaml
	cd $(WORKSPACE) && talosctl machineconfig patch $(OUT_DIR)/worker_2_0.yaml --patch @2_2_wk02.patch.yaml --output $(OUT_DIR)/worker_2_2.yaml
	cd $(WORKSPACE) && talosctl machineconfig patch $(OUT_DIR)/worker_2_0.yaml --patch @2_3_wk03.patch.yaml --output $(OUT_DIR)/worker_2_3.yaml

# Generate configuration with existing secrets (for update)
.PHONY: talos-gen-config-update
talos-gen-config-update:
	@echo "Generating Talos configuration with existing secrets..."
	@mkdir -p $(OUT_DIR)
	@if [ ! -f $(SECRETS_FILE) ]; then \
		echo "Error: $(SECRETS_FILE) not found. Run 'make talos-init' to generate secrets."; \
		exit 1; \
	fi
	cd $(WORKSPACE) && talosctl gen config --with-secrets $(SECRETS_FILE) $(CLUSTER_NAME) $(ENDPOINT_URL) --output-dir _out --force
	cd $(WORKSPACE) && talosctl machineconfig patch $(OUT_DIR)/controlplane.yaml --patch @0_0_master.patch.yaml --output $(OUT_DIR)/controlplane_0_0.yaml
	cd $(WORKSPACE) && talosctl machineconfig patch $(OUT_DIR)/controlplane_0_0.yaml --patch @1_0_cp.patch.yaml --output $(OUT_DIR)/controlplane_1_0.yaml
	cd $(WORKSPACE) && talosctl machineconfig patch $(OUT_DIR)/controlplane_1_0.yaml --patch @1_1_cp01.patch.yaml --output $(OUT_DIR)/controlplane_1_1.yaml
	cd $(WORKSPACE) && talosctl machineconfig patch $(OUT_DIR)/controlplane_1_0.yaml --patch @1_2_cp02.patch.yaml --output $(OUT_DIR)/controlplane_1_2.yaml
	cd $(WORKSPACE) && talosctl machineconfig patch $(OUT_DIR)/controlplane_1_0.yaml --patch @1_3_cp03.patch.yaml --output $(OUT_DIR)/controlplane_1_3.yaml
	cd $(WORKSPACE) && talosctl machineconfig patch $(OUT_DIR)/worker.yaml --patch @0_0_master.patch.yaml --output $(OUT_DIR)/worker_0_0.yaml
	cd $(WORKSPACE) && talosctl machineconfig patch $(OUT_DIR)/worker_0_0.yaml --patch @2_0_wk.patch.yaml --output $(OUT_DIR)/worker_2_0.yaml
	cd $(WORKSPACE) && talosctl machineconfig patch $(OUT_DIR)/worker_2_0.yaml --patch @2_1_wk01.patch.yaml --output $(OUT_DIR)/worker_2_1.yaml
	cd $(WORKSPACE) && talosctl machineconfig patch $(OUT_DIR)/worker_2_0.yaml --patch @2_2_wk02.patch.yaml --output $(OUT_DIR)/worker_2_2.yaml
	cd $(WORKSPACE) && talosctl machineconfig patch $(OUT_DIR)/worker_2_0.yaml --patch @2_3_wk03.patch.yaml --output $(OUT_DIR)/worker_2_3.yaml

# Apply configuration for initial setup (with --insecure)
.PHONY: talos-apply-config-insecure
talos-apply-config-insecure:
	@echo "Applying Talos configuration in insecure mode..."
	cd $(WORKSPACE) && TALOSCONFIG=$(TALOSCONFIG) talosctl apply-config --insecure --nodes rotterdam-cp01.my.vadue.de --file $(OUT_DIR)/controlplane_1_1.yaml
	cd $(WORKSPACE) && TALOSCONFIG=$(TALOSCONFIG) talosctl apply-config --insecure --nodes rotterdam-cp02.my.vadue.de --file $(OUT_DIR)/controlplane_1_2.yaml
	cd $(WORKSPACE) && TALOSCONFIG=$(TALOSCONFIG) talosctl apply-config --insecure --nodes rotterdam-cp03.my.vadue.de --file $(OUT_DIR)/controlplane_1_3.yaml
	cd $(WORKSPACE) && TALOSCONFIG=$(TALOSCONFIG) talosctl apply-config --insecure --nodes rotterdam-wk01.my.vadue.de --file $(OUT_DIR)/worker_2_1.yaml
	cd $(WORKSPACE) && TALOSCONFIG=$(TALOSCONFIG) talosctl apply-config --insecure --nodes rotterdam-wk02.my.vadue.de --file $(OUT_DIR)/worker_2_2.yaml
	cd $(WORKSPACE) && TALOSCONFIG=$(TALOSCONFIG) talosctl apply-config --insecure --nodes rotterdam-wk03.my.vadue.de --file $(OUT_DIR)/worker_2_3.yaml

# Apply configuration for updates (without --insecure)
.PHONY: talos-apply-config
talos-apply-config:
	@echo "Applying Talos configuration..."
	cd $(WORKSPACE) && TALOSCONFIG=$(TALOSCONFIG) talosctl apply-config --nodes rotterdam-cp01.my.vadue.de --file $(OUT_DIR)/controlplane_1_1.yaml
	cd $(WORKSPACE) && TALOSCONFIG=$(TALOSCONFIG) talosctl apply-config --nodes rotterdam-cp02.my.vadue.de --file $(OUT_DIR)/controlplane_1_2.yaml
	cd $(WORKSPACE) && TALOSCONFIG=$(TALOSCONFIG) talosctl apply-config --nodes rotterdam-cp03.my.vadue.de --file $(OUT_DIR)/controlplane_1_3.yaml
	cd $(WORKSPACE) && TALOSCONFIG=$(TALOSCONFIG) talosctl apply-config --nodes rotterdam-wk01.my.vadue.de --file $(OUT_DIR)/worker_2_1.yaml
	cd $(WORKSPACE) && TALOSCONFIG=$(TALOSCONFIG) talosctl apply-config --nodes rotterdam-wk02.my.vadue.de --file $(OUT_DIR)/worker_2_2.yaml
	cd $(WORKSPACE) && TALOSCONFIG=$(TALOSCONFIG) talosctl apply-config --nodes rotterdam-wk03.my.vadue.de --file $(OUT_DIR)/worker_2_3.yaml

# Set environment variables
.PHONY: talos-set-env
talos-set-env:
	@echo "Setting environment variables for Talos..."
	@echo "export TALOSCONFIG=$(TALOSCONFIG)" > $(ENV_FILE)
	@echo "export KUBECONFIG=$(KUBECONFIG)" >> $(ENV_FILE)
	@echo "talosctl config endpoint $(ENDPOINT)" >> $(ENV_FILE)
	@echo "talosctl config node rotterdam-cp01.my.vadue.de" >> $(ENV_FILE)
	@chmod +x $(ENV_FILE)
	@echo "Environment variables have been saved to $(ENV_FILE)."
	@echo "Run 'source $(ENV_FILE)' to load them."
	cd $(WORKSPACE) && TALOSCONFIG=$(TALOSCONFIG) talosctl config endpoint $(ENDPOINT)
	cd $(WORKSPACE) && TALOSCONFIG=$(TALOSCONFIG) talosctl config node rotterdam-cp01.my.vadue.de

# Bootstrap the cluster
.PHONY: talos-bootstrap
talos-bootstrap:
	@echo "Bootstrapping the Talos cluster..."
	cd $(WORKSPACE) && TALOSCONFIG=$(TALOSCONFIG) talosctl bootstrap
	cd $(WORKSPACE) && TALOSCONFIG=$(TALOSCONFIG) talosctl kubeconfig --nodes rotterdam-cp01.my.vadue.de -f $(KUBECONFIG)
	@echo "Kubeconfig has been downloaded to $(KUBECONFIG)."
	@echo "export KUBECONFIG=$(KUBECONFIG)" >> $(ENV_FILE)

# Clean up
.PHONY: talos-clean
talos-clean:
	@echo "Deleting generated configuration files..."
	@rm -rf $(OUT_DIR)/*.yaml $(KUBECONFIG) $(ENV_FILE)
