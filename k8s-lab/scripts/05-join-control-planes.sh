#!/usr/bin/env bash
# Join control-plane-02 and control-plane-03 to the cluster.
# Generates a fresh certificate key and join token via kubeadm.
# Tokens expire after 24h; certificate keys expire after 2h.

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

for host in "${CP2}" "${CP3}"; do
    wait_cloud_init "${host}"
done

echo -n "Re-uploading certificates and generating certificate key... "
CERT_KEY=$(ssh "${CP1}" "sudo -i kubeadm init phase upload-certs --upload-certs \
    --kubeconfig /etc/kubernetes/admin.conf 2>/dev/null | tail -1")
echo "done"

echo -n "Generating a fresh join token... "
JOIN_CMD=$(ssh "${CP1}" "sudo -i kubeadm token create --print-join-command \
    --kubeconfig /etc/kubernetes/admin.conf")
echo "done"

for host in "${CP2}" "${CP3}"; do
    echo "--- Joining ${host} as control plane"
    ssh "${host}" "sudo -i ${JOIN_CMD} --control-plane --certificate-key ${CERT_KEY}"
    echo -n "Setting up kubeconfig on ${host}... "
    ssh "${host}" "
        mkdir -p ~/.kube
        sudo cp /etc/kubernetes/admin.conf ~/.kube/config
        sudo chown ${LAB_USER}:${LAB_USER} ~/.kube/config
    " && echo "done"
done

echo "--- All control plane nodes joined"
