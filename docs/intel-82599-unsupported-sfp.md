# Intel 82599 / X520 Unsupported SFP Recovery

Use this runbook when a Proxmox host has an Intel 82599ES or X520-class 10GbE adapter and the port does not appear in `ip a` even though the card is visible in `lspci`.

This showed up on `pve-elitedesk` with:

- PCI ID `8086:10fb`
- driver `ixgbe`
- kernel log:

```text
ixgbe 0000:01:00.0: failed to load because an unsupported SFP+ or QSFP module type was detected.
ixgbe 0000:01:00.0: Reload the driver after installing a supported module.
ixgbe 0000:01:00.0: probe with driver ixgbe failed with error -95
```

## Symptoms

- `lspci -nnk` shows the Intel 10GbE adapter
- `lsmod` shows `ixgbe`
- no corresponding 10GbE interface appears in `ip a`
- `journalctl -k` or `dmesg` shows the unsupported SFP/QSFP probe failure above

## Persistent Driver Override

Install a persistent `modprobe.d` override:

```bash
cat >/etc/modprobe.d/ixgbe-unsupported-sfp.conf <<'EOF'
options ixgbe allow_unsupported_sfp=1
EOF

update-initramfs -u
```

To apply it immediately without rebooting:

```bash
modprobe -rv ixgbe
modprobe -v ixgbe
```

Verify the option is active:

```bash
cat /sys/module/ixgbe/parameters/allow_unsupported_sfp
```

Expected value:

```text
Y
```

## Important Limitation

On `pve-elitedesk`, the override was accepted by the module and persisted, but the current optic/cable was still rejected during probe.

That means `allow_unsupported_sfp=1` is worth setting first, but it is not guaranteed to make every third-party transceiver work.

## EEPROM Verification

The 82599 stores the "allow any SFP" capability in EEPROM word `0x2c`, bit `0`.

On `pve-elitedesk`, I verified that word directly from BAR0 with the controller's EEPROM read register and found:

```text
word 0x002c = 0xfffd
```

That value already has bit `0` set, so the common X520/82599 EEPROM unlock is already present on this card.

I also backed up the separate SPI flash attached to the NIC with:

```bash
flashrom -p nicintel_spi:pci=01:00.0 -r /root/ixgbe-82599-backup-<timestamp>.bin
```

Important: that SPI flash is the boot ROM image, not the configuration EEPROM word the Linux `ixgbe` driver reads for `IXGBE_DEVICE_CAPS`.

## What This Means

If both of these are true:

- `allow_unsupported_sfp=1` is active
- EEPROM word `0x2c` already has bit `0` set

and the driver still logs:

```text
failed to load because an unsupported SFP+ or QSFP module type was detected
```

then the failure is not the usual Intel vendor lock alone.

The remaining likely cases are:

1. The module advertises a transceiver type the driver rejects before the "allow any SFP" path helps.
2. The module's EEPROM/compliance fields are malformed or too old for the 82599 driver's parser.
3. The optic/DAC is simply not usable with this card even after the usual unlock.

## If the Port Still Does Not Enumerate

Use one of these paths:

1. Replace the optic or DAC with an Intel-compatible supported module.
2. Try a known-good passive or active limiting DAC that already works with 82599/X520 hardware.
3. Use a temporary patched `ixgbe` build only long enough to identify the module and confirm whether the failure is in the module compliance data path.

Do not blindly write the SPI flash backup image or flip bytes in the raw flash dump. That dump is not the same storage layout as the EEPROM words the driver reads.

## Patched Driver Path

On `pve-elitedesk`, the working fix was a patched Intel `ixgbe` module.

The stock Proxmox module still aborted probe with:

```text
failed to load because an unsupported SFP+ or QSFP module type was detected
```

even though:

- EEPROM word `0x2c` already allowed any SFP
- `allow_unsupported_sfp=1` was active

### What was done

1. Enable the public Proxmox repositories so matching headers can be installed.
2. Install:

```bash
apt-get install -y proxmox-headers-$(uname -r) build-essential git
```

3. Clone Intel's driver source:

```bash
git clone --depth 1 https://github.com/intel/ethernet-linux-ixgbe /root/src/ixgbe-patched
```

4. Patch both `src/ixgbe_82599.c` and `src/ixgbe_main.c` so `allow_unsupported_sfp=1` bypasses the 82599-specific `IXGBE_ERR_SFP_NOT_SUPPORTED` exits during both probe and later SFP polling.
5. Build:

```bash
cd /root/src/ixgbe-patched/src
make -j"$(nproc)" KSRC=/lib/modules/$(uname -r)/build
```

6. Install the built module into the override path:

```bash
install -d /lib/modules/$(uname -r)/updates/drivers/net/ethernet/intel/ixgbe
install -m 0644 /root/src/ixgbe-patched/src/ixgbe.ko \
  /lib/modules/$(uname -r)/updates/drivers/net/ethernet/intel/ixgbe/ixgbe.ko
depmod -a
update-initramfs -u
```

### Exact Host State To Preserve

On `pve-elitedesk`, the following host-local state now exists and is needed to reproduce this node:

- `/etc/modprobe.d/ixgbe-unsupported-sfp.conf`
- `/etc/apt/sources.list.d/pve-no-subscription.sources`
- `/etc/apt/sources.list.d/ceph-no-subscription.sources`
- `/etc/apt/sources.list.d/pve-enterprise.sources.disabled`
- `/etc/apt/sources.list.d/ceph.sources.disabled`
- `/root/src/ixgbe-patched`
- `/lib/modules/6.14.8-2-pve/updates/drivers/net/ethernet/intel/ixgbe/ixgbe.ko`
- `/root/ixgbe-82599-backup-20260420-213728.bin`
- `/root/ixgbe-82599-backup-verbose.bin`

The Intel tree used on the host was:

```text
https://github.com/intel/ethernet-linux-ixgbe
commit f2f58c487e60b6a5a2a520e366018bba98793875
```

### Exact Source Edits

The live host patch touched these files:

- `src/ixgbe_82599.c`
- `src/ixgbe_main.c`
- `src/ixgbe_phy.c`

Behavioral summary:

- `ixgbe_82599.c`
  - keep `allow_unsupported_sfp=1` from aborting in `ixgbe_init_phy_ops_82599`
  - keep `allow_unsupported_sfp=1` from aborting in `ixgbe_reset_hw_82599`
  - return success from `ixgbe_identify_phy_82599` when the PHY is marked unsupported but the override is enabled
- `ixgbe_main.c`
  - keep `ixgbe_sfp_detection_subtask` from bailing out on `identify_sfp`
  - keep `ixgbe_sfp_detection_subtask` from bailing out on `setup_sfp`
  - prevent the service path from unregistering the netdev when `allow_unsupported_sfp=1`
- `ixgbe_phy.c`
  - map malformed third-party 10G SR optics with zeroed compliance-code bytes to the normal 82599 SR/LR SFP type
  - this changed the detected SFP type from `65535` / unknown to `5` / `ixgbe_sfp_type_srlr_core0`

The live diff on the host is available with:

```bash
cd /root/src/ixgbe-patched
git diff -- src/ixgbe_82599.c src/ixgbe_main.c src/ixgbe_phy.c
```

### Apt Repository Change

The host originally had the paid Proxmox enterprise repos enabled and they were returning `401 Unauthorized`.

For this node, those files were disabled:

- `/etc/apt/sources.list.d/pve-enterprise.sources.disabled`
- `/etc/apt/sources.list.d/ceph.sources.disabled`

and replaced with:

```text
/etc/apt/sources.list.d/pve-no-subscription.sources
/etc/apt/sources.list.d/ceph-no-subscription.sources
```

This was required so `proxmox-headers-$(uname -r)` could be installed.

### Observed Result

After loading the patched module, the host created the interface:

```text
enp1s0
```

Kernel log excerpt:

```text
ixgbe ... allow_unsupported_sfp Enabled
ixgbe ... Intel(R) 10 Gigabit Network Connection
enp1s0: renamed from eth0
enp1s0: detected SFP+: 5
```

That confirms the problem on this host was the in-kernel driver probe path, not missing hardware, not stale module state, and not the usual EEPROM lock bit.

### Optic Compatibility Result

The patched driver made the 10GbE port enumerate, but it still showed unstable behavior in later SFP service checks until the second `ixgbe_main.c` patch was added.

The original optic was a Cisco/Finisar `FTLX8570D3BCL-C2`.

It was readable and reported healthy optical levels, but its transceiver compliance code bytes were all zero:

```text
Transceiver codes: 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00 0x00
```

With that optic, even after patching the driver enough to enumerate and classify the NIC, the port stayed at `NO-CARRIER`.

Replacing it with a Dely-Tech `SFP-10G-SR` module fixed link carrier. The replacement advertises:

```text
Transceiver type: 10G Ethernet: 10G Base-SR
Speed: 10000Mb/s
Duplex: Full
Link detected: yes
```

Conclusion: the old optic was not necessarily electrically dead, but it was incompatible with this 82599/`ixgbe` path because its EEPROM did not advertise 10G SR compliance correctly.

### Management Cutover

The Proxmox management bridge was moved from onboard `eno1` to the 10GbE port.

Persistent interface naming is handled by:

```text
/etc/systemd/network/10-mgmt0.link
```

with:

```ini
[Match]
MACAddress=90:e2:ba:3a:1d:6a

[Link]
Name=mgmt0
```

The persistent Proxmox network config is:

```text
iface eno1 inet manual

iface mgmt0 inet manual

auto vmbr0
iface vmbr0 inet static
	address 10.10.11.44/16
	gateway 10.10.10.1
	bridge-ports mgmt0
	bridge-stp off
	bridge-fd 0
```

The live cutover was done before reboot while the interface was still named `enp1s0`:

```bash
ip link set enp1s0 up
ip link set eno1 nomaster
ip link set enp1s0 master vmbr0
ip link set vmbr0 up
```

After cutover:

```text
vmbr0 10.10.11.44/16
enp1s0 master vmbr0 state forwarding
default via 10.10.10.1 dev vmbr0
```

On the next reboot, `enp1s0` should come back as `mgmt0`, and `vmbr0` should attach to `mgmt0`.

Reproduction of the node should preserve:

- the patched module
- the Dely-Tech `SFP-10G-SR` or another module that correctly advertises `10G Base-SR`
- the `mgmt0` systemd link file
- the `vmbr0` bridge config using `bridge-ports mgmt0`

## Quick Checks

```bash
lspci -nnk | grep -A4 -i ethernet
journalctl -k --no-pager | grep -i ixgbe
ip -br a
```
