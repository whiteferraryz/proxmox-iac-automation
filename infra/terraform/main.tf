module "vm" {
  source   = "./modules/vm"
  for_each = var.vms

  name           = each.key
  vm_id          = each.value.vm_id
  node_name      = each.value.node
  template_id    = var.template_id
  ip             = each.value.ip
  gateway        = var.gateway
  vlan_id        = each.value.vlan_id
  cores          = each.value.cores
  memory         = each.value.memory
  disk_gb        = each.value.disk_gb
  username       = var.username
  ssh_public_key = trimspace(file(var.ssh_public_key_path))
}

# Replication job: gọi thẳng API bằng token của Terraform (không cần SSH root)
resource "terraform_data" "replication" {
  for_each = var.vms
  input = {
    id       = "${each.value.vm_id}-0"
    target   = each.value.node == "pve1" ? "pve2" : "pve1"
    endpoint = var.pm_endpoint
  }

  provisioner "local-exec" {
    command = "curl -sk -X POST -H \"Authorization: PVEAPIToken=$PROXMOX_VE_API_TOKEN\" ${self.input.endpoint}/api2/json/cluster/replication -d id=${self.input.id} -d type=local -d target=${self.input.target} -d 'schedule=*/1'"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "curl -sk -X DELETE -H \"Authorization: PVEAPIToken=$PROXMOX_VE_API_TOKEN\" ${self.input.endpoint}/api2/json/cluster/replication/${self.input.id}"
  }

  depends_on = [module.vm]
}

resource "proxmox_virtual_environment_haresource" "vm" {
  for_each     = { for k, v in var.vms : k => v if v.ha }
  resource_id  = "vm:${each.value.vm_id}"
  state        = "started"
  max_restart  = 1
  max_relocate = 1
  group        = var.ha_group
  depends_on   = [terraform_data.replication]
}