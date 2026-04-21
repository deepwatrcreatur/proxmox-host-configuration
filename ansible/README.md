# Ansible Setup for Proxmox Hosts

This directory contains Ansible playbooks for bootstrapping freshly installed Proxmox VE hosts over SSH.

## Quick Start

```bash
# Install Ansible (if not already installed)
pip install ansible

# Run the playbook
ansible-playbook -i inventory/proxmox.ini playbooks/setup-proxmox-root.yml
```

## Directory Structure

```text
ansible/
├── inventory/
│   └── proxmox.ini
├── group_vars/
│   └── proxmox.yml
└── playbooks/
    └── setup-proxmox-root.yml
```

## What This Playbook Is For

`setup-proxmox-root.yml` is the repeatable bootstrap path for a fresh Proxmox host.

It is a good fit for:

- local operator runs from a trusted host
- Semaphore jobs that have SSH access and the required cache secret
- rerunning the same bootstrap later when you want to converge a host back to the expected state

It is not meant to own long-lived SSH identity capture or agenix rekeying.

## Configuration

### Inventory (`inventory/proxmox.ini`)

Add your Proxmox hosts:

```ini
[proxmox]
10.10.11.47 ansible_user=root
10.10.11.52 ansible_user=root
10.10.11.53 ansible_user=root
10.10.11.55 ansible_user=root
10.10.11.57 ansible_user=root
```

### Variables (`group_vars/proxmox.yml`)

Customize variables in `group_vars/proxmox.yml`:

| Variable | Default | Description |
|----------|----------|-------------|
| `cache_build_server_host` | `attic-cache` | Hostname of the local Attic cache |
| `cache_build_server_port` | `5001` | Port for the Attic cache |
| `nix_ci_cache_url` | `https://cache.nix-ci.com` | Paid fallback cache used after Attic |
| `nix_ci_netrc` | Required | Ready-made netrc stanza for `cache.nix-ci.com` |
| `config_repo_url` | Required | `unified-nix-configuration` Git repository URL |
| `config_repo_path` | `/root/flakes/unified-nix-configuration` | Local path for repo |
| `home_manager_output` | `proxmox-root` | Home Manager output name |

### GitHub Transport

Keep `config_repo_url` as HTTPS for this bootstrap flow:

```ini
config_repo_url=https://github.com/deepwatrcreatur/unified-nix-configuration.git
```

The playbook forces repo pulls to ignore root's global Git config with `GIT_CONFIG_GLOBAL=/dev/null`. This prevents a host-local rewrite such as `https://github.com/` to `ssh://git@github.com/` from turning a public bootstrap update into a dependency on root's GitHub SSH identity.

This does not forbid SSH for GitHub generally. Settled hosts can still use SSH or token-backed GitHub access for private repositories and rate-limit avoidance after Home Manager and secrets are active. The bootstrap path should stay HTTPS-first and deterministic.

## Bootstrap Behavior

The `setup-proxmox-root.yml` playbook performs:

1. Installs bootstrap packages.
2. Runs `apt dist-upgrade`.
3. Installs or upgrades Determinate Nix.
4. Writes `/etc/nix/nix.custom.conf` with substituters and trusted keys.
5. Seeds `/root/.config/nix/nix-ci-netrc` before the first Home Manager activation.
6. Clones or updates `unified-nix-configuration`.
7. Activates `.#proxmox-root`.
8. Verifies `nix` and `home-manager`.

The intended cache order is:

1. `http://attic-cache:5001/cache-local`
2. `http://10.10.11.39:5001/cache-local`
3. `https://cache.nix-ci.com`
4. `https://cache.nixos.org`

## What This Playbook Deliberately Leaves Out

This bootstrap does not attempt to:

- collect the new host's SSH host key
- create a persistent root SSH client keypair on the host
- update agenix recipients in `unified-nix-configuration`
- rekey secrets for the new host

Those steps are better handled as operator-run follow-up tasks because they require higher-trust credentials and happen infrequently.

## Supplying `nix_ci_netrc`

Provide a valid netrc stanza for NixCI through inventory, extra vars, or Ansible Vault.

Expected value:

```netrc
machine cache.nix-ci.com
login <login>
password <token>
```

Example with extra vars:

```bash
ansible-playbook -i inventory/proxmox.ini playbooks/setup-proxmox-root.yml \
  -e 'nix_ci_netrc=machine cache.nix-ci.com\nlogin <login>\npassword <token>'
```

If you already manage secrets with Ansible Vault, put `nix_ci_netrc` in a vaulted vars file instead of passing it on the command line.

## Usage Examples

### Run on a single host

```bash
ansible-playbook -i inventory/proxmox.ini playbooks/setup-proxmox-root.yml --limit 10.10.11.47
```

### Run on all Proxmox hosts

```bash
ansible-playbook -i inventory/proxmox.ini playbooks/setup-proxmox-root.yml
```

### Check mode

```bash
ansible-playbook -i inventory/proxmox.ini playbooks/setup-proxmox-root.yml --check
```

### Verbose output

```bash
ansible-playbook -i inventory/proxmox.ini playbooks/setup-proxmox-root.yml -v
```

## Troubleshooting

### First activation conflicts

Fresh Proxmox installs often have root dotfiles that block the first Home Manager activation. The playbook removes the common conflicting files before activation:

```text
/root/.profile
/root/.bashrc
/root/.ssh/config
```

If activation still fails, SSH into the host and re-run manually:

```bash
cd /root/flakes/unified-nix-configuration
. /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
nix run nixpkgs#home-manager -- switch --flake .#proxmox-root
```

### Cache authentication issues

Check the files that the bootstrap flow is expected to create:

```bash
cat /etc/nix/nix.custom.conf
cat /root/.config/nix/nix-ci-netrc
cat /nix/var/determinate/netrc
```

If `cache.nix-ci.com` is present in `nix.custom.conf` but missing from the netrc files, fix the `nix_ci_netrc` variable and rerun the playbook.

### Connection issues

```bash
ansible proxmox -i inventory/proxmox.ini -m ping
ansible proxmox -i inventory/proxmox.ini -m shell -a "hostname"
```

## Requirements

### Control machine

- Python 3.6+
- Ansible 2.9+
- SSH access to target hosts

### Target machines

- Debian/Ubuntu-based system (Proxmox VE)
- Root SSH access
- Internet access for Nix installation and package downloads
- Access to `attic-cache`
- Access to `cache.nix-ci.com`

## Related Documentation

- [Proxmox Root Setup Guide](../docs/proxmox-root-setup.md)
- [Determinate Nix](https://determinate.systems/)
- [Ansible Documentation](https://docs.ansible.com/)
