# Proxmox Apt Cache

This homelab uses a dedicated `apt-cacher-ng` LXC on `pve-tomahawk` for Proxmox and Debian-family hosts.

## Service Details

- Host node: `pve-tomahawk` (`10.10.11.55`)
- LXC VMID: `553142`
- LXC hostname: `apt-cache`
- Service address: `10.10.11.42`
- Service port: `3142`
- DNS name: `apt-cache.deepwatercreature.com`

The VMID follows the existing convention of `55` + service port `3142`.

## LXC Shape

- Template: `debian-12-standard_12.12-1_amd64.tar.zst`
- Unprivileged container
- 2 vCPU
- 2048 MiB RAM
- 512 MiB swap
- 20 GiB rootfs on `rpool-data`
- Static IP: `10.10.11.42/16`
- Gateway: `10.10.10.1`
- DNS: `10.10.10.1`

## Server Notes

`apt-cacher-ng` is installed in the container and listens on `0.0.0.0:3142`.

HTTP repositories are cached normally. HTTPS repositories are allowed to pass through the proxy, which keeps clients working even when the upstream source is HTTPS-only.

Useful checks from a Proxmox host:

```bash
curl http://apt-cache.deepwatercreature.com:3142/acng-report.html
apt-config dump | grep -i proxy
```

## Proxmox Client Configuration

Create `/usr/local/bin/apt-proxy-auto-detect` on each Proxmox host:

```bash
#!/usr/bin/env bash
set -euo pipefail

proxy_url="http://apt-cache.deepwatercreature.com:3142/"
report_url="http://apt-cache.deepwatercreature.com:3142/acng-report.html"
target_uri="${1:-}"

case "$target_uri" in
  *apt-cache.deepwatercreature.com*|*10.10.11.42*)
    echo DIRECT
    exit 0
    ;;
esac

if command -v curl >/dev/null 2>&1 && curl -fsS --max-time 2 "$report_url" >/dev/null 2>&1; then
  echo "$proxy_url"
else
  echo DIRECT
fi
```

Then create `/etc/apt/apt.conf.d/90apt-proxy`:

```conf
Acquire::http::Proxy "DIRECT";
Acquire::https::Proxy "DIRECT";
Acquire::http::Proxy-Auto-Detect "/usr/local/bin/apt-proxy-auto-detect";
Acquire::https::Proxy-Auto-Detect "/usr/local/bin/apt-proxy-auto-detect";
```

If DNS has not been deployed yet, use the IP directly:

```bash
#!/usr/bin/env bash
set -euo pipefail

proxy_url="http://10.10.11.42:3142/"
report_url="http://10.10.11.42:3142/acng-report.html"

if command -v curl >/dev/null 2>&1 && curl -fsS --max-time 2 "$report_url" >/dev/null 2>&1; then
  echo "$proxy_url"
else
  echo DIRECT
fi
```

Then validate it:

```bash
apt update
apt-config dump | grep -i proxy
curl http://apt-cache.deepwatercreature.com:3142/acng-report.html
```

## Maintenance

- Service status inside the container:

```bash
pct exec 553142 -- systemctl status apt-cacher-ng
```

- Access the report page:

```bash
curl http://apt-cache.deepwatercreature.com:3142/acng-report.html
```

- Tail logs:

```bash
pct exec 553142 -- journalctl -u apt-cacher-ng -f
```
