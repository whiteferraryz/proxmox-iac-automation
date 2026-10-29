variable "name"           { type = string }
variable "vm_id"          { type = number }
variable "node_name"      { type = string }
variable "template_id"    { type = number }
variable "ip"             { type = string }
variable "gateway"        { type = string }
variable "vlan_id"        { type = number }
variable "cores"          { type = number }
variable "memory"         { type = number }
variable "disk_gb"        { type = number }
variable "username"       { type = string }
variable "ssh_public_key" { type = string }
variable "dns"            { type = list(string) default = ["192.168.42.2"] }

variable "pm_endpoint" {
  type    = string
  default = "https://192.168.42.11:8006"
}
variable "template_id"         { type = number  default = 9000 }
variable "gateway"             { type = string  default = "10.10.20.1" }
variable "username"            { type = string  default = "ops" }
variable "ssh_public_key_path" { type = string  default = "~/.ssh/lab_ed25519.pub" }
variable "ha_group"            { type = string  default = null }

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