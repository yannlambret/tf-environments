# tf-environments

Terraform configurations for local lab environments running on libvirt/KVM.

Each environment is self-contained — it provisions its own network, storage pool, and VMs using
shared modules from [tf-modules](https://github.com/yannlambret/tf-modules).

## Environments

| Environment | Description |
|-------------|-------------|
| [`k8s-lab`](k8s-lab/) | Multi-node Kubernetes cluster with a distributed control plane, HAProxy load balancer, and kubeadm-based setup |
