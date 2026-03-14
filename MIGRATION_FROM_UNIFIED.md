# Migration From `unified-nix-configuration`

This repo is the better home for Proxmox host operations that are not part of a NixOS system configuration.

## Move Here

These items in `unified-nix-configuration` are Proxmox host administration concerns and fit this repo better:

- `ansible/`
  - `inventory/proxmox.ini`
  - `group_vars/proxmox.yml`
  - `playbooks/setup-proxmox-root.yml`
  - `playbooks/configure-proxmox-apt-proxy.yml`
  - `README.md`
  - `Makefile`
- `docs/proxmox-root-setup.md`
- `docs/proxmox-apt-cache.md`
- `scripts/update-proxmox-root.sh`

## Keep In `unified-nix-configuration`

These are still part of Nix-managed infrastructure or are consumed by non-Proxmox systems:

- `hosts/nixos/gateway/dns-zone.nix`
  - This is authoritative DNS data for the NixOS gateway.
- `scripts/gateway/dns-mappings.txt`
  - Same reason: gateway DNS management belongs with the gateway config.
- `hosts/nixos-lxc/`
  - These are NixOS guest definitions, not generic Proxmox host config.
- `modules/` used by NixOS or Home Manager across multiple machines
- `users/root/hosts/proxmox/`
  - This is Nix-managed Home Manager configuration and should stay with the Nix source of truth.
- `outputs/proxmox-root.nix`
  - Same reason: it is part of the Nix flake outputs.
- `secrets-agenix/proxmox-api-token.age`
  - Used by workstation-side integrations talking to the Proxmox API.
- Shared SSH config and host key material
  - These are broader homelab concerns, not Proxmox-host-only concerns.

## Boundary

Use this split going forward:

- `proxmox-host-configuration`
  - Debian/Proxmox host setup
  - apt sources
  - apt proxy rollout
  - shell tooling
  - host-local scripts and operational docs
- `unified-nix-configuration`
  - NixOS systems
  - NixOS LXC guests
  - gateway DNS and routing
  - shared secrets consumed by Nix-managed machines
  - workstation integrations

## Recommended Order

1. Move the `ansible/` directory first.
2. Move `docs/proxmox-root-setup.md` and `docs/proxmox-apt-cache.md`.
3. Delete or replace the old copies in `unified-nix-configuration` with short pointers.

## Notes

- Do not move the `apt-cache` DNS record out of `unified-nix-configuration`; the gateway owns DNS.
- Do not move NixOS LXC definitions just because they run under Proxmox. Their source of truth is still NixOS.
- Do not recreate a second Home Manager source of truth in this repo.
- `pve-gateway` should resolve to `10.10.11.52`; keep Proxmox inventories and gateway DNS data aligned with that address.
