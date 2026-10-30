# OpenTofu Proxmox VM Management

This directory contains OpenTofu declarations for managing Proxmox VE virtual machines.

---

## 1. Prerequisites

OpenTofu is installed across the fleet:
- **`homeserver`**: Pre-installed in system profile via the `declarative-runtime` NixOS aspect (`tofu`).
- **`phoenix` (workstation)**: Available instantly via Nix:
  ```bash
  nix shell nixpkgs#opentofu
  ```

---

## 2. Authentication

The `bpg/proxmox` provider connects to the Proxmox VE API (default: `https://10.10.11.53:8006/`).

### Recommended: Proxmox API Token

Generate an API token on `pve-rog` (or the cluster):
```bash
# 1. Create automation user and role with VM permissions
pveum user add tofu@pve -comment "OpenTofu Automation"
pveum role add TerraformRole -privs "VM.Allocate VM.Config.Disk VM.Config.CPU VM.Config.Memory VM.Config.Network VM.Config.HWType VM.Audit VM.PowerMgmt"
pveum acl modify / -user tofu@pve -role TerraformRole

# 2. Generate token (uncheck privilege separation)
pveum user token add tofu@pve default --privsep 0
```

Export the token in your shell:
```bash
export PROXMOX_VE_API_TOKEN="tofu@pve!default=<uuid-token-secret>"
```

Alternatively, use Proxmox username and password credentials:
```bash
export PROXMOX_VE_USERNAME="root@pam"
export PROXMOX_VE_PASSWORD="<password>"
```

---

## 3. Usage Workflow

From this directory (`tofu/`):

```bash
# Initialize provider and lock file
tofu init

# Check planned changes
tofu plan

# Apply changes
tofu apply
```

---

## 4. Adopting Existing VMs into State

If the VM already exists on Proxmox (such as `synology-dsm` with ID `210` on `pve-rog`):

```bash
tofu import proxmox_virtual_environment_vm.synology_dsm pve-rog/210
```

After importing, run `tofu plan` to verify that state matches the HCL definition without unexpected drift.
