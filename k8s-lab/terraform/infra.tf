# ───────────────────────────────────────
# Common locals
# ───────────────────────────────────────

locals {
  lab_name    = "k8s-lab"
  domain_name = "k8s.local"

  ipv4_network_cidr = "192.168.101.0/24"
  ipv6_network_cidr = "fd00:2::/64"

  # Kubernetes versions — must stay in sync with kubernetesVersion in config/kubeadm-config.yaml.
  # Minor version selects the apt repository; patch version pins the installed packages.
  k8s_minor_version = "v1.34"
  k8s_patch_version = "1.34.5"

  # Cilium LB-IPAM pool and system gateway IP.
  # These values are the single source of truth shared with the Kubernetes
  # manifest layer via config/lab.env (rendered by the local_file resource below).
  cilium_lb_pool_cidr = "192.168.101.128/25"
  cilium_gateway_ip   = "192.168.101.128"

  base_image = {
    name   = "ubuntu-22.04-base.qcow2"
    source = "https://cloud-images.ubuntu.com/releases/22.04/release/ubuntu-22.04-server-cloudimg-amd64-disk-kvm.img"
    format = "qcow2"
  }

  user           = "ubuntu"
  ssh_public_key = file("~/.ssh/id_ed25519.pub")
}

# ───────────────────────────────────────
# Node prerequisites (kubeadm)
# ───────────────────────────────────────

locals {
  k8s_node_extra_user_data = <<-EOT
    runcmd:
      # ── Kernel modules ──────────────────────────────────────────────────────
      - printf 'overlay\nbr_netfilter\n' > /etc/modules-load.d/k8s.conf
      - modprobe overlay
      - modprobe br_netfilter

      # ── Sysctl ───────────────────────────────────────────────────────────────
      - |
        cat > /etc/sysctl.d/k8s.conf << 'EOF'
        net.bridge.bridge-nf-call-iptables  = 1
        net.bridge.bridge-nf-call-ip6tables = 1
        net.ipv4.ip_forward                 = 1
        net.ipv6.conf.all.forwarding        = 1
        EOF
      - sysctl --system

      # ── Swap ─────────────────────────────────────────────────────────────────
      - swapoff -a
      - sed -i '/\sswap\s/s/^/#/' /etc/fstab

      # ── containerd ───────────────────────────────────────────────────────────
      - install -m 0755 -d /etc/apt/keyrings
      - >-
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg
        -o /etc/apt/keyrings/docker.asc
      - chmod a+r /etc/apt/keyrings/docker.asc
      - >-
        echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.asc]
        https://download.docker.com/linux/ubuntu jammy stable"
        > /etc/apt/sources.list.d/docker.list
      - apt-get update -qq
      - apt-get install -y containerd.io
      - containerd config default > /etc/containerd/config.toml
      - sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
      - systemctl enable containerd
      - systemctl restart containerd

      # ── kubeadm, kubelet, kubectl ────────────────────────────────────────────
      - >-
        curl -fsSL https://pkgs.k8s.io/core:/stable:/${local.k8s_minor_version}/deb/Release.key
        | gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
      - >-
        echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg]
        https://pkgs.k8s.io/core:/stable:/${local.k8s_minor_version}/deb/ /"
        > /etc/apt/sources.list.d/kubernetes.list
      - apt-get update -qq
      - apt-get install -y kubelet=${local.k8s_patch_version}-* kubeadm=${local.k8s_patch_version}-* kubectl=${local.k8s_patch_version}-*
      - apt-mark hold kubelet kubeadm kubectl
      - systemctl enable kubelet
    EOT
}

# ───────────────────────────────────────
# Guest configurations
# ───────────────────────────────────────

locals {
  guests = [
    {
      name            = "control-plane-lb"
      hostname        = "control-plane-lb"
      ipv4_address    = "192.168.101.10"
      ipv6_address    = "fd00:2::a"
      vcpu            = 1
      memory          = 1024
      disk_capacity   = 10
      extra_user_data = <<-EOT
        packages:
          - docker.io

        runcmd:
          - systemctl enable --now docker
        EOT
    },
    {
      name            = "control-plane-01"
      hostname        = "control-plane-01"
      ipv4_address    = "192.168.101.11"
      ipv6_address    = "fd00:2::b"
      vcpu            = 2
      memory          = 2048
      disk_capacity   = 20
      extra_user_data = local.k8s_node_extra_user_data
    },
    {
      name            = "control-plane-02"
      hostname        = "control-plane-02"
      ipv4_address    = "192.168.101.12"
      ipv6_address    = "fd00:2::c"
      vcpu            = 2
      memory          = 2048
      disk_capacity   = 20
      extra_user_data = local.k8s_node_extra_user_data
    },
    {
      name            = "control-plane-03"
      hostname        = "control-plane-03"
      ipv4_address    = "192.168.101.13"
      ipv6_address    = "fd00:2::d"
      vcpu            = 2
      memory          = 2048
      disk_capacity   = 20
      extra_user_data = local.k8s_node_extra_user_data
    },
    {
      name            = "worker-01"
      hostname        = "worker-01"
      ipv4_address    = "192.168.101.21"
      ipv6_address    = "fd00:2::15"
      vcpu            = 4
      memory          = 16384
      disk_capacity   = 20
      extra_user_data = local.k8s_node_extra_user_data
    },
    {
      name            = "worker-02"
      hostname        = "worker-02"
      ipv4_address    = "192.168.101.22"
      ipv6_address    = "fd00:2::16"
      vcpu            = 4
      memory          = 16384
      disk_capacity   = 20
      extra_user_data = local.k8s_node_extra_user_data
    },
    {
      name            = "worker-03"
      hostname        = "worker-03"
      ipv4_address    = "192.168.101.23"
      ipv6_address    = "fd00:2::17"
      vcpu            = 4
      memory          = 16384
      disk_capacity   = 20
      extra_user_data = local.k8s_node_extra_user_data
    },
  ]
}

# ───────────────────────────────────────
# Cluster service DNS entries
# ───────────────────────────────────────

locals {
  # Static DNS entries for cluster services exposed via Cilium LB-IPAM.
  # These must match the lb.lbipam.cilium.io/ips annotation on the corresponding Gateway/Service.
  service_hosts = [
    {
      ipv4     = local.cilium_gateway_ip
      hostname = "grafana"
    },
    {
      ipv4     = local.cilium_gateway_ip
      hostname = "prometheus"
    },
  ]
}

# ───────────────────────────────────────
# Network
# ───────────────────────────────────────

module "network" {
  source = "git::https://github.com/yannlambret/tf-modules.git//libvirt/network?ref=libvirt/network/v0.3.0"

  network = {
    name      = local.lab_name
    bridge    = local.lab_name
    ipv4_cidr = local.ipv4_network_cidr
    ipv6_cidr = local.ipv6_network_cidr
    domain    = local.domain_name
  }

  static_hosts = concat(
    [
      for g in local.guests : {
        ipv4     = g.ipv4_address
        ipv6     = g.ipv6_address
        hostname = g.hostname
      }
    ],
    local.service_hosts
  )
}

# ───────────────────────────────────────
# Storage pool
# ───────────────────────────────────────

module "storage_pool" {
  source = "git::https://github.com/yannlambret/tf-modules.git//libvirt/storage-pool?ref=libvirt/storage-pool/v0.1.0"

  pool = {
    name = local.lab_name
    path = "/var/lib/libvirt/${local.lab_name}-images"
  }

  base_images = [
    {
      name   = local.base_image.name
      source = local.base_image.source
      format = local.base_image.format
    },
  ]
}

# ───────────────────────────────────────
# VMs
# ───────────────────────────────────────

module "cloudinit" {
  source = "git::https://github.com/yannlambret/tf-modules.git//libvirt/cloudinit?ref=libvirt/cloudinit/v0.3.0"

  for_each = { for item in local.guests : item.name => item }

  cloudinit = {
    name                 = each.value.name
    hostname             = each.value.hostname
    ipv4_address         = each.value.ipv4_address
    ipv6_address         = each.value.ipv6_address
    extra_user_data      = each.value.extra_user_data
    gateway_ipv4_address = module.network.gateway_ipv4_address
    gateway_ipv6_address = module.network.gateway_ipv6_address
    ipv4_network_cidr    = module.network.ipv4_cidr
    ipv6_network_cidr    = module.network.ipv6_cidr
    domain               = module.network.domain
    pool                 = module.storage_pool.name
    user                 = local.user
    ssh_public_key       = local.ssh_public_key
  }
}

module "vm" {
  source = "git::https://github.com/yannlambret/tf-modules.git//libvirt/vm?ref=libvirt/vm/v0.6.0"

  for_each = { for item in local.guests : item.name => item }

  vm = {
    name                = each.value.name
    vcpu                = each.value.vcpu
    memory              = each.value.memory        // MiB
    disk_capacity       = each.value.disk_capacity // GiB
    static_ipv4_address = each.value.ipv4_address
    network             = module.network.name
    pool                = module.storage_pool.name
    base_image          = module.storage_pool.base_images[local.base_image.name]
    cloudinit_path      = module.cloudinit[each.key].volume_path
  }
}

# ───────────────────────────────────────
# Manifest values file
# ───────────────────────────────────────

resource "local_file" "lab_env" {
  filename        = "${path.module}/../config/lab.env"
  file_permission = "0644"
  content         = <<-EOT
    CILIUM_GATEWAY_IP=${local.cilium_gateway_ip}
    CILIUM_LB_POOL_CIDR=${local.cilium_lb_pool_cidr}
  EOT
}
