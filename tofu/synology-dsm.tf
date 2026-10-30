# Synology DSM Virtual Machine (VM 210)
#
# Hardware baseline matching live VM 210 on pve-rog.
# Backend storage: ZFS RAIDZ1 pool ('tank') via thin zvol with discard enabled.

resource "proxmox_virtual_environment_vm" "synology_dsm" {
  node_name = var.pve_target_node
  vm_id     = var.synology_vm_id
  name      = "synology-dsm"
  started   = true
  on_boot   = true

  machine = "q35"

  operating_system {
    type = "l26"
  }

  cpu {
    cores = 4
    type  = "host"
  }

  memory {
    dedicated = 4096
  }

  # RedPill / ARC loader boot disk
  disk {
    datastore_id = "local-lvm"
    interface    = "sata0"
    size         = 2 # GiB
  }

  # Data disk on ZFS pool (thin zvol with discard enabled)
  # IMPORTANT: The underlying zvol 'tank/vm-210-disk-0' on the host must have
  # 'refreservation=none' set so unallocated space is freed back to ZFS pool.
  disk {
    datastore_id = "tank-pool"
    interface    = "sata1"
    size         = 2000 # GiB
    discard      = "on"
  }

  network_device {
    bridge      = "vmbr0"
    mac_address = "BC:24:11:53:D5:D0"
    model       = "virtio"
  }

  serial_device {}

  lifecycle {
    ignore_changes = [
      started,
    ]
  }
}
