#!/usr/bin/env bash
# Install a NetworkManager dispatcher script that configures systemd-resolved
# to forward k8s.local DNS queries to the libvirt dnsmasq instance.
# Requires sudo.

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

sudo -n true 2>/dev/null || { echo "Authenticating with sudo for DNS setup..." && sudo -v; }

echo -n "Getting output values from Terraform... "
BRIDGE=$(terraform -chdir="${TERRAFORM_DIR}" output -raw network_bridge) \
    && DOMAIN=$(terraform -chdir="${TERRAFORM_DIR}" output -raw network_domain) \
    && DNS_IP=$(terraform -chdir="${TERRAFORM_DIR}" output -raw network_gateway_ipv4_address) \
    && echo "done"
echo "  BRIDGE=${BRIDGE}"
echo "  DNS_IP=${DNS_IP}"
echo "  DOMAIN=${DOMAIN}"

echo -n "Installing DNS dispatcher script to ${DISPATCHER_SCRIPT}... "
{
    echo "#!/usr/bin/env bash"
    echo "set -euo pipefail"
    echo ""
    echo "IFACE=\"\$1\""
    echo "ACTION=\"\$2\""
    echo ""
    echo "BRIDGE=\"${BRIDGE}\""
    echo "DNS_IP=\"${DNS_IP}\""
    echo "DOMAIN=\"${DOMAIN}\""
    echo ""
    echo "if [[ \"\$IFACE\" == \"\$BRIDGE\" && \"\$ACTION\" == \"up\" ]]; then"
    echo "    resolvectl dns \"\$BRIDGE\" \"\$DNS_IP\""
    echo "    resolvectl domain \"\$BRIDGE\" \"~\$DOMAIN\""
    echo "fi"
} | sudo install -m 755 /dev/stdin "${DISPATCHER_SCRIPT}" \
    && echo "done"

echo -n "Configuring lab DNS for ${BRIDGE}... "
sudo "${DISPATCHER_SCRIPT}" "${BRIDGE}" up && echo "done"
