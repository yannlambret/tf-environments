# ───────────────────────────────────────
# Kubernetes lab Makefile
# ───────────────────────────────────────

MAKEFLAGS += --no-print-directory

SHELL := /usr/bin/env bash

TERRAFORM_DIR     := terraform
TF                := terraform -chdir=$(TERRAFORM_DIR)
SSH_CONFIG        := $(HOME)/.ssh/config
SSH_CONFIG_DIR    := $(HOME)/.ssh/config.d
LAB_SSH_CONFIG    := $(SSH_CONFIG_DIR)/k8s-lab
LAB_USER          := ubuntu
DISPATCHER_SCRIPT := /etc/NetworkManager/dispatcher.d/99-k8s-lab

HOSTS := \
    control-plane-lb \
    control-plane-01 \
    control-plane-02 \
    control-plane-03 \
    worker-01 \
    worker-02 \
    worker-03

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
		CONTENT=$$(cat $(SSH_CONFIG)); \
		{ echo "Include config.d/*"; [ -n "$$CONTENT" ] && printf "\n%s" "$$CONTENT"; } > $(SSH_CONFIG); \
		echo "✅ (added)"; \
	else \
		echo "✅ (already present)"; \
	fi
	@echo -n "Writing SSH config to $(LAB_SSH_CONFIG)... "; \
	{ \
	    for host in $(HOSTS); \
	    do \
            echo "Host $$host"; \
            echo "  HostName $$($(TF) output -raw "$${host//-/_}_ipv4_address")"; \
            echo "  User $(LAB_USER)"; \
            echo "  StrictHostKeyChecking no"; \
            echo "  UserKnownHostsFile /dev/null"; \
            echo ""; \
	    done \
	} > $(LAB_SSH_CONFIG); \
	echo "✅"

# ───────────────────────────────────────
# Start the domains
# ───────────────────────────────────────
start-domains:
	@for host in $(HOSTS); do \
	    echo -n "Starting $$host... "; \
	    virsh start "$$host" > /tmp/make_task.log 2>&1 \
	        && { echo "✅"; rm -f /tmp/make_task.log; } \
	        || { echo "❌"; cat /tmp/make_task.log; rm -f /tmp/make_task.log; exit 1; }; \
	done

# ───────────────────────────────────────
# Stop the domains
# ───────────────────────────────────────
stop-domains:
	@for host in $(HOSTS); do \
	    echo -n "Stopping $$host... "; \
	    virsh shutdown "$$host" > /tmp/make_task.log 2>&1 \
	        && { echo "✅"; rm -f /tmp/make_task.log; } \
	        || { echo "❌"; cat /tmp/make_task.log; rm -f /tmp/make_task.log; exit 1; }; \
	done
