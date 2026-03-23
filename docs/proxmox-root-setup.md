# Proxmox Root Setup Guide

This guide covers bootstrapping the `proxmox-root` Home Manager configuration on a freshly installed Proxmox VE host.

`unified-nix-configuration` remains the Nix source of truth for the `proxmox-root` output. This repo owns the operational bootstrap material that gets a Proxmox host to the point where that Home Manager configuration can activate cleanly.

## What This Bootstrap Is For

The supported bootstrap path is the Ansible playbook in [`ansible/playbooks/setup-proxmox-root.yml`](../ansible/playbooks/setup-proxmox-root.yml).

It is designed for the repeatable, low-ceremony part of Proxmox host setup:

1. Install or upgrade Determinate Nix.
2. Write `/etc/nix/nix.custom.conf` with the intended substituter order.
3. Seed `/root/.config/nix/nix-ci-netrc` with NixCI credentials.
4. Activate `.#proxmox-root` from `unified-nix-configuration`.

It is not the place to manage long-lived operator key material or to rekey agenix recipients.

## What This Bootstrap Does Not Do

The playbook intentionally does not try to do these tasks:

- collect the new host's SSH host key for you
- create or rotate a persistent root SSH client keypair
- update `secrets.nix` in `unified-nix-configuration`
- re-encrypt agenix secrets for the new host

Those are operator steps. They happen infrequently and require higher-trust credentials than the bootstrap itself.

## Cache Order

Proxmox hosts should use binary caches in this order:

1. `http://attic-cache:5001/cache-local`
2. `https://cache.nix-ci.com`
3. `https://cache.nixos.org`

That gives you the fastest path through the local Attic cache first, then the paid NixCI cache, with the public NixOS cache as the final fallback.

## Required Secret

Before running the playbook, set the Ansible variable `nix_ci_netrc` to a valid netrc stanza for `cache.nix-ci.com`.

Expected format:

```netrc
machine cache.nix-ci.com
login <login>
password <token>
```

The playbook copies that value to:

- `/root/.config/nix/nix-ci-netrc`

That file is then consumed by the `proxmox-root` Home Manager configuration in `unified-nix-configuration`, which appends it into Determinate Nix's managed netrc.

## Recommended Bootstrap Flow

From the control machine:

```bash
cd /home/deepwatrcreatur/flakes/proxmox-host-configuration/ansible
ansible-playbook -i inventory/proxmox.ini playbooks/setup-proxmox-root.yml --limit <proxmox-host>
```

The playbook expects:

- SSH access as `root`
- `config_repo_url` and related repo variables set correctly
- `nix_ci_netrc` provided through Ansible vars, inventory, or vault-managed vars

A Semaphore job can handle this bootstrap path if it has the same SSH and secret inputs.

## After Bootstrap

Once the first Home Manager activation succeeds, decide whether the host also needs onboarding into your longer-lived secret and SSH identity flows.

That follow-up may include:

- recording the host's SSH host key
- deciding whether to create a root user keypair on the host
- adding the host as an agenix recipient in `unified-nix-configuration`
- rekeying secrets from a trusted operator environment

Keep those tasks separate from the bootstrap unless you deliberately want Semaphore to hold the high-trust private key material needed for rekeying.

Detailed follow-up runbooks:

- [Proxmox Post-Bootstrap Onboarding](./proxmox-post-bootstrap-onboarding.md)
- [Proxmox Agenix Recipient Onboarding](./proxmox-agenix-recipient-onboarding.md)

## Manual Recovery

If the Home Manager step fails after bootstrap, SSH to the Proxmox host and retry manually:

```bash
cd /root/flakes/unified-nix-configuration
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
nix run nixpkgs#home-manager -- switch --flake .#proxmox-root
```

Useful checks:

```bash
cat /etc/nix/nix.custom.conf
cat /root/.config/nix/nix-ci-netrc
cat /nix/var/determinate/netrc
```

You should see:

- the Attic cache first in `substituters`
- `https://cache.nix-ci.com` present as the second cache
- a valid NixCI stanza in the netrc files

## Related Documentation

- [Ansible Setup for Proxmox Hosts](../ansible/README.md)
- [Proxmox Post-Bootstrap Onboarding](./proxmox-post-bootstrap-onboarding.md)
- [Proxmox Agenix Recipient Onboarding](./proxmox-agenix-recipient-onboarding.md)
- [Proxmox Apt Cache](./proxmox-apt-cache.md)
