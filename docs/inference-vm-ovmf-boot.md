# Inference VM OVMF Boot Runbook

This runbook records the OVMF boot failure we hit on `pve-tomahawk` with VM `103`
(`inference1`) and the configuration that worked reliably afterward.

## Summary

Working reference:

- VM `5573`
- `bios: ovmf`
- `machine: q35`
- no persistent `efidisk0`

Broken reference before remediation:

- VM `103`
- `bios: ovmf`
- `machine: q35`
- persistent `efidisk0`
- `pre-enrolled-keys=1`

Observed symptom:

- OVMF reported `no bootable option`
- SeaBIOS could still boot the live ISO

## Findings

There were three distinct problems on VM `103`:

1. `efidisk0` had `pre-enrolled-keys=1`, which enabled Secure Boot behavior.
   The NixOS installer ISO and installed Limine EFI binary were not accepted.
2. The persistent EFI vars disk carried stale NVRAM state.
3. The installed ESP had Limine under `EFI/limine/BOOTX64.EFI`, but OVMF disk
   boot was more reliable once the standard fallback path
   `EFI/BOOT/BOOTX64.EFI` was present.

The fix that worked was:

1. remove `efidisk0` from the VM
2. keep `bios: ovmf`
3. keep `machine: q35`
4. boot the installer ISO first and the system disk second
5. ensure the guest ESP contains `EFI/BOOT/BOOTX64.EFI`

## Known-Good Proxmox Settings

For `inference1`, `inference2`, and `inference3`:

- `bios: ovmf`
- `machine: q35`
- no `efidisk0`
- no Secure Boot
- no pre-enrolled keys
- `boot: order=ide0;scsi0` during install
- one installer ISO only, attached as `ide0`
- primary disk on `scsi0`
- `scsihw: virtio-scsi-single`

For passthrough GPU VMs such as `inference1`:

- pass the whole PCI slot, not just function `.0`
- use `hostpci0: 0000:01:00,pcie=1,x-vga=1` for the Tesla P40 so it is the primary GPU
- set `vga: none` to avoid competing emulated display devices

After installation is complete, switch boot order to:

- `boot: order=scsi0`

## Recovery Procedure

If an inference VM shows `no bootable option` under OVMF:

1. Inspect the VM config with `qm config <vmid>`.
2. If `efidisk0` exists, snapshot it first if you care about rollback.
3. Remove the persistent EFI vars disk from the VM config:

```bash
qm set <vmid> --delete efidisk0
```

4. Ensure the installer ISO is first for install-time boot:

```bash
qm set <vmid> --boot order=ide0\;scsi0
```

5. After the guest installs, make sure the fallback EFI path exists:

```bash
mkdir -p /boot/EFI/BOOT
cp -f /boot/EFI/limine/BOOTX64.EFI /boot/EFI/BOOT/BOOTX64.EFI
```

6. Once the guest boots successfully from disk, switch the VM back to:

```bash
qm set <vmid> --boot order=scsi0
```

## Repository Baselines

See:

- `vm-configs/inference1.conf`
- `vm-configs/inference2.conf`
- `vm-configs/inference3.conf`

Those files are intended as checked-in baselines for future Proxmox-side VM
creation so the firmware/boot mistakes above do not get reintroduced.
