# Proxmox Host Configuration

This repo holds Proxmox host operational material that is not the Nix source of truth.

## Scope

- Proxmox host administration docs
- Ansible playbooks for Debian/Proxmox hosts
- Bootstrap runbooks for Determinate Nix and `proxmox-root`
- operator runbooks for new-host onboarding and secret recipient changes
- apt proxy rollout
- host-local operational scripts
- ad hoc Proxmox artifacts that are not managed by Nix

## Repo Boundary

The Nix source of truth for Proxmox root Home Manager and the rest of the homelab still lives in `unified-nix-configuration`.

This repo is responsible for getting a fresh Proxmox install to the point where that Home Manager configuration can activate reliably, and for documenting the operator follow-up steps that happen around that bootstrap.

## Two Kinds of Work

### Regular, automation-friendly work

This is the work that fits Semaphore or Ansible well:

- install or upgrade Determinate Nix
- configure binary caches in this order:
  1. `http://attic-cache:5001/cache-local`
  2. `https://cache.nix-ci.com`
  3. `https://cache.nixos.org`
- seed the NixCI netrc stanza used by `proxmox-root`
- run the first `home-manager switch`
- rerun the bootstrap or maintenance playbooks later

### Infrequent, operator-only work

This is the work that should stay in a high-trust operator flow unless you intentionally automate it:

- inspect or record the new host's SSH host key
- decide whether to create a persistent root user keypair on the host
- add new SSH or agenix recipient keys to `unified-nix-configuration`
- rekey agenix secrets for the new host
- commit and push onboarding-related repo changes

## Layout

- `ansible/` for Proxmox host rollout and maintenance
- `docs/` for Proxmox operational runbooks
- `scripts/` for host-side helper scripts
- `MIGRATION_FROM_UNIFIED.md` for the current repo boundary

## Start Here

- `ansible/playbooks/setup-proxmox-root.yml` for first-host bootstrap
- `ansible/README.md` for playbook variables and secret expectations
- `docs/proxmox-root-setup.md` for the bootstrap runbook
- `docs/proxmox-post-bootstrap-onboarding.md` for SSH identity follow-up
- `docs/proxmox-agenix-recipient-onboarding.md` for agenix recipient onboarding
