#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
check_kernel

mkdir -p ~/touchpad-surface/touchscreen-test
cd ~/touchpad-surface/touchscreen-test
cat > touchscreen.dts <<'DTS'
/dts-v1/;
/plugin/;
/ { compatible = "microsoft,romulus13", "qcom,x1e80100"; };
&i2c8 {
    clock-frequency = <400000>;
    status = "okay";
    touchscreen@34 {
        compatible = "hid-over-i2c";
        reg = <0x34>;
        hid-descr-addr = <0>;
        interrupt-parent = <&tlmm>;
        interrupts = <38 8>;
        pinctrl-0 = <&touchscreen_int_default>;
        pinctrl-names = "default";
    };
};
&tlmm {
    touchscreen_int_default: touchscreen-int-default-state {
        pins = "gpio38";
        function = "gpio";
        bias-pull-up;
    };
};
DTS
dtc -@ -I dts -O dtb -o touchscreen.dtbo touchscreen.dts
fdtoverlay -i /boot/surface-touchpad-test.dtb -o surface-touchpad-touchscreen.dtb touchscreen.dtbo
sudo install -m 644 surface-touchpad-touchscreen.dtb /boot/surface-touchpad-touchscreen-test.dtb
create_entry 42_surface_touchscreen_test "Ubuntu - Touchpad and touchscreen test" surface-touchscreen-test /boot/surface-touchpad-touchscreen-test.dtb
echo "Reboot using the touchscreen entry before continuing."
