# ───────────────────────────────────────
# Common locals
# ───────────────────────────────────────

locals {
  lab_name        = "k8s-lab"
  base_image_name = "debian-12-base.qcow2"
  user            = "debian"
  ssh_public_key  = file("~/.ssh/id_ed25519.pub")
}

# ───────────────────────────────────────
# Guest configurations
# ───────────────────────────────────────

locals {
  guests = [
    {
      name          = "jumpbox"
      hostname      = "jumpbox"
      ipv4_address  = "192.168.100.10"
      ipv6_address  = "fd00:1::a"
      vcpu          = 1
      memory        = 512
      disk_capacity = 10
    },
    {
      name          = "server"
      hostname      = "server"
      ipv4_address  = "192.168.100.11"
      ipv6_address  = "fd00:1::b"
      vcpu          = 1
      memory        = 2048
      disk_capacity = 20
    },
    {
      name          = "node-0"
      hostname      = "node-0"
      ipv4_address  = "192.168.100.12"
      ipv6_address  = "fd00:1::c"
      vcpu          = 1
      memory        = 2048
      disk_capacity = 20
    },
    {
      name          = "node-1"
      hostname      = "node-1"
      ipv4_address  = "192.168.100.13"
      ipv6_address  = "fd00:1::d"
      vcpu          = 1
      memory        = 2048
      disk_capacity = 20
    },
  ]
}

# ───────────────────────────────────────
# Network
# ───────────────────────────────────────

module "network" {
  source = "git::https://github.com/yannlambret/tf-modules.git//libvirt/network?ref=libvirt/network/v0.2.0"

  network = {
    name      = local.lab_name
    bridge    = "k8slab"
    ipv4_cidr = "192.168.100.0/24"
    ipv6_cidr = "fd00:1::/64"
    domain    = "${local.lab_name}.local"
  }

  static_hosts = [
    for g in local.guests : {
      ip       = g.ipv4_address
      hostname = g.hostname
    }
  ]
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
      name   = local.base_image_name
      source = "https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-generic-amd64.qcow2"
      format = "qcow2"
    },
  ]
}

# ───────────────────────────────────────
# VMs
# ───────────────────────────────────────

module "cloudinit" {
  source = "git::https://github.com/yannlambret/tf-modules.git//libvirt/cloudinit?ref=libvirt/cloudinit/v0.2.0"

  for_each = { for item in local.guests : item.name => item }

  cloudinit = {
    name                 = each.value.name
    hostname             = each.value.hostname
    ipv4_address         = each.value.ipv4_address
    ipv6_address         = each.value.ipv6_address
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
  source = "git::https://github.com/yannlambret/tf-modules.git//libvirt/vm?ref=libvirt/vm/v0.5.0"

  for_each = { for item in local.guests : item.name => item }

  vm = {
    name                = each.value.name
    vcpu                = each.value.vcpu
    memory              = each.value.memory        // MiB
    disk_capacity       = each.value.disk_capacity // GiB
    static_ipv4_address = each.value.ipv4_address
    network             = module.network.name
    pool                = module.storage_pool.name
    base_image          = module.storage_pool.base_images[local.base_image_name]
    cloudinit_path      = module.cloudinit[each.key].path
  }
}
