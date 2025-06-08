#!/usr/bin/env bash
# Rocky Linux 9 LXC Installer for Proxmox
# https://github.com/kkgogogo17/proxmox_script.git

set -e

# shellcheck source=/dev/null
source <(curl -fsSL https://raw.githubusercontent.com/tteck/Proxmox/main/misc/build.func)
variables
color

APP="Rocky Linux 9"
var_os="rockylinux-9-default_20240912_amd64.tar.xz"
var_template="local:vztmpl/${var_os}"
var_ctid=$(pvesh get /cluster/nextid)
var_hostname="rocky9"
var_password="changeme"

read -p "Disk Size (default 32): " input_disk
read -p "CPU Cores (default 2): " input_cpu
read -p "RAM (MB) (default 2048): " input_ram

var_disk="${input_disk:-32}"
var_cpu="${input_cpu:-2}"
var_ram="${input_ram:-2048}"
var_net="name=eth0,bridge=vmbr0"

msg_info "Downloading Rocky Linux 9 LXC Template"
pveam update >/dev/null
pveam available | grep rockylinux-9 || error_exit "Template not found. Try manually downloading from Proxmox or importing."
pveam download local $var_os >/dev/null || error_exit "Failed to download template"
msg_ok "Template downloaded"

msg_info "Creating LXC Container for $APP"

pct create $var_ctid $var_template \
  -hostname $var_hostname \
  -password $var_password \
  -storage local-lvm \
  -rootfs ${var_disk}G \
  -cores $var_cpu \
  -memory $var_ram \
  -net0 "$var_net" \
  -features nesting=1 \
  -unprivileged 1 \
  -start 1 >/dev/null
msg_ok "LXC Container Created (CTID: $var_ctid)"

msg_info "Updating Rocky Linux in container"
pct exec $var_ctid -- dnf -y update >/dev/null
msg_ok "System Updated"

msg_ok "$APP LXC deployed successfully!"
echo "Default password: ${var_password}"
echo "To access: pct console $var_ctid"
