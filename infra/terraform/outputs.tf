output "vm_ips" {
  value = { for k, v in var.vms : k => v.ip }
}