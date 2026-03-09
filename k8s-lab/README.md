# k8s-lab

Provision a fully functional multi-node Kubernetes cluster with Cilium on your local machine in
just a few minutes — using Terraform, libvirt/KVM, and kubeadm.

## Cluster layout

| VM | Role | vCPU | RAM | IPv4 | IPv6 |
|----|------|:----:|:---:|------|------|
| `control-plane-lb` | HAProxy load balancer |  1   | 1 GiB | 192.168.101.10 | fd00:2::a |
| `control-plane-01` | Control plane |  2   | 2 GiB | 192.168.101.11 | fd00:2::b |
| `control-plane-02` | Control plane |  2   | 2 GiB | 192.168.101.12 | fd00:2::c |
| `control-plane-03` | Control plane |  2   | 2 GiB | 192.168.101.13 | fd00:2::d |
| `worker-01` | Worker node |  4   | 16 GiB | 192.168.101.21 | fd00:2::15 |
| `worker-02` | Worker node |  4   | 16 GiB | 192.168.101.22 | fd00:2::16 |
| `worker-03` | Worker node |  4   | 16 GiB | 192.168.101.23 | fd00:2::17 |

## Features

- **Dual-stack networking** — each VM gets a static IPv4 and IPv6 address on a private NAT network (`k8s.local`)
- **Persistent DNS** — a NetworkManager dispatcher script keeps the lab domain resolvable across reboots
- **SSH config** — host entries generated from Terraform outputs so nodes are reachable by name
- **Cloud-init** — hostname, network, user, and Kubernetes prerequisites configured on first boot
- **HA control plane** — three control plane nodes behind an HAProxy load balancer
- **Cilium** — kube-proxy replacement with full eBPF dataplane, installed via Helm

## Requirements

### KVM / libvirt

The lab runs on KVM via libvirt. Ensure the following are installed and the current user has
access to the `libvirt` group:

```bash
# Debian / Ubuntu
sudo apt install qemu-kvm libvirt-daemon-system virtinst

sudo usermod -aG libvirt $USER   # log out and back in after this
```

Verify KVM is usable:

```bash
virsh -c qemu:///system version
```

### Tools

| Tool | Minimum version | Purpose |
|------|----------------|---------|
| [Terraform](https://www.terraform.io/) | 1.14 | Provision VMs, network, and storage |
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | 1.32 | Interact with the cluster |
| [Helm](https://helm.sh/) | 3.x | Install Cilium |
| [virsh](https://libvirt.org/manpage/virsh.html) | any | Start / stop VMs |
| [NetworkManager](https://networkmanager.dev/) + `resolvectl` | any | Lab DNS resolution |

## Quick start

### 1. Provision the infrastructure

```bash
make init             # Download providers and modules
make apply            # Provision network, storage pool, and VMs
make configure-dns    # Install DNS dispatcher script
make configure-ssh    # Generate SSH config for lab hosts
make start-domains    # Boot all VMs
```

Nodes are then reachable by name:

```bash
ssh control-plane-01
ssh worker-01
```

### 2. Bootstrap the cluster

```bash
make bootstrap        # Run all steps below in sequence
```

Or step by step:

```bash
make setup-lb             # Deploy HAProxy on control-plane-lb
make init-cluster         # Bootstrap the first control plane with kubeadm
make join-control-planes  # Join control-plane-02 and control-plane-03
make join-workers         # Join the worker nodes
make install-cilium       # Install Cilium via Helm
```

### 3. Access the cluster

```bash
export KUBECONFIG=~/.kube/config-k8s-lab
kubectl get nodes
```

## All targets

| Target | Description |
|--------|-------------|
| `make init` | Initialize Terraform |
| `make apply` | Apply infrastructure |
| `make destroy` | Destroy infrastructure |
| `make configure-dns` | Install DNS dispatcher script and configure lab DNS |
| `make configure-ssh` | Generate SSH config for lab hosts |
| `make start-domains` | Start all lab VMs |
| `make stop-domains` | Gracefully shut down all lab VMs |
| `make setup-lb` | Deploy HAProxy on control-plane-lb |
| `make init-cluster` | Bootstrap first control plane with kubeadm |
| `make join-control-planes` | Join control-plane-02 and 03 to the cluster |
| `make join-workers` | Join worker nodes to the cluster |
| `make install-cilium` | Install Cilium via Helm |
| `make bootstrap` | Run all cluster setup steps in sequence |
