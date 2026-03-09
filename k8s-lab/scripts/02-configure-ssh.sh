#!/usr/bin/env bash
# Generate an SSH config fragment for all lab hosts under ~/.ssh/config.d/k8s-lab.
# Adds an Include directive to ~/.ssh/config if not already present.

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

mkdir -p "${SSH_CONFIG_DIR}"
touch "${SSH_CONFIG}"

echo -n "Checking SSH Include directive... "
if ! grep -qE '^[[:space:]]*Include[[:space:]]+config\.d/\*' "${SSH_CONFIG}"; then
    CONTENT=$(cat "${SSH_CONFIG}")
    { echo "Include config.d/*"; [ -n "${CONTENT}" ] && printf "\n%s" "${CONTENT}"; } > "${SSH_CONFIG}" \
        && echo "done (added)"
else
    echo "done (already present)"
fi

echo -n "Writing SSH config to ${LAB_SSH_CONFIG}... "
{
    for host in "${HOSTS[@]}"; do
        tf_var="${host//-/_}_ipv4_address"
        ip=$(terraform -chdir="${TERRAFORM_DIR}" output -raw "${tf_var}")
        echo "Host ${host}"
        echo "  HostName ${ip}"
        echo "  User ${LAB_USER}"
        echo "  StrictHostKeyChecking no"
        echo "  UserKnownHostsFile /dev/null"
        echo "  LogLevel ERROR"
        echo ""
    done
} > "${LAB_SSH_CONFIG}" && echo "done"
