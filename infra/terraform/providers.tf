terraform {
  required_version = ">= 1.6"
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      # ghim phiên bản hiện hành (xem registry.terraform.io/providers/bpg/proxmox), ví dụ "~> 0.x"
    }
  }
}

provider "proxmox" {} # endpoint, token, insecure lấy từ PROXMOX_VE_*