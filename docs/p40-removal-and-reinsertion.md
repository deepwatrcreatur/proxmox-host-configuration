# Tesla P40 Removal and Reinsertion Notes

## What Happened (2026-04-04)

The NVIDIA Tesla P40 (`10de:1b38`) was **physically removed** from `pve-tomahawk`
between the clean poweroff at 18:04 EDT and restart at 18:24 EDT on April 4, 2026.

- **Not a crash or hardware failure** — no PCIe AER errors, no GPU hang, no
  `device lost from bus` in the journal. The system powered off cleanly.
- The P40 occupied PCIe slot `0000:01:00.0` prior to removal.
- After restart, that slot contains an ADATA NVMe (`1cc1:621a`).
- The P40 is not detectable anywhere on the host (`lspci` confirms absence).

The live VM 103 (`inference1`) config was also updated at removal time to drop the
`hostpci0` passthrough line. The repo baseline (`vm-configs/inference1.conf`) still
reflects the intended P40 passthrough configuration for when the card is reinstalled.

## To Reinstall the P40

1. Power down `pve-tomahawk`.
2. Seat the P40 in an appropriate PCIe x16 slot. Verify power connectors.
3. Boot. Confirm detection: `lspci | grep 10de`
4. Note the new PCI address (may differ from `0000:01:00.0` depending on slot).
5. Verify IOMMU grouping: `./view_iommu_groups.sh | grep -A5 10de`
6. Re-bind to VFIO: ensure `vfio-pci` claims `10de:1b38` at boot
   (see `bind-gpu-vfio.sh` and `gpu-vfio.service`).
7. Update `vm-configs/inference1.conf` with the new PCI address if it changed.
8. On the Proxmox host, update VM 103:
   ```
   qm set 103 --hostpci0 <new-addr>,pcie=1,x-vga=1
   qm set 103 --vga none
   qm set 103 --serial0 socket
   ```
9. Commit updated `vm-configs/inference1.conf` to this repo.

## Live Config vs Repo Baseline Differences (as of removal)

The live `qm config 103` currently differs from the repo baseline:

| Setting | Repo baseline | Live config |
|---------|--------------|-------------|
| `hostpci0` | `0000:01:00,pcie=1,x-vga=1` | *(absent — P40 removed)* |
| `vga` | `none` | *(absent — using default virtual VGA)* |
| `serial0` | `socket` | *(absent)* |

The `vga` and `serial0` omissions are acceptable while the P40 is absent (the VM
uses a software VGA for display). Restore them together with `hostpci0` on reinsertion.
