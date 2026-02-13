# Kubernetes The Hard Way — libvirt lab

A local Kubernetes lab environment built with Terraform and libvirt, following the
[Kubernetes The Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way) guide.

The lab provisions four VMs (`jumpbox`, `server`, `node-0`, `node-1`) on a private
NAT network, with static IP addresses, cloud-init configuration, and persistent DNS
resolution — so hostnames work out of the box and survive reboots.

## Requirements

- [Terraform](https://www.terraform.io/) >= 1.14
- [libvirt](https://libvirt.org/) with QEMU/KVM
- [NetworkManager](https://networkmanager.dev/) with `resolvectl`
- [virsh](https://libvirt.org/manpage/virsh.html) (required for `start-domains`/`stop-domains`)

## Usage

### 1. Initialize and apply

```bash
make init
make apply
```

* `init` downloads the Terraform providers and modules.
* `apply` provisions the network, storage pool, and VMs.

### 2. Configure DNS

```bash
make configure-dns
```

Installs a NetworkManager dispatcher script that automatically configures DNS resolution
via `resolvectl` whenever the lab bridge interface comes up. The script runs immediately
after installation, so DNS is active right away — and will be restored automatically
after every reboot, without any manual intervention.

### 3. Configure SSH

```bash
make configure-ssh
```

Generates `~/.ssh/config.d/k8s-lab` with a `Host` entry for each VM, populated with
the IP addresses from Terraform outputs. Also ensures `~/.ssh/config` contains an
`Include config.d/*` directive so the entries are picked up automatically by SSH.

VMs can then be reached directly by name:

```bash
ssh jumpbox
ssh server
ssh node-0
ssh node-1
```

### 4. Managing VMs

```bash
make start-domains   # Start all VMs
make stop-domains    # Gracefully shut down all VMs
```

### 5. Teardown

```bash
make destroy
```

Destroys all Terraform-managed resources (VMs, network, storage pool).

## All targets

| Target | Description |
|---|---|
| `make init` | Initialize Terraform |
| `make apply` | Apply infrastructure |
| `make destroy` | Destroy infrastructure |
| `make configure-dns` | Install DNS dispatcher script and configure lab DNS |
| `make configure-ssh` | Generate SSH config for lab hosts |
| `make start-domains` | Start all lab VMs |
| `make stop-domains` | Stop all lab VMs |
