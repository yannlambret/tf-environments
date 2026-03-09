#!/usr/bin/env bash
# Deploy HAProxy as a Docker container on control-plane-lb.
# Requires: make configure-ssh has been run.

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/common.sh"

wait_cloud_init "${LB_HOST}"

echo "--- Setting up load balancer on ${LB_HOST}"

echo -n "Uploading HAProxy config... "
ssh "${LB_HOST}" "sudo mkdir -p $(dirname "${HAPROXY_CFG_REMOTE}")" \
    && ssh "${LB_HOST}" "cat | sudo tee ${HAPROXY_CFG_REMOTE} > /dev/null" \
        < "${CONFIG_DIR}/haproxy.cfg" \
    && echo "done"

echo -n "Pulling HAProxy image... "
ssh "${LB_HOST}" "sudo docker pull -q ${HAPROXY_IMAGE}" &> /dev/null \
    && echo "done"

echo -n "Starting HAProxy container... "
# Remove any previous instance so this script is re-runnable
ssh "${LB_HOST}" "
    sudo docker rm -f ${HAPROXY_CONTAINER} 2>/dev/null || true
    sudo docker run -d \
        --name ${HAPROXY_CONTAINER} \
        --network host \
        --restart unless-stopped \
        -v ${HAPROXY_CFG_REMOTE}:${HAPROXY_CFG_REMOTE}:ro \
        ${HAPROXY_IMAGE} > /dev/null
" && echo "done"

echo -n "Verifying HAProxy is listening on port 6443... "
ssh "${LB_HOST}" "
    for i in \$(seq 1 10); do
        nc -z localhost 6443 2>/dev/null && exit 0
        sleep 1
    done
    echo 'HAProxy did not come up in time' >&2
    exit 1
" && echo "done"

echo "--- Load balancer ready"
