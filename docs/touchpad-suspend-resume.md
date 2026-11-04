# Surface Laptop 7 touchpad suspend/resume fix

## Problem

On the tested Surface Laptop 7, the touchpad stopped responding after
suspend. IPTSD device checks failed with GET_FEATURE 0x06 timeouts.

Restarting IPTSD or reloading the previous SPI-HID driver after the
failure did not restore operation. Rebooting restored the touchpad.

The previous bundled driver did not implement system-sleep PM callbacks.

## Experimental fix: surface-pm-test1

The updated driver:

- Blocks new requests and quiesces IRQ handling and deferred work.
- Removes the previous HID device and powers down the touchpad.
- Resets and powers up the device during resume.
- Defers HID reinitialization to the PM complete phase.
- Recreates the HID device so udev and IPTSD can reconnect automatically
  and restore heatmap mode.
- Tracks IRQ enable state when error handling disables the IRQ.
- Cancels deferred work before freeing buffers during driver removal.

## Hardware validation

Tested configuration:

- Microsoft Surface Laptop 7, 13.8-inch.
- Snapdragon X Plus X1P64100.
- Ubuntu 26.10 ARM64.
- Kernel 7.3.0-31-qcom-x1e.
- The project's custom QSPI/GPI drivers and Device Tree.

The module compiled successfully on ARM64.

Touchpad operation was confirmed after three suspend/resume cycles with
the temporarily loaded module, and after another cycle following a
reboot into a dedicated GRUB entry.

The tested installation loads the original Surface initrd followed by
an additional archive containing the updated module:

- /boot/initrd.img-surface-touchpad-test
- /boot/surface-touchpad-pm-test1.cpio

The previous boot configuration was retained for recovery.

## Building

From the repository root, with matching kernel headers installed:

```bash
make -C "/lib/modules/$(uname -r)/build" \
    M="$PWD/kernel/modules/spi-hid" -j2 modules
```

This command only builds the module.

A working installation also requires the matching controller drivers,
Device Tree, firmware and IPTSD configuration.

Updating this repository does not automatically update existing
initrd or ISO images.

## Limitations and remaining issues

This experimental fix has been validated on one hardware and software
configuration. Other devices and kernel versions have not been tested.

An inherited "Unbalanced pm_runtime_enable!" warning was observed
during live module replacement and remains to be addressed.

A PCIe L2-entry timeout was also logged during a tested transition.
This change does not address PCIe power management.

The Ubuntu and Debian ISO images have not yet been rebuilt with this fix.

Existing source attribution and GPL licensing are retained.
This change has not been accepted into mainline Linux.

## Included patch

patches/spi-hid-surface-pm-test1.patch records the changes relative
to the previous bundled source.

The repository source already contains the fix.
Do not apply the patch a second time.
