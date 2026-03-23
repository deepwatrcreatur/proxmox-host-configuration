# Proxmox Agenix Recipient Onboarding

Use this runbook when a new Proxmox host should become a recipient for agenix-managed secrets in `unified-nix-configuration`.

This is a trusted operator workflow. Run it from a machine that already has the private operator key needed to decrypt and re-encrypt the existing secrets.

## Purpose

Add the new host to the agenix recipient graph without turning Semaphore into a high-trust key custodian.

In this repository model:

- SSH host keys are for SSH trust.
- Optional root user keys are for outbound SSH as `root`.
- Stable agenix machine identities are for secret decryption on the host.

Prefer the stable agenix machine identity for secrets.

## Inputs You Need

From the new host:

- the stable agenix machine identity public key
- optionally the SSH host Ed25519 public key
- optionally a root Ed25519 public key if you created one

From your operator environment:

- a clean checkout of `unified-nix-configuration`
- access to an operator key that can already decrypt the repo's agenix secrets
- `agenix` available locally

## 1. Add Public Keys to the Repo

In `unified-nix-configuration`, add the new public keys using the existing naming conventions.

Typical paths:

- `ssh-keys/agenix-machine-identities/<hostname>.pub`
- `ssh-keys/pve-<hostname>-host-ed25519.pub`
- `ssh-keys/root@pve-<hostname>-ed25519.pub`

The stable machine identity is the important one for agenix.

## 2. Update `secrets.nix`

Add or update the host entry in [`secrets.nix`](../../unified-nix-configuration/secrets.nix).

What usually matters:

- if `ssh-keys/agenix-machine-identities/<hostname>.pub` exists, `machineRecipients "<hostname>"` will pick it up automatically
- ensure the new hostname is included in any host list that should receive shared secrets, such as cache credentials

For Proxmox nodes that should get the shared cache credentials, confirm the host is present in the relevant host lists.

## 3. Re-encrypt the Affected Secrets

After updating recipients, re-encrypt the affected files.

For files that should now include the new host, open and save them with agenix:

```bash
cd /path/to/unified-nix-configuration
nix run github:ryantm/agenix -- -e secrets-agenix/attic-client-token.age
nix run github:ryantm/agenix -- -e secrets-agenix/nix-ci-netrc.age
```

If the host should receive additional service-scoped secrets, re-encrypt those too.

The general agenix workflow is documented in:

- [docs/agenix-workflow.md](../../unified-nix-configuration/docs/agenix-workflow.md)

## 4. Commit the Recipient Change

In `unified-nix-configuration`:

```bash
git add secrets.nix ssh-keys/ secrets-agenix/
git commit --no-gpg-sign -m "feat(secrets): add <hostname> agenix recipients"
git push origin <branch>
```

Keep this separate from routine maintenance commits when possible.

## 5. Redeploy or Re-run Bootstrap as Needed

If the host already has the relevant config applied, redeploy the host configuration so it can use the newly rekeyed secret set.

For a Proxmox root Home Manager target, that may simply be:

```bash
ssh root@<proxmox-host>
cd /root/flakes/unified-nix-configuration
home-manager switch --flake .#proxmox-root
```

If the host is still at initial bootstrap stage, rerunning the Ansible bootstrap is also fine.

## 6. When Semaphore Is Appropriate

Semaphore is fine for:

- running the bootstrap playbook
- providing `nix_ci_netrc`
- providing transient SSH connectivity to the new host

Semaphore is a separate trust decision for:

- storing the stable agenix private key
- editing `unified-nix-configuration`
- re-encrypting secrets and pushing commits

Unless you explicitly want that model, keep recipient onboarding on a trusted operator machine.

## Related Documentation

- [Proxmox Post-Bootstrap Onboarding](./proxmox-post-bootstrap-onboarding.md)
- [Proxmox Root Setup Guide](./proxmox-root-setup.md)
- [Adding a New Secret with Agenix](../../unified-nix-configuration/docs/agenix-workflow.md)
