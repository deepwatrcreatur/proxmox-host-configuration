# Proxmox Host Configuration

This repo holds Proxmox host operational material that is not the Nix source of truth.

## Scope

- Proxmox host administration docs
- Ansible playbooks for Debian/Proxmox hosts
- apt proxy rollout
- host-local operational scripts
- ad hoc Proxmox artifacts that are not managed by Nix

## Not Here

The Nix source of truth for Proxmox root Home Manager and the rest of the homelab still lives in `unified-nix-configuration`.

## Layout

- `ansible/` for Proxmox host rollout and maintenance
- `docs/` for Proxmox operational runbooks
- `scripts/` for host-side helper scripts
- `MIGRATION_FROM_UNIFIED.md` for the current repo boundary
