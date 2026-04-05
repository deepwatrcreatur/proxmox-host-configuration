#!/usr/bin/env bash

set -euo pipefail

DKMS_MODULE="${DKMS_MODULE:-realtek-r8125}"
KERNEL_MODULE="${KERNEL_MODULE:-r8125}"

usage() {
  cat <<'EOF'
Rebuild and verify the Realtek r8125 DKMS driver for one or more Proxmox kernels.

Usage:
  rebuild-r8125-dkms.sh [kernel-version ...]

Examples:
  rebuild-r8125-dkms.sh
  rebuild-r8125-dkms.sh 6.17.13-2-pve
  rebuild-r8125-dkms.sh 6.17.13-2-pve 6.17.4-2-pve

If no kernel versions are provided, the script rebuilds the module for every
installed kernel found under /boot/vmlinuz-*.
EOF
}

require_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    echo "This script must be run as root." >&2
    exit 1
  fi
}

collect_kernels() {
  if [[ "$#" -gt 0 ]]; then
    printf '%s\n' "$@"
    return 0
  fi

  find /boot -maxdepth 1 -type f -name 'vmlinuz-*-pve' -printf '%f\n' \
    | sed 's/^vmlinuz-//' \
    | sort -V
}

ensure_headers() {
  local kernel="$1"
  local build_dir="/lib/modules/${kernel}/build"
  local header_pkg="proxmox-headers-${kernel}"

  if [[ -d "${build_dir}" ]]; then
    return 0
  fi

  echo "Installing missing headers: ${header_pkg}"
  apt-get install -y "${header_pkg}"
}

rebuild_kernel() {
  local kernel="$1"

  if [[ ! -d "/lib/modules/${kernel}" ]]; then
    echo "Kernel ${kernel} is not installed under /lib/modules." >&2
    return 1
  fi

  ensure_headers "${kernel}"

  echo "Rebuilding ${DKMS_MODULE} for ${kernel}"
  dkms autoinstall -k "${kernel}"

  echo "Refreshing dependency metadata for ${kernel}"
  depmod "${kernel}"

  echo "Refreshing initramfs for ${kernel}"
  update-initramfs -u -k "${kernel}"

  echo "Verifying ${KERNEL_MODULE} for ${kernel}"
  modinfo -k "${kernel}" "${KERNEL_MODULE}" >/dev/null
}

main() {
  if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
    usage
    exit 0
  fi

  require_root

  mapfile -t kernels < <(collect_kernels "$@")

  if [[ "${#kernels[@]}" -eq 0 ]]; then
    echo "No installed Proxmox kernels were found under /boot." >&2
    exit 1
  fi

  for kernel in "${kernels[@]}"; do
    rebuild_kernel "${kernel}"
  done

  echo "Refreshing Proxmox boot entries"
  proxmox-boot-tool refresh

  echo
  echo "DKMS status:"
  dkms status -m "${DKMS_MODULE}" || true
}

main "$@"
