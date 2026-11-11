terraform {
  required_version = ">= 1.6"
  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      # ghim phiên bản hiện hành (xem registry.terraform.io/providers/bpg/proxmox), ví dụ "~> 0.x"
    }
  }
}

provider "proxmox" {
  endpoint  = "https://192.168.42.11:8006/api2/json"
  api_token = "root@pam!terraform=${var.proxmox_api_token}"
  insecure  = true
}