# k8s-lab

A local multi-node Kubernetes lab provisioned with Terraform and libvirt, using kubeadm for
cluster setup. Designed for personal use and experimentation.

## Cluster layout

| VM | Role | vCPU | RAM | IPv4 | IPv6 |
|----|------|:----:|:---:|------|------|
| `control-plane-lb` | HAProxy load balancer | 1 | 1 GiB | 192.168.101.10 | fd00:2::a |
| `control-plane-01` | Control plane | 1 | 2 GiB | 192.168.101.11 | fd00:2::b |
| `control-plane-02` | Control plane | 1 | 2 GiB | 192.168.101.12 | fd00:2::c |
| `control-plane-03` | Control plane | 1 | 2 GiB | 192.168.101.13 | fd00:2::d |
| `worker-01` | Worker node | 4 | 16 GiB | 192.168.101.21 | fd00:2::15 |
| `worker-02` | Worker node | 4 | 16 GiB | 192.168.101.22 | fd00:2::16 |
| `worker-03` | Worker node | 4 | 16 GiB | 192.168.101.23 | fd00:2::17 |

## Features

- **Dual-stack networking** — each VM gets a static IPv4 and IPv6 address on a private NAT network (`k8s.local`)
- **Cloud-init** — hostname, network, user, and Kubernetes prerequisites configured on first boot
- **Persistent DNS** — a NetworkManager dispatcher script keeps the lab domain resolvable across reboots
- **SSH config** — host entries generated from Terraform outputs so nodes are reachable by name
- **UEFI boot** — Q35 machine type with OVMF firmware; firmware resolved automatically from host descriptors

## Quick start

```bash
make init             # Download providers and modules
make apply            # Provision network, storage pool, and VMs
make configure-dns    # Install DNS dispatcher script
make configure-ssh    # Generate SSH config for lab hosts
make start-domains    # Boot all VMs
```

Nodes are then reachable by name:

```bash
ssh control-plane-lb
ssh control-plane-01
ssh worker-01
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

## Requirements

- [Terraform](https://www.terraform.io/) >= 1.14
- [libvirt](https://libvirt.org/) with QEMU/KVM
- [NetworkManager](https://networkmanager.dev/) with `resolvectl`
- [virsh](https://libvirt.org/manpage/virsh.html) (required for `start-domains` / `stop-domains`)
