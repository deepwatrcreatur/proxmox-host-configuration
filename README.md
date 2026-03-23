# Proxmox Host Configuration

This repo holds Proxmox host operational material that is not the Nix source of truth.

## Scope

- Proxmox host administration docs
- Ansible playbooks for Debian/Proxmox hosts
- Bootstrap runbooks for Determinate Nix and `proxmox-root`
- apt proxy rollout
- host-local operational scripts
- ad hoc Proxmox artifacts that are not managed by Nix

## Repo Boundary

The Nix source of truth for Proxmox root Home Manager and the rest of the homelab still lives in `unified-nix-configuration`.

This repo is responsible for getting a fresh Proxmox install to the point where that Home Manager configuration can activate reliably.

Current bootstrap expectations:

- install or upgrade Determinate Nix
- configure binary caches in this order:
  1. `http://attic-cache:5001/cache-local`
  2. `https://cache.nix-ci.com`
  3. `https://cache.nixos.org`
- seed the NixCI netrc stanza used by `proxmox-root`
- run the first `home-manager switch`

## Layout

- `ansible/` for Proxmox host rollout and maintenance
- `docs/` for Proxmox operational runbooks
- `scripts/` for host-side helper scripts
- `MIGRATION_FROM_UNIFIED.md` for the current repo boundary

## Start Here

- `ansible/playbooks/setup-proxmox-root.yml` for first-host bootstrap
- `ansible/README.md` for playbook variables and secret expectations
- `docs/proxmox-root-setup.md` for the operational runbook
