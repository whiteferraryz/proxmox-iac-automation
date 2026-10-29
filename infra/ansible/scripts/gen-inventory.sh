#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../../terraform"

{
  echo "[lab_vms]"
  terraform output -json vm_ips | jq -r 'to_entries[] | "\(.key) ansible_host=\(.value)"'
  echo
  echo "[lab_vms:vars]"
  echo "ansible_user=ops"
  echo "ansible_ssh_private_key_file=~/.ssh/lab__ed25519"
} > ../ansible/inventory/hosts.ini
