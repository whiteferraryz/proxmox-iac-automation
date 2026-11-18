# QUY HOẠCH IP

## 1. Cấu hình 3 NIC cho mỗi Node Proxmox

| NIC | VMware | Vai trò | Mạng |
| :--- | :--- | :--- | :--- |
| **nic0** | VMnet8 (NAT) | Management + Internet | `192.168.42.0/24` |
| **nic1** | LAN segment (VM trunk) | Trunk cho VMware (`vmbr1`) VLAN-aware | `VLAN 10/20/30` |
| **nic2** | LAN segment (REPL) | Replication + live migration + corosync link dự phòng | `10.10.99.0/24` |

---

## 2. Dải IP và VLAN

| Mạng | VLAN | Subnet | Mục đích |
| :--- | :--- | :--- | :--- |
| **Management** | untagged | `192.168.42.0/24` | Web UI, SSH, PBS, QDevice |
| **Server** | 10 | `10.10.10.0/24` | VM hạ tầng (monitoring, runner CI) |
| **App/Dev** | 20 | `10.10.20.0/20` | VM tạo bằng Terraform, đích của Ansible |
| **DMZ/Test** | 30 | `10.10.30.0/24` | VM demo firewall, test cô lập |
| **Replication** | không | `10.10.99.0/24` | ZFS replication, migration |

---

## 3. Gán địa chỉ IP cố định

| Thiết bị | Management | Replication |
| :--- | :--- | :--- |
| **pve1** | `192.168.42.11` | `10.10.99.11` |
| **pve2** | `192.168.42.12` | `10.10.99.12` |
| **QDevice** | `192.168.42.13` | `-` |
| **PBS** | `192.168.42.14` | `-` |
| **pve3** | `192.168.42.15` | `10.10.99.15` |
| **ControlNode** | `192.168.42.20` | `-` |

### Quy tắc quy hoạch bổ sung:
* **Gateway:** Mỗi VLAN sử dụng địa chỉ `.1` (ví dụ: `10.10.10.1`).
* **Máy hạ tầng:** Sử dụng dải từ `.2` đến `.9`.
* **VM (Máy ảo):** Sử dụng dải từ `.10` trở lên.