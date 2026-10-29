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