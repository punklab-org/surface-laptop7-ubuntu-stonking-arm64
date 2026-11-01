#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
check_kernel

mkdir -p ~/camera-surface/build
cd ~/camera-surface/build
cp "$BUNDLE_ROOT/overlays/camera-overlay.dts" ./camera-overlay.dts
cpp -P -nostdinc -undef -x assembler-with-cpp \
-I "$HOME/wifi-surface-kernel/linux-qcom-x1e-7.3.0/include" \
camera-overlay.dts -o camera-overlay-preprocessed.dts
dtc -@ -I dts -O dtb -o camera-overlay.dtbo camera-overlay-preprocessed.dts
fdtoverlay -i /boot/surface-touchpad-touchscreen-test.dtb \
-o surface-camera-test.dtb camera-overlay.dtbo

fdtget -t x surface-camera-test.dtb /soc@0/cci@ac16000/i2c-bus@1 '#address-cells'
fdtget -t x surface-camera-test.dtb /soc@0/cci@ac16000/i2c-bus@1 '#size-cells'
fdtget -t s surface-camera-test.dtb /soc@0/cci@ac16000/i2c-bus@1/camera@36 compatible
fdtget -t x surface-camera-test.dtb /soc@0/cci@ac16000/i2c-bus@1/camera@36 reg
# Link check: both values must match.
fdtget -t x surface-camera-test.dtb /soc@0/isp@acb7000/ports/port@3/endpoint@0 remote-endpoint
fdtget -t x surface-camera-test.dtb /soc@0/cci@ac16000/i2c-bus@1/camera@36/port/endpoint phandle
sudo install -m 644 surface-camera-test.dtb /boot/surface-camera-test.dtb
create_entry 43_surface_camera_test "Ubuntu 7.3.0-31-qcom-x1e all peripherals" surface-camera-test /boot/surface-camera-test.dtb
sudo apt install v4l-utils libcamera-tools qcam libspa-0.2-libcamera
echo "Reboot and check with cam -l and qcam."
