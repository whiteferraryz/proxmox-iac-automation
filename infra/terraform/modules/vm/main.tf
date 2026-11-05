terraform {
  required_providers {
    proxmox = { source = "bpg/proxmox" }
  }
}

resource "proxmox_virtual_environment_vm" "this" {
  name      = var.name
  node_name = var.node_name
  vm_id     = var.vm_id
  tags      = ["terraform", "lab"]
  on_boot   = true

  clone {
    vm_id = var.template_id
    full  = true
  }

  agent {
    enabled = true
    timeout = "5m"
  }

  cpu {
    cores = var.cores
    type  = "x86-64-v2-AES"
  }

  memory {
    dedicated = var.memory
  }

  disk {
    datastore_id = "tank"
    interface    = "scsi0"
    size         = var.disk_gb
    discard      = "on"
  }

  network_device {
    bridge  = "vmbr1"
    vlan_id = var.vlan_id
  }

  initialization {
    datastore_id = "tank"
    ip_config {
      ipv4 {
        address = "${var.ip}/24"
        gateway = var.gateway
      }
    }
    dns {
      servers = var.dns
    }
    user_account {
      username = var.username
      keys     = [var.ssh_public_key]
    }
  }
}

output "vm_id" { value = proxmox_virtual_environment_vm.this.vm_id }
