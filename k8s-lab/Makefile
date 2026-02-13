# ───────────────────────────────────────
# Kubernetes The Hard Way lab Makefile
# ───────────────────────────────────────

MAKEFLAGS += --no-print-directory

SHELL := /usr/bin/env bash

TERRAFORM_DIR     := terraform
TF                := terraform -chdir=$(TERRAFORM_DIR)
SSH_CONFIG        := $(HOME)/.ssh/config
SSH_CONFIG_DIR    := $(HOME)/.ssh/config.d
LAB_SSH_CONFIG    := $(SSH_CONFIG_DIR)/k8s-lab
LAB_USER          := debian
DISPATCHER_SCRIPT := /etc/NetworkManager/dispatcher.d/99-k8s-lab

.PHONY: help init apply destroy configure-dns configure-ssh start-domains stop-domains

help:
	@echo "Available commands:"
	@echo "  make init             Initialize Terraform"
	@echo "  make apply            Apply infrastructure"
	@echo "  make destroy          Destroy infrastructure"
	@echo "  make configure-dns    Install DNS dispatcher script and configure lab DNS"
	@echo "  make configure-ssh    Generate SSH config for lab hosts"
	@echo "  make start-domains    Start all lab VMs"
	@echo "  make stop-domains     Stop all lab VMs"

define run_silent
	@echo -n "$(1)... "
	@$(2) > /tmp/make_task.log 2>&1 || ( \
		echo "❌"; \
		echo "───────────────────────────────────────"; \
		cat /tmp/make_task.log; \
		echo "───────────────────────────────────────"; \
		rm -f /tmp/make_task.log; \
		exit 1 \
	)
	@echo "✅"
	@rm -f /tmp/make_task.log
endef

# ───────────────────────────────────────
# Terraform
# ───────────────────────────────────────
init:
	$(call run_silent,Running Terraform init,$(TF) init)

apply:
	$(call run_silent,Running Terraform apply,$(TF) apply -auto-approve)

destroy:
	$(call run_silent,Running Terraform destroy,$(TF) destroy -auto-approve)

# ───────────────────────────────────────
# DNS setup via NetworkManager dispatcher
# ───────────────────────────────────────
configure-dns:
	@sudo -n true 2>/dev/null || { echo "Authenticating with sudo for DNS setup..." && sudo -v; }
	@echo -n "Getting output values from Terraform... "; \
	BRIDGE=$$($(TF) output -raw network_bridge); \
	DOMAIN=$$($(TF) output -raw network_domain); \
	DNS_IP=$$($(TF) output -raw network_gateway_ipv4_address); \
	echo "✅"; \
	echo "  • BRIDGE=$$BRIDGE"; \
	echo "  • DNS_IP=$$DNS_IP"; \
	echo "  • DOMAIN=$$DOMAIN"; \
	echo -n "Installing DNS dispatcher script to $(DISPATCHER_SCRIPT)... "; \
	{ \
	  echo "#!/usr/bin/env bash"; \
	  echo "set -euo pipefail"; \
	  echo ""; \
	  echo "IFACE=\"\$$1\""; \
	  echo "ACTION=\"\$$2\""; \
	  echo ""; \
	  echo "BRIDGE=\"$$BRIDGE\""; \
	  echo "DNS_IP=\"$$DNS_IP\""; \
	  echo "DOMAIN=\"$$DOMAIN\""; \
	  echo ""; \
	  echo "if [[ \"\$$IFACE\" == \"\$$BRIDGE\" && \"\$$ACTION\" == \"up\" ]]; then"; \
	  echo "    resolvectl dns \"\$$BRIDGE\" \"\$$DNS_IP\""; \
	  echo "    resolvectl domain \"\$$BRIDGE\" \"~\$$DOMAIN\""; \
	  echo "fi"; \
	} | sudo install -m 755 /dev/stdin $(DISPATCHER_SCRIPT); \
	echo "✅"; \
	echo -n "Configuring lab DNS for $$BRIDGE... "; \
	sudo $(DISPATCHER_SCRIPT) "$$BRIDGE" up; \
	echo "✅"

# ───────────────────────────────────────
# SSH config
# ───────────────────────────────────────
configure-ssh:
	@mkdir -p $(SSH_CONFIG_DIR)
	@touch $(SSH_CONFIG)
	@echo -n "Checking SSH Include directive... "; \
	if ! grep -qE '^[[:space:]]*Include[[:space:]]+config\.d/\*' $(SSH_CONFIG); then \
		{ echo "Include config.d/*"; [ -s $(SSH_CONFIG) ] && echo; cat $(SSH_CONFIG); } > /tmp/ssh_config && mv /tmp/ssh_config $(SSH_CONFIG); \
		echo "✅ (added)"; \
	else \
		echo "✅ (already present)"; \
	fi
	@echo -n "Getting output values from Terraform... "; \
	JUMPBOX_IP=$$($(TF) output -raw jumpbox_ipv4_address); \
	SERVER_IP=$$($(TF) output -raw server_ipv4_address); \
	NODE0_IP=$$($(TF) output -raw node_0_ipv4_address); \
	NODE1_IP=$$($(TF) output -raw node_1_ipv4_address); \
	echo "✅"; \
	echo "  • JUMPBOX_IP=$$JUMPBOX_IP"; \
	echo "  • SERVER_IP=$$SERVER_IP"; \
	echo "  • NODE0_IP=$$NODE0_IP"; \
	echo "  • NODE1_IP=$$NODE1_IP"; \
	echo -n "Writing SSH config to $(LAB_SSH_CONFIG)... "; \
	{ \
	  echo "Host jumpbox"; \
	  echo "  HostName $$JUMPBOX_IP"; \
	  echo "  User $(LAB_USER)"; \
	  echo "  StrictHostKeyChecking no"; \
	  echo "  UserKnownHostsFile /dev/null"; \
	  echo ""; \
	  echo "Host server"; \
	  echo "  HostName $$SERVER_IP"; \
	  echo "  User $(LAB_USER)"; \
	  echo "  StrictHostKeyChecking no"; \
	  echo "  UserKnownHostsFile /dev/null"; \
	  echo ""; \
	  echo "Host node-0"; \
	  echo "  HostName $$NODE0_IP"; \
	  echo "  User $(LAB_USER)"; \
	  echo "  StrictHostKeyChecking no"; \
	  echo "  UserKnownHostsFile /dev/null"; \
	  echo ""; \
	  echo "Host node-1"; \
	  echo "  HostName $$NODE1_IP"; \
	  echo "  User $(LAB_USER)"; \
	  echo "  StrictHostKeyChecking no"; \
	  echo "  UserKnownHostsFile /dev/null"; \
	} > $(LAB_SSH_CONFIG); \
	echo "✅"

# ───────────────────────────────────────
# Start the domains
# ───────────────────────────────────────
start-domains:
	$(call run_silent,Starting jumpbox,virsh start jumpbox)
	$(call run_silent,Starting server,virsh start server)
	$(call run_silent,Starting node-0,virsh start node-0)
	$(call run_silent,Starting node-1,virsh start node-1)

# ───────────────────────────────────────
# Stop the domains
# ───────────────────────────────────────
stop-domains:
	$(call run_silent,Stopping jumpbox,virsh shutdown jumpbox)
	$(call run_silent,Stopping server,virsh shutdown server)
	$(call run_silent,Stopping node-0,virsh shutdown node-0)
	$(call run_silent,Stopping node-1,virsh shutdown node-1)
