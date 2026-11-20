# Hạ tầng ảo hoá / Private Cloud trên Proxmox VE thay thế VMware

Đồ án thực tập: nghiên cứu, thiết kế và triển khai (quy mô lab, nested virtualization) một hạ tầng ảo hoá/private cloud trên **Proxmox VE** để thay thế VMware, kèm tự động hoá hạ tầng bằng **Terraform, cloud-init, Ansible** và pipeline CI/CD.

- Người thực hiện:Nguyễn Vĩnh Thắng
- Thời gian: 4 tuần (24 ngày làm việc)
- Phiên bản lab: Proxmox VE 9.2.2 (Debian 13)

> Lab chạy trên máy cá nhân (khoảng 6GB RAM, 100GB ổ đĩa) bằng VMware Workstation. Số liệu hiệu năng trên nested chỉ có giá trị **so sánh tương đối**, không đại diện phần cứng thật.

## 1. Mục tiêu

Mục tiêu của dự án là xây dựng và chuyển đổi hạ tầng từ VMware sang Proxmox VE, tập trung vào việc tối ưu hóa chi phí thông qua phân tích so sánh TCO trong vòng 3–5 năm. Hệ thống đảm bảo tính ổn định cao với kiến trúc cluster 2 node kết hợp QDevice, ZFS replication, live migration, HA và quy trình backup/restore tối ưu RTO/RPO. Về mặt bảo mật, dự án áp dụng các tiêu chuẩn như RBAC, 2FA, firewall datacenter, phân tách mạng và hardening toàn diện cho cả host lẫn VM. Khả năng mở rộng (scale-out) được định hướng qua việc thêm node thứ 3 và thiết kế cụm Ceph 3–5 node. Quá trình chuyển đổi từ VMware được thực hiện bài bản với các runbook migrate VM Linux sử dụng qm importdisk và VirtIO kèm theo đánh giá downtime, kết hợp tự động hóa toàn bộ quy trình triển khai thông qua Terraform, cloud-init, Ansible và GitLab CI.

## 2. Kiến trúc lab

```
                 Internet
                    |
          VMware NAT (VMnet8) 192.168.42.0/24
      ┌─────────────┼───────────────┬──────────────┐
   pve1 (.11)    pve2 (.12)    control node (.20)  QDevice (.13)  PBS (.14)
      │             │                 │
      ├── LAN Segment VM-TRUNK (VLAN 10/20/30) ──┘   gateway VLAN 20 = 10.10.20.1
      └── LAN Segment REPL 10.10.99.0/24 (replication, migration, corosync link1)
```

## 🏗️ Kiến trúc & Thành phần hệ thống

* **Compute & Storage (`pve1`, `pve2`):** Proxmox VE (nested virtualization), cấu hình 2 vCPU, 2.5GB RAM, sử dụng ZFS pool `tank` (single disk).
* **Quorum (`QDevice`):** VM Debian tối giản chạy `corosync-qnetd` để duy trì quorum cho cluster 2 node.
* **Backup (`PBS`):** Proxmox Backup Server triển khai trên VM độc lập nằm ngoài cluster.
* **Automation & Monitoring (`Control node`):** Máy chủ quản lý tập trung tích hợp Terraform, Ansible, GitLab Runner, Prometheus và Grafana.

> 📌 **Tài liệu chi tiết:** Xem quy hoạch IP/VLAN tại [`docs/01-architecture/ip-plan.md`](docs/01-architecture/ip-plan.md) và sơ đồ mạng tại [`docs/01-architecture/network-diagram.md`](docs/01-architecture/network-diagram.md).

## 3. Cấu trúc thư mục


```
├── .gitlab-ci.yml                 # Pipeline validate, plan, apply thủ công và configure
├── README.md
├── docs/                          # Tài liệu dự án
├── evidence/                      # Ảnh chụp và bằng chứng triển khai
└── infra/
    ├── ansible/
    │   ├── inventory/             # Inventory Ansible
    │   ├── roles/
    │   │   └── baseline_hardening/ # Role cấu hình và tăng cường bảo mật máy chủ
    │   ├── scripts/               # Script hỗ trợ Ansible
    │   ├── ansible.cfg
    │   └── site.yml               # Playbook chính
    ├── keys/                      # Public key SSH dùng cho máy ảo
    ├── monitoring/                # Dashboard giám sát Proxmox và Node Exporter
    └── terraform/
        ├── modules/
        │   └── vm/                # Module Terraform tạo máy ảo
        ├── backend.tf             # Cấu hình Terraform backend
        ├── main.tf                # Khai báo tài nguyên hạ tầng
        ├── outputs.tf             # Các giá trị đầu ra
        ├── providers.tf            # Cấu hình provider
        ├── variables.tf           # Khai báo biến đầu vào
        └── terraform.tfvars       # Giá trị biến môi trường
```
## 4. Bắt đầu nhanh

### 4.1 Điều kiện
- Cluster Proxmox đã chạy, template cloud-init `9000` trên `pve1`, storage `tank` trên cả hai node.
- Control node có `terraform` (>= 1.6), `ansible`, `jq`, `curl`, và cặp khoá SSH `~/.ssh/lab_ed25519`.
- Role + API token cho Terraform (xem `proxmox/rbac-setup.sh`; secret **không** commit).

### 4.2 Terraform

```bash
cat > ~/.config/proxmox.env <<'ENV'
export PROXMOX_VE_ENDPOINT="https://192.168.42.11:8006/"
export PROXMOX_VE_API_TOKEN="terraform@pve!tf2=<secret>"
export PROXMOX_VE_INSECURE="true"      # cert tự ký trong lab
ENV
chmod 600 ~/.config/proxmox.env && source ~/.config/proxmox.env

cd infra/terraform
terraform fmt -recursive
```

- **State cục bộ (không dùng GitLab):** đổi tên `backend.tf` thành `backend.tf.disabled`, rồi `terraform init`.
- **State do GitLab quản lý:** `terraform init -backend-config=...` (địa chỉ, khoá lock, username, token cá nhân); xem ví dụ trong `.gitlab-ci.yml`.

```bash
terraform validate
terraform plan -out tfplan
terraform apply tfplan
terraform output vm_ips
```


### 4.3 Ansible

```bash
cd infra/ansible
./scripts/gen-inventory.sh                 # sinh inventory từ output Terraform
ansible all -m ping
ansible-playbook site.yml                  # lần 2 phải cho changed=0 (idempotent)
ansible-playbook site.yml --tags ssh,firewall
```

### 4.4 CI/CD (GitLab)
Luồng: Merge Request chạy `fmt/validate/lint` + `plan`; trên `main` chạy `plan`, **`apply` bấm tay**, rồi Ansible tự chạy.
Cần runner tag `lab` trên control node, biến CI `PM_TOKEN_SECRET` (masked) và khoá SSH cho user `gitlab-runner`. Runner tự host chỉ dùng cho project **private**.

### 4.5 Monitoring và benchmark
- `monitoring/`: Prometheus + `pve-exporter` + Grafana trên control node (token chỉ đọc).
- `benchmark/`: `bench-disk.sh`, `bench-net.sh`, `summarize.py` (xem README trong thư mục).

## 5. Kịch bản demo

1. `terraform apply` tạo VM (kèm replication và HA).
2. Ansible hardening các VM.
3. Tắt đột ngột một node Proxmox.
4. HA tự khởi động lại VM trên node còn lại; Grafana hiện cảnh báo `NodeDown`.

## 6. Quản lý bí mật

Không commit: token Proxmox, `*.env`, khoá SSH, `terraform.tfstate`, `pve.yml` của exporter, file backup cấu hình (chứa `authkey` corosync). Đã có trong `.gitignore`. Che token/mật khẩu trong ảnh chụp trước khi lưu vào `evidence/`.

## 7. Giới hạn của lab

- Nested virtualization: số đo chỉ so sánh tương đối; watchdog `softdog`; mạng ảo (LAN Segment).
- ZFS single-disk, replication bất đồng bộ (RPO > 0); Ceph chỉ thiết kế trên giấy.
- Migration từ VMware: VM Linux, cold migration; chưa làm Windows.
- Live migration dùng mode `insecure` trong mạng REPL cô lập (chỉ chấp nhận trong lab).
- Tài khoản cục bộ thay cho AD/OIDC; chứng chỉ tự ký.

## 8. Tiến độ 24 ngày

| Tuần | Nội dung | Thư mục |
|---|---|---|
| 1 (ngày 1–6) | Cluster, mạng VLAN, QDevice, ZFS, khảo sát giải pháp | `docs/01-architecture`, `docs/02-survey`, `proxmox/` |
| 2 (ngày 7–12) | Replication, live migration, HA, PBS, migration từ VMware | `docs/03-deployment`, `docs/04-runbooks` |
| 3 (ngày 13–18) | Template, Terraform, Ansible, hardening host, CI, monitoring | `terraform/`, `ansible/`, `.gitlab-ci.yml`, `monitoring/`, `docs/05-security` |
| 4 (ngày 19–24) | Benchmark, scale-out, TCO, ma trận rủi ro, báo cáo, demo | `benchmark/`, `docs/06-evaluation`, `docs/07-scale-out` |

## 9. Tài liệu tham khảo

- Tài liệu Proxmox VE, Proxmox Backup Server (pve.proxmox.com, pbs.proxmox.com)
- Provider Terraform `bpg/proxmox` (registry.terraform.io/providers/bpg/proxmox)
- Tài liệu Ansible, GitLab CI/CD và Terraform state do GitLab quản lý
- Trang giá và tài liệu licensing: proxmox.com, Broadcom/VMware (xem nguồn và ngày tra trong `docs/06-evaluation/tco.md`)
