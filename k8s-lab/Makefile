# ───────────────────────────────────────
# Kubernetes lab Makefile
# ───────────────────────────────────────

MAKEFLAGS += --no-print-directory

SHELL := /usr/bin/env bash

TERRAFORM_DIR := terraform
TF            := terraform -chdir=$(TERRAFORM_DIR)
SCRIPTS_DIR   := scripts
KUBECONFIG    := $(HOME)/.kube/config-k8s-lab

HOSTS := \
    control-plane-lb \
    control-plane-01 \
    control-plane-02 \
    control-plane-03 \
    worker-01 \
    worker-02 \
    worker-03

.PHONY: help init apply destroy configure-dns configure-ssh start-domains stop-domains \
        setup-lb init-cluster join-control-planes join-workers install-prometheus-crds install-cilium install-prometheus-stack bootstrap \
        apply-manifests

help:
	@echo "Available commands:"
	@echo "  make init                      Initialize Terraform"
	@echo "  make apply                     Apply infrastructure"
	@echo "  make destroy                   Destroy infrastructure"
	@echo "  make configure-dns             Install DNS dispatcher script and configure lab DNS"
	@echo "  make configure-ssh             Generate SSH config for lab hosts"
	@echo "  make start-domains             Start all lab VMs"
	@echo "  make stop-domains              Stop all lab VMs"
	@echo "  make setup-lb                  Deploy HAProxy on control-plane-lb"
	@echo "  make init-cluster              Bootstrap first control plane with kubeadm"
	@echo "  make join-control-planes       Join control-plane-02 and 03 to the cluster"
	@echo "  make join-workers              Join worker nodes to the cluster"
	@echo "  make install-prometheus-crds   Install Prometheus Operator CRDs via Helm"
	@echo "  make install-cilium            Install Cilium via Helm"
	@echo "  make install-prometheus-stack  Install kube-prometheus-stack via Helm"
	@echo "  make bootstrap                 Run all cluster setup steps in sequence"
	@echo "  make apply-manifests           Render and apply Kubernetes manifests"

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
	@bash $(SCRIPTS_DIR)/01-configure-dns.sh

# ───────────────────────────────────────
# SSH config
# ───────────────────────────────────────
configure-ssh:
	@bash $(SCRIPTS_DIR)/02-configure-ssh.sh

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

# ───────────────────────────────────────
# Cluster bootstrap
# ───────────────────────────────────────
setup-lb:
	$(call run_silent,Deploying HAProxy on control-plane-lb,bash $(SCRIPTS_DIR)/03-setup-lb.sh)

init-cluster:
	$(call run_silent,Initializing control plane (this takes a minute),bash $(SCRIPTS_DIR)/04-init-control-plane.sh)

join-control-planes:
	$(call run_silent,Joining control plane nodes,bash $(SCRIPTS_DIR)/05-join-control-planes.sh)

join-workers:
	$(call run_silent,Joining worker nodes,bash $(SCRIPTS_DIR)/06-join-workers.sh)

install-prometheus-crds:
	$(call run_silent,Installing Prometheus Operator CRDs via Helm,KUBECONFIG=$(KUBECONFIG) bash $(SCRIPTS_DIR)/07-install-prometheus-crds.sh)

install-cilium:
	$(call run_silent,Installing Cilium via Helm,KUBECONFIG=$(KUBECONFIG) bash $(SCRIPTS_DIR)/08-install-cilium.sh)

install-prometheus-stack:
	$(call run_silent,Installing kube-prometheus-stack via Helm,KUBECONFIG=$(KUBECONFIG) bash $(SCRIPTS_DIR)/09-install-prometheus-stack.sh)

# ───────────────────────────────────────
# Kubernetes manifests
# ───────────────────────────────────────
apply-manifests:
	$(call run_silent,Applying Kubernetes manifests,KUBECONFIG=$(KUBECONFIG) bash $(SCRIPTS_DIR)/10-apply-manifests.sh)

bootstrap: setup-lb init-cluster join-control-planes join-workers install-prometheus-crds install-cilium install-prometheus-stack
	@echo ""
	@echo "Cluster is ready. Run:"
	@echo "  export KUBECONFIG=$(KUBECONFIG)"
	@echo "  kubectl get nodes"
