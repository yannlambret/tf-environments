#!/usr/bin/env bash
# Install Cilium via Helm.
# Requires: kubectl and helm are available on the host, KUBECONFIG is set.

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

GATEWAY_API_VERSION="${GATEWAY_API_VERSION:-1.4.1}"
GATEWAY_API_CRDS_URL="https://github.com/kubernetes-sigs/gateway-api/releases/download/v${GATEWAY_API_VERSION}/experimental-install.yaml"

for cmd in kubectl helm; do
    if ! command -v "${cmd}" &>/dev/null; then
        echo "Error: ${cmd} is not installed or not in PATH" >&2
        exit 1
    fi
done

echo -n "Installing Gateway API CRDs (v${GATEWAY_API_VERSION})... "
kubectl --kubeconfig "${KUBECONFIG}" apply --server-side -f "${GATEWAY_API_CRDS_URL}" &>/dev/null \
    && echo "done"

echo -n "Adding Cilium Helm repository... "
helm repo add cilium https://helm.cilium.io/ --force-update &>/dev/null \
    && helm repo update cilium &>/dev/null \
    && echo "done"

echo "Installing Cilium ${CILIUM_VERSION}..."
helm upgrade --install "${CILIUM_HELM_RELEASE}" cilium/cilium \
    --version "${CILIUM_VERSION}" \
    --namespace "${CILIUM_HELM_NAMESPACE}" \
    --values "${CONFIG_DIR}/cilium-values.yaml" \
    --wait

echo -n "Waiting for Cilium to be ready... "
kubectl -n "${CILIUM_HELM_NAMESPACE}" rollout status daemonset/cilium --timeout=5m \
    && echo "done"

echo "--- Cilium installed"
echo ""
echo "    Run 'cilium status' or check with:"
echo "    kubectl -n ${CILIUM_HELM_NAMESPACE} get pods -l k8s-app=cilium"
