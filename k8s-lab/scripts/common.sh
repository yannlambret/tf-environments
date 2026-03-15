#!/usr/bin/env bash
# Shared configuration sourced by all lab scripts.
# Do not execute directly.

# ── Directories ──────────────────────────────────────────────────────────────

SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_DIR="$(cd "${SCRIPTS_DIR}/.." && pwd)"
TERRAFORM_DIR="${LAB_DIR}/terraform"
CONFIG_DIR="${LAB_DIR}/config"

# ── NetworkManager dispatcher ─────────────────────────────────────────────────

DISPATCHER_SCRIPT="/etc/NetworkManager/dispatcher.d/99-k8s-lab"

# ── SSH / user ────────────────────────────────────────────────────────────────

LAB_USER="ubuntu"
SSH_CONFIG="${HOME}/.ssh/config"
SSH_CONFIG_DIR="${HOME}/.ssh/config.d"
LAB_SSH_CONFIG="${SSH_CONFIG_DIR}/k8s-lab"

# ── Hosts ─────────────────────────────────────────────────────────────────────

LB_HOST="control-plane-lb"
CP1="control-plane-01"
CP2="control-plane-02"
CP3="control-plane-03"
WORKERS=("worker-01" "worker-02" "worker-03")
HOSTS=("${LB_HOST}" "${CP1}" "${CP2}" "${CP3}" "${WORKERS[@]}")

# ── HAProxy ───────────────────────────────────────────────────────────────────

HAPROXY_IMAGE="haproxy:lts-alpine"
HAPROXY_CONTAINER="haproxy"
HAPROXY_CFG_REMOTE="/usr/local/etc/haproxy/haproxy.cfg"

# ── Cilium ────────────────────────────────────────────────────────────────────

CILIUM_VERSION="${CILIUM_VERSION:-1.19.1}"
CILIUM_HELM_RELEASE="cilium"
CILIUM_HELM_NAMESPACE="kube-system"

# ── Kubeconfig ────────────────────────────────────────────────────────────────

export KUBECONFIG="${KUBECONFIG:-${HOME}/.kube/config-k8s-lab}"

# ── Helpers ───────────────────────────────────────────────────────────────────

wait_cloud_init() {
    local host="$1"
    local max_attempts=30
    local attempt=0

    echo -n "Waiting for ${host} to become reachable... "
    until ssh -o ConnectTimeout=5 "${host}" true 2>/dev/null; do
        attempt=$(( attempt + 1 ))
        if (( attempt >= max_attempts )); then
            echo "timed out" >&2
            return 1
        fi
        sleep 5
    done
    echo "done"

    echo -n "Waiting for cloud-init on ${host}... "
    ssh "${host}" "cloud-init status --wait" > /dev/null \
        && echo "done"
}
