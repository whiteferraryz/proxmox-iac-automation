variable "pm_endpoint" {
  type    = string
  default = "https://192.168.42.11:8006"
}

variable "template_id" {
  type    = number
  default = 9000
}

variable "gateway" {
  type    = string
  default = "10.10.20.1"
}

variable "username" {
  type    = string
  default = "ops"
}

variable "ssh_public_key_path" {
  type    = string
  default = "~/.ssh/lab__ed25519.pub"
}

variable "ha_group" {
  type    = string
  default = null
}

variable "vms" {
  type = map(object({
    vm_id   = number
    node    = string
    ip      = string
    vlan_id = optional(number, 20)
    cores   = optional(number, 1)
    memory  = optional(number, 384)
    disk_gb = optional(number, 5)
    ha      = optional(bool, true)
  }))
}
