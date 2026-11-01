#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
check_kernel

sudo apt install device-tree-compiler
cd ~/touchpad-surface/build-qspi
# The session used x1e-nixos; this path uses the embedded source archive.
cpp -P -nostdinc -undef -x assembler-with-cpp ~/touchpad-surface/archivio/kernel/dtb-overlays/surface-laptop-7-touchpad.dts -o touchpad-overlay.dts
dtc -@ -I dts -O dtb -o touchpad-overlay.dtbo touchpad-overlay.dts
sudo cat /sys/firmware/fdt > surface-original.dtb
fdtoverlay -i surface-original.dtb -o surface-touchpad-boot.dtb touchpad-overlay.dtbo
(
set -e
kver=$(uname -r)
test "$kver" = "7.3.0-31-qcom-x1e"
work=~/touchpad-surface/build-qspi
stage=~/touchpad-surface/test-root
mkdir -p "$stage/lib/modules"
cp -a --reflink=auto "/lib/modules/$kver" "$stage/lib/modules/"
mkdir -p "$stage/lib/modules/$kver/updates/touchpad-test"
install -m 644 "$work/drivers/dma/qcom/gpi.ko" "$stage/lib/modules/$kver/updates/touchpad-test/"
install -m 644 "$work/drivers/spi/spi-geni-qcom.ko" "$stage/lib/modules/$kver/updates/touchpad-test/"
install -m 644 ~/touchpad-surface/archivio/kernel/modules/spi-hid/spi-hid.ko "$stage/lib/modules/$kver/updates/touchpad-test/"
depmod -b "$stage" "$kver"
sudo dracut --force --kver "$kver" --kmoddir "$stage/lib/modules/$kver" --force-drivers "gpi spi-geni-qcom spi-hid" /boot/initrd.img-surface-touchpad-test
sudo install -m 644 "$work/surface-touchpad-boot.dtb" /boot/surface-touchpad-test.dtb
)
create_entry 41_surface_touchpad_test "Ubuntu - Surface touchpad test" surface-touchpad-test /boot/surface-touchpad-test.dtb
echo "Reboot using the new entry and check pointer movement."
