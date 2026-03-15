#!/usr/bin/env bash
# Bootstrap the first control plane node with kubeadm.

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

wait_cloud_init "${CP1}"

echo "--- Initializing control plane on ${CP1}"

echo -n "Uploading kubeadm config... "
ssh "${CP1}" "cat | sudo tee /tmp/kubeadm-config.yaml > /dev/null" \
    < "${CONFIG_DIR}/kubeadm-config.yaml" \
    && echo "done"

echo "Running kubeadm init (this takes a minute)..."
ssh "${CP1}" "sudo -i kubeadm init \
    --config /tmp/kubeadm-config.yaml \
    2>&1 | tee /tmp/kubeadm-init.log"

echo -n "Setting up kubeconfig for ${LAB_USER} on ${CP1}... "
ssh "${CP1}" "
    mkdir -p ~/.kube
    sudo cp /etc/kubernetes/admin.conf ~/.kube/config
    sudo chown ${LAB_USER}:${LAB_USER} ~/.kube/config
" && echo "done"

echo -n "Copying kubeconfig to host (${KUBECONFIG})... "
mkdir -p "$(dirname "${KUBECONFIG}")" \
    && ssh "${CP1}" "cat ~/.kube/config" > "${KUBECONFIG}" \
    && echo "done"

echo ""
echo "--- Control plane initialized"
echo "    Kubeconfig saved to: ${KUBECONFIG}"
echo ""
echo "    To use: export KUBECONFIG=${KUBECONFIG}"
