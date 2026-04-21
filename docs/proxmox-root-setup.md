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
2. `http://10.10.11.39:5001/cache-local`
3. `https://cache.nix-ci.com`
4. `https://cache.nixos.org`

That gives you the fastest path through the local Attic cache first, an IP fallback for fresh hosts that cannot yet resolve `attic-cache`, then the paid NixCI cache, with the public NixOS cache as the final fallback.

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

## GitHub Transport Policy

Use HTTPS for the bootstrap checkout of `unified-nix-configuration`.

The inventory should keep:

```ini
config_repo_url=https://github.com/deepwatrcreatur/unified-nix-configuration.git
```

The playbook also runs repo pulls with `GIT_CONFIG_GLOBAL=/dev/null`. This is intentional: some configured roots rewrite `https://github.com/` to `ssh://git@github.com/` to avoid unauthenticated GitHub API limits or to access private repositories, but that rewrite is too fragile for first-bootstrap automation. It makes a public repo update depend on root's GitHub client key, GitHub's host key, and working DNS for `github.com`.

After Home Manager and secrets are active, a settled host may still use SSH or token-backed Nix/GitHub access where appropriate. Bootstrap should remain deterministic and should not require a root GitHub SSH identity.

## After Bootstrap

Once the first Home Manager activation succeeds, decide whether the host also needs onboarding into your longer-lived secret and SSH identity flows.

That follow-up may include:

- recording the host's SSH host key
- adding the host to `lib/hosts.nix` in `unified-nix-configuration` so generated SSH config exposes the `pve-*` alias
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
- `http://10.10.11.39:5001/cache-local` present as the DNS-independent Attic fallback
- `https://cache.nix-ci.com` present before the public NixOS cache
- a valid NixCI stanza in the netrc files

### DNS During Bootstrap

If Nix or Git repeatedly fails with `Could not resolve host` or `Resolving timed out`, verify the host's resolver before changing Git transport:

```bash
cat /etc/resolv.conf
dig +time=2 +tries=1 cache.nixos.org A
dig +time=2 +tries=1 @1.1.1.1 cache.nixos.org A
getent hosts attic-cache
```

On hosts where Tailscale has overwritten `/etc/resolv.conf` but MagicDNS is not answering, disable Tailscale DNS for that host and use normal resolvers:

```bash
tailscale set --accept-dns=false
printf "search deepwatercreature.com\nnameserver 1.1.1.1\nnameserver 9.9.9.9\n" > /etc/resolv.conf
grep -q " attic-cache" /etc/hosts || printf "10.10.11.39 attic-cache attic-cache.deepwatercreature.com\n" >> /etc/hosts
```

For reboot persistence on Proxmox ifupdown hosts, add the DNS settings under the `vmbr0` static interface:

```text
    dns-nameservers 1.1.1.1 9.9.9.9
    dns-search deepwatercreature.com
```

## Related Documentation

- [Ansible Setup for Proxmox Hosts](../ansible/README.md)
- [Proxmox Post-Bootstrap Onboarding](./proxmox-post-bootstrap-onboarding.md)
- [Proxmox Agenix Recipient Onboarding](./proxmox-agenix-recipient-onboarding.md)
- [Proxmox Apt Cache](./proxmox-apt-cache.md)
- [Intel 82599 / X520 Unsupported SFP Recovery](./intel-82599-unsupported-sfp.md)
