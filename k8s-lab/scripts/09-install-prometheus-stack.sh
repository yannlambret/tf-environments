#!/usr/bin/env bash
# Install kube-prometheus-stack via Helm.
# Requires: kubectl and helm are available on the host.

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

PROMETHEUS_HELM_RELEASE="kube-prometheus-stack"
PROMETHEUS_HELM_NAMESPACE="monitoring"
PROMETHEUS_HELM_REPO="https://prometheus-community.github.io/helm-charts"

for cmd in helm; do
    if ! command -v "${cmd}" &>/dev/null; then
        echo "Error: ${cmd} is not installed or not in PATH" >&2
        exit 1
    fi
done

echo -n "Adding Prometheus community Helm repository... "
helm repo add prometheus-community "${PROMETHEUS_HELM_REPO}" --force-update &>/dev/null \
    && helm repo update prometheus-community &>/dev/null \
    && echo "done"

echo "Installing ${PROMETHEUS_HELM_RELEASE}..."
helm upgrade --install "${PROMETHEUS_HELM_RELEASE}" prometheus-community/kube-prometheus-stack \
    --kubeconfig "${KUBECONFIG}" \
    --namespace "${PROMETHEUS_HELM_NAMESPACE}" \
    --values "${CONFIG_DIR}/prometheus-stack-values.yaml" \
    --skip-crds \
    --wait

echo "--- kube-prometheus-stack installed"
