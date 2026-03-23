# Proxmox Post-Bootstrap Onboarding

Use this runbook after `setup-proxmox-root.yml` has completed successfully and the host is reachable with the `proxmox-root` Home Manager environment.

This is operator work, not routine maintenance. Run it from a trusted machine where you already have access to your SSH and agenix operator keys.

## Goals

- verify which SSH identities the new host already has
- record the host SSH key if you want it tracked in the repo
- decide whether `root` needs its own persistent SSH client keypair
- prepare inputs for agenix recipient onboarding

## 1. Inspect Existing SSH Material on the New Host

SSH to the new Proxmox node as `root` and inspect the current keys:

```bash
ssh root@<proxmox-host>
ls -l /etc/ssh/ssh_host_* /root/.ssh 2>/dev/null
```

What to expect:

- Proxmox/Debian should already have SSH host keys under `/etc/ssh/`.
- Those are the server's host identities.
- `root` may or may not already have a personal client keypair under `/root/.ssh/id_*`.

The host key and the root user key are different things.

## 2. Prefer the Ed25519 Host Key

If the host has multiple SSH host keys, prefer the Ed25519 host key for repo tracking.

On the Proxmox host:

```bash
ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
cat /etc/ssh/ssh_host_ed25519_key.pub
```

If the Ed25519 host key does not exist, stop and investigate before you standardize on another key type.

## 3. Decide Whether Root Needs a Persistent User Keypair

Only do this if you actually want `root` on the Proxmox host to initiate outbound SSH as its own long-lived identity.

Examples where it may be useful:

- pulling private repos directly as `root`
- acting as a remote build client with a host-owned key
- authenticating to other infrastructure from that Proxmox host

If you do not have a real use for it, skip this and rely on operator-managed access instead.

To create one on the host:

```bash
mkdir -p /root/.ssh
chmod 700 /root/.ssh
ssh-keygen -t ed25519 -f /root/.ssh/id_ed25519 -C root@<proxmox-host>
chmod 600 /root/.ssh/id_ed25519
chmod 644 /root/.ssh/id_ed25519.pub
```

Then inspect the public half:

```bash
cat /root/.ssh/id_ed25519.pub
```

## 4. Capture the Public Keys You Care About

Typical repo-tracked public keys are:

- SSH host key
- optional `root` user key
- agenix machine identity public key

For the first two, capture them now if you intend to track them in `unified-nix-configuration`.

Suggested repository paths follow the current convention:

- `ssh-keys/pve-<name>-host-ed25519.pub`
- `ssh-keys/root@pve-<name>-ed25519.pub`

## 5. Check the Stable Agenix Machine Identity

This repo prefers a dedicated machine identity for agenix, separate from SSH host keys.

The public key is stored in:

- `ssh-keys/agenix-machine-identities/<hostname>.pub`

The private key lives only on the host at:

- `/var/lib/agenix/machine-identity`

Check whether the host already has that identity:

```bash
ls -l /var/lib/agenix/machine-identity*
```

If it is missing, create it on the host:

```bash
install -d -m 700 /var/lib/agenix
ssh-keygen -t ed25519 -f /var/lib/agenix/machine-identity -N '' -C 'agenix-machine-identity <hostname>'
chmod 600 /var/lib/agenix/machine-identity
chmod 644 /var/lib/agenix/machine-identity.pub
cat /var/lib/agenix/machine-identity.pub
```

Do not reuse the SSH host key as the stable agenix machine identity.

## 6. Store Stable Private Material in Dashlane if Needed

If you keep stable private identities in Dashlane, store the private half there now for the keys you deliberately want to preserve.

That typically means:

- optional `/root/.ssh/id_ed25519`
- `/var/lib/agenix/machine-identity`

It does not usually mean the SSH host private key.

## 7. Continue to Recipient Onboarding

Once you have the public keys you want to keep, continue with:

- [Proxmox Agenix Recipient Onboarding](./proxmox-agenix-recipient-onboarding.md)
