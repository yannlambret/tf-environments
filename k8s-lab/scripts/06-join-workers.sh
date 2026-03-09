#!/usr/bin/env bash
# Join worker nodes to the cluster.
# Generates a fresh join token via kubeadm (tokens expire after 24h).

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

for host in "${WORKERS[@]}"; do
    wait_cloud_init "${host}"
done

echo -n "Generating a fresh join token... "
JOIN_CMD=$(ssh "${CP1}" "sudo -i kubeadm token create --print-join-command --kubeconfig /etc/kubernetes/admin.conf")
echo "done"

for host in "${WORKERS[@]}"; do
    echo "--- Joining ${host} as worker"
    ssh "${host}" "sudo -i ${JOIN_CMD}"
done

echo "--- All worker nodes joined"
