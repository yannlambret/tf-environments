#!/usr/bin/env bash
# Install Prometheus Operator CRDs via the dedicated Helm chart.
# This must run before Cilium so that ServiceMonitor CRDs exist when
# Cilium installs its serviceMonitor resource.
# Requires: helm is available on the host.

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

PROMETHEUS_CRDS_HELM_RELEASE="prometheus-operator-crds"
PROMETHEUS_HELM_REPO="https://prometheus-community.github.io/helm-charts"

if ! command -v helm &>/dev/null; then
    echo "Error: helm is not installed or not in PATH" >&2
    exit 1
fi

echo -n "Adding Prometheus community Helm repository... "
helm repo add prometheus-community "${PROMETHEUS_HELM_REPO}" --force-update &>/dev/null \
    && helm repo update prometheus-community &>/dev/null \
    && echo "done"

echo -n "Installing ${PROMETHEUS_CRDS_HELM_RELEASE}... "
helm upgrade --install "${PROMETHEUS_CRDS_HELM_RELEASE}" prometheus-community/prometheus-operator-crds \
    --kubeconfig "${KUBECONFIG}" \
    --namespace monitoring \
    --create-namespace \
    &>/dev/null \
    && echo "done"

echo "--- Prometheus Operator CRDs installed"
