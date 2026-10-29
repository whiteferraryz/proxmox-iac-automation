ssh_public_key_path = "/root/.ssh/lab_ed25519.pub"
vms = {
  web01 = { 
    vm_id = 110, 
    node  = "pve1", 
    ip    = "10.10.20.31" 
  },
  web02 = { 
    vm_id = 111, 
    node  = "pve1", 
    ip    = "10.10.20.32" 
  }
}
