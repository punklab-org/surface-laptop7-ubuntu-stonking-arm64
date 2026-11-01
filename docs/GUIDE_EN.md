# Ubuntu 26.10 ARM64 X1E on Surface Laptop 7 — Post-installation guide


stonking-desktop-arm64-x1e • Surface Laptop 7 13.8″ • 10-core Snapdragon X Plus

Procedure based on the working Surface configuration: firmware, Wi-Fi, Adreno, multitouch touchpad, touchscreen, webcam, audio, battery settings and a corrected 10-core Device Tree.
## Before you start


**Translation note:** Procedural comments, prompts and GRUB display titles are translated into English. Technical identifiers, paths, patch files and upstream source files retain their original names. The GRUB examples use ROOT_FILESYSTEM_UUID as an installation-specific placeholder; replace it with the UUID of your own root filesystem. The English script package detects this UUID automatically. This guide does not include proprietary firmware or the full kernel source archive.

**GitHub package:** the English ZIP accompanying this guide contains a README, numbered scripts, patches and source files. For a fresh installation, follow the README sequence; do not apply the same changes both through the scripts and through the manual command blocks. The scripts automate the procedure, but have not been run end to end on ARM64 in the environment used to prepare this guide.

**Reinstallation warning:** the GRUB examples contain the UUID of the drive used during testing. After a fresh installation, replace it with the new root UUID obtained with `findmnt -no UUID /`. The examples assume /boot is on the same ext4 partition as the root filesystem; with a separate /boot partition, adapt the paths to the generated Ubuntu entry. Do not change the UUID on an already working installation.

**Order of operations:** 1) Surface firmware and the exact kernel; 2) Wi-Fi board alias and RF-kill workaround; 3) Mesa verification; 4) three touchpad modules and overlay; 5) separate initramfs and Stubble; 6) iptsd and gestures; 7) touchscreen overlay; 8) camera overlay; 9) Firefox/PipeWire; 10) 10-core Device Tree; 11) audio, suspend and battery; 12) backup and optional cleanup. The technical blocks below are specific to this installation; do not run them all again on a working system. Do not run rollback commands during installation.
## Notice and disclaimer


This guide and the accompanying scripts are provided “as is”, without warranties of functionality, compatibility or fitness for a particular purpose.

The procedure was developed for the 13.8-inch Microsoft Surface Laptop 7 with a 10-core Snapdragon X Plus X1P-64-100, Ubuntu 26.10 ARM64 and kernel 7.3.0-31-qcom-x1e. Other configurations may behave differently.

The procedure changes drivers, firmware files, the Device Tree and boot configuration. Incorrect or incompatible changes may cause data loss, boot failure, malfunction or damage. Read and understand the instructions, back up your data and prepare recovery media before proceeding. Use the guide and scripts at your own risk.

To the extent permitted by applicable law, the author and contributors disclaim liability for direct or indirect damage, data loss or other problems arising from use of this guide and its scripts. This notice does not override applicable law or the licences of third-party components.

The scripts assembled in the repository have not been tested end to end on a fresh installation. Read the validation report before using them.
## Contents

## 1. System configuration and confirmed results


Guide to the documented configuration • Work carried out on 31 October–1 November 2026. This records the configuration actually tested on the Surface and provides technical steps to rebuild its components. It applies to the stonking-desktop-arm64-x1e ISO and the stated kernel, rather than to other models or kernels in general. Build instructions are intended for a fresh installation, not for repeating changes on a working system.

| Item | Configuration |
| --- | --- |
| Computer | Microsoft Surface Laptop 7, 13.8-inch, ARM64 |
| Device Tree identifiers | microsoft,romulus13 / qcom,x1e80100 |
| Ubuntu | 26.10 — Stonking Stingray |
| Working kernel | 7.3.0-31-qcom-x1e (package 7.3.0-31.31) |
| Actual processor | Snapdragon X Plus X1P-64-100, 10 cores; SMBIOS Core Count/Core Enabled: 10 |
| Bootloader | GRUB; Ubuntu kernel with Stubble |
| Secure Boot | Disabled during testing |
| Wi-Fi | Qualcomm WCN785x / WCN7850 hw2.0, PCI 17cb:1107 |
| Graphics | Adreno X1-85; Mesa 26.2.4 |
| Touchpad | 045E:0C77, HID over SPI / QSPI |


| Feature | Observed result |
| --- | --- |
| Wi-Fi | Connection and browsing confirmed |
| 3D graphics | OpenGL hardware acceleration and Vulkan device detection confirmed |
| Touchpad pointer movement | Confirmed with the custom modules and test Device Tree |
| Two-finger scrolling | Confirmed with locally compiled iptsd |
| Selection and copy/paste | Confirmed after enabling tap-to-click and tap-and-drag |
| Automatic iptsd startup | Service active/running; scrolling confirmed without manual daemon startup |
| Suspend and resume | Deep suspend and resume on lid opening confirmed in a short test; peripherals still worked |
| Webcam | OV02C10 detected; five frames captured, qcam preview and Google Meet working |
| Touchscreen | 1FD2:3001 detected and working; continuous contact verified |
| Speakers and microphone | Both confirmed; audio restored after restarting services and setting mute/volume, then confirmed again after a reboot |
| Battery / AC adapter | Charging/discharging detected; reported full capacity 43.99 Wh versus 52.33 Wh design capacity; runtime depends on workload |


**Final boot entry:** use “Ubuntu 7.3.0-31-qcom-x1e all peripherals - 10 core”. This entry includes the touchpad, touchscreen, camera and corrected 10-core topology, using Ubuntu kernel 7.3.0-31 and the custom touchpad initramfs. It was not set as the default during the documented procedure. Keep the other entries for recovery. The iptsd service was observed running and multitouch remained functional during the later stages.
## 2. Booting and using the system


Restart, press Esc repeatedly to display GRUB, and select **Ubuntu 7.3.0-31-qcom-x1e all peripherals - 10 core**. This is the same Ubuntu kernel, but the entry uses a dedicated initramfs and Device Tree. If the test entry does not boot, select the normal 7.3.0-31-qcom-x1e entry under Advanced options.

```bash
uname -r
cat /proc/cmdline
systemctl list-units --all --no-pager 'iptsd*'
rfkill list
nmcli device status
```


The touchpad boot command line must include `stubble.dtb_override=false`. The expected service is `iptsd@dev-hidrawN.service`, active/running. N is not fixed: it was 0 in one successful test.
## 3. Preparing the installed system


**Verified scope:** Surface Laptop 7 13.8″, compatible string `microsoft,romulus13`, X1P64100 processor and `7.3.0-31-qcom-x1e` kernel. Do not apply the CPU workaround to a 12-core model. Start with USB Ethernet. Keep a USB keyboard/mouse available until the touchpad works. Secure Boot was disabled during testing: the modules built here are not signed with a key trusted by the firmware.

Before reinstalling, save the extracted firmware and the backup described near the end of this guide to external storage. Do not remove Windows before extracting the required firmware.

```bash
cat /etc/os-release
uname -r
tr '\0' '\n' < /sys/firmware/devicetree/base/compatible
sudo dmidecode -t processor
mokutil --sb-state
lsblk -f
apt-cache policy linux-image-qcom-x1e linux-headers-qcom-x1e
```


The tested kernel came from the Ubuntu Concept X1E PPA. Do not add it again if it is already configured. The metapackage tracks updates, but a newer kernel does not automatically make these patches compatible. If the exact version is unavailable in the repositories, use your saved packages or stop and adapt the procedure; do not simply replace the version number in the commands.

```bash
sudo apt update
sudo apt install build-essential git curl zstd xz-utils patch python3 libelf-dev libssl-dev device-tree-compiler dracut-core linux-headers-$(uname -r)
test "$(uname -r)" = "7.3.0-31-qcom-x1e"
```


Downloading sources through APT also requires the source indexes for the Concept repository. In “Software & Updates”, enable source code for the relevant repository; in Deb822 files the field is `Types: deb deb-src`. Do not create a second source with key or signature checks disabled. Refresh indexes with `sudo apt update`.

**Firmware extraction from Windows — prerequisite.** The following command is documented by the Ubuntu project; the extracted firmware package was installed during the session. The details of the earlier BitLocker prompts were not retained. Follow the tool’s local prompts and do not share your recovery key.

```bash
sudo apt install qcom-firmware-extract
sudo qcom-firmware-extract
# After completion, check the Romulus-specific package:
dpkg-query -W 'qcom-x1e-firmware-extracted*' 2>/dev/null
```


The tool locates the Windows partition, extracts firmware, builds and installs the package, and updates the initramfs. Keep the generated .deb. The machine had `qcom-x1e-firmware-extracted-x1e80100-microsoft-romulus`, version `20261031`. Reboot before continuing. If Windows is no longer available, use your saved .deb rather than firmware from a different model.

References: [Ubuntu FAQ: firmware extraction](https://discourse.ubuntu.com/t/faq-ubuntu-25-04-25-10-on-snapdragon-x-elite/61016) and the [project manual](https://github.com/Srinivas-Kandagatla/qcom-firmware-extract/blob/ubuntu/devel/qcom-firmware-extract.8). The FAQ also covers earlier releases: do not apply its older Snap channel suggestions to this installation without checking them.
## 4. Wi-Fi: the two issues and their fixes


Initially, nmcli listed only Ethernet; lspci detected the adapter and ath12k_wifi7_pci driver. The main firmware started, but could not find the matching board entry for subsystem-device=1107 and qmi-board-id=255. An alias was added to board-2.bin using the existing subsystem-device=3378, board-id=255 configuration. After this change the wlP4p1s0 interface appeared.

The second obstacle was `Hard blocked: yes`. The ath12k and ath12k_wifi7 modules were built from the exact Ubuntu source, bypassing RF-kill configuration only on microsoft,romulus13 with WCN7850 hw2.0. After reboot the hardware block became “no” and the Wi-Fi connection worked.

```bash
sudo apt install curl zstd build-essential libelf-dev libssl-dev linux-headers-$(uname -r)
mkdir -p ~/wifi-surface-fix
cd ~/wifi-surface-fix
zstd -d -f /lib/firmware/ath12k/WCN7850/hw2.0/board-2.bin.zst -o board-2.bin
curl -fL https://raw.githubusercontent.com/qca/qca-swiss-army-knife/master/tools/scripts/ath12k/ath12k-bdencoder -o ath12k-bdencoder
python3 ath12k-bdencoder -e board-2.bin
```


The extracted JSON was modified as follows. Check that the files match the version documented here before running this again.

```bash
python3 <<'PYCODE'
import json
from pathlib import Path
data = json.loads(Path("board-2.json").read_text())
base = "bus=pci,vendor=17cb,device=1107,subsystem-vendor=17cb,"
suffix = ",qmi-chip-id=2,qmi-board-id=255"
source = base + "subsystem-device=3378" + suffix
target = base + "subsystem-device=1107" + suffix
for group in data:
    for entry in group.get("board", []):
        names = entry.get("names", [])
        if source in names:
            if target not in names:
                names.append(target)
            Path("board-surface.json").write_text(json.dumps(data, indent=4))
            print("Surface configuration prepared")
            raise SystemExit(0)
raise SystemExit("Configuration not found: stop here")
PYCODE
python3 ath12k-bdencoder -c board-surface.json &&
sudo install -m 644 board-2.bin /lib/firmware/ath12k/WCN7850/hw2.0/board-2.bin &&
sudo update-initramfs -u
```


The original compressed `board-2.bin.zst` was retained. An initial attempt using a single `board.bin` did not solve the issue and was undone. Do not repeat it. A reboot was reported during attempts to reload modules at runtime; live unloading/reloading was therefore abandoned.

```bash
mkdir -p ~/wifi-surface-kernel
cd ~/wifi-surface-kernel
apt-get source --only-source linux-qcom-x1e=7.3.0-31.31
cd linux-qcom-x1e-7.3.0
```


If the source was archived during cleanup, instead extract `~/wifi-surface-kernel/linux-qcom-x1e-7.3.0-surface_laptop7.tar.xz` with `tar -xJf` from the same directory. Do not download it again or apply changes twice. That 180 MB archive is on your computer and is not embedded in this guide.

Apply the RF-kill workaround only if it is not already present in the source. It remains restricted to Surface Romulus13 and WCN7850 hw2.0.

```bash
python3 <<'PYCODE'
from pathlib import Path
p = Path("drivers/net/wireless/ath/ath12k/core.c")
s = p.read_text()
marker = "Surface Laptop 7 Romulus13"
if marker in s:
    print("Workaround already present")
else:
    old = "\tif (ath12k_acpi_get_disable_rfkill(ab))\n\t\treturn 0;\n"
    if s.count(old) != 1:
        raise SystemExit("Unexpected source: stop here")
    addition = '\n\t/* Surface Laptop 7 Romulus13: unusable hardware rfkill line. */\n\tif (ab->hw_rev == ATH12K_HW_WCN7850_HW20 &&\n\t    of_machine_is_compatible("microsoft,romulus13"))\n\t\treturn 0;\n'
    if "#include <linux/of.h>" not in s:
        raise SystemExit("OF header missing: check the source")
    p.write_text(s.replace(old, old + addition, 1))
    print("Workaround applied")
PYCODE
```


```bash
make -C /lib/modules/$(uname -r)/build M="$PWD/drivers/net/wireless/ath/ath12k" -j2 modules

sudo install -D -m 644 drivers/net/wireless/ath/ath12k/ath12k.ko /lib/modules/7.3.0-31-qcom-x1e/updates/surface-wifi/ath12k.ko
sudo install -D -m 644 drivers/net/wireless/ath/ath12k/wifi7/ath12k_wifi7.ko /lib/modules/7.3.0-31-qcom-x1e/updates/surface-wifi/ath12k_wifi7.ko
sudo depmod -a 7.3.0-31-qcom-x1e
sudo update-initramfs -u -k 7.3.0-31-qcom-x1e
```


Then reboot normally and verify:

```bash
rfkill list
nmcli radio wifi on
nmcli --ask device wifi connect "YOUR_NETWORK_NAME"
nmcli device status
```

## 5. Adreno graphics: what was actually installed


GPU firmware loading was observed in the logs. The following command requested Mesa components and firmware, but APT actually installed only mesa-utils, mesa-utils-bin and vulkan-tools: the drivers were already present. Installing Adreno components did not repair Wi-Fi; the logs show the Wi-Fi device being created before that installation.

```bash
sudo apt install libgl1-mesa-dri libegl-mesa0 mesa-vulkan-drivers mesa-utils vulkan-tools linux-firmware-qualcomm-graphics
glxinfo -B
vulkaninfo --summary
```


Result: Adreno X1-85 renderer, Freedreno, Accelerated: yes, OpenGL 4.6, OpenGL ES 3.2; Vulkan 1.4 through Turnip. An llvmpipe entry in the Vulkan list is an additional available software device, not evidence that OpenGL uses the CPU. Hardware video decoding was not verified.
## 6. Touchpad: components of the fix


The touchpad was initially absent from /proc/bus/input/devices, although the GNOME setting was already enabled. The kernel source did not provide SPI-HID or enable the touchpad in the Device Tree. Four components were needed: SPI-HID, QSPI extensions for the GENI controller, QSPI extensions for GPI DMA, and a romulus13 Device Tree overlay. iptsd was then required for multitouch.

Source used: the scuggo/x1e-nixos repository, commit `ca7db709ee29ecdd3c00fec679febdfb2ebfaa32`. The GPI patch applied; the SPI patch needed adaptation for geni_spi_desc and automatic power management. Modules were compiled against the exact running kernel headers.

**Files embedded in this guide:** open this HTML in a browser and download the two files below. The archive is the one supplied during the session; the consolidated SPI patch was reconstructed from those sources and the successful adjustments. Application to the supplied source was checked with patch --dry-run --fuzz=0; the binary was not rebuilt in the environment preparing this guide.

[Download the original source files and patches from the session](../touchpad-sorgenti.tar.gz)

[Download the adapted, consolidated SPI patch](../patches/spi-geni-qcom-ubuntu-7.3.0-31.patch)

The following steps rebuild this exact configuration; they are not intended for repeating changes on a working system. Keep the extracted Ubuntu source tree: it also contains internal headers needed to build GPI.

```bash
mkdir -p ~/touchpad-surface/archivio
cd ~/touchpad-surface/archivio
# Copy both files downloaded from this guide into this directory first.
tar --no-same-owner -xzf touchpad-sorgenti.tar.gz

# Check the SPI patch against the original source:
patch --dry-run --fuzz=0 -p1 < spi-geni-qcom-ubuntu-7.3.0-31.patch
# Stop if the check fails.
```

## 7. Rebuilding the touchpad modules


The session used ~/touchpad-surface/x1e-nixos as the repository. When rebuilding from the archive, use ~/touchpad-surface/archivio for kernel/modules and dtb-overlays. The following block uses the archive and works on clean copies; it does not install modules.

```bash
(
set -e
src=~/wifi-surface-kernel/linux-qcom-x1e-7.3.0
repo=~/touchpad-surface/archivio
work=~/touchpad-surface/build-qspi
mkdir -p "$work"/drivers/dma/qcom "$work"/drivers/spi "$work"/include/linux/dma "$work"/include/dt-bindings/dma
cp "$src/drivers/dma/qcom/gpi.c" "$work/drivers/dma/qcom/"
cp "$src/drivers/dma/"{dmaengine.h,virt-dma.h} "$work/drivers/dma/"
cp "$src/drivers/spi/spi-geni-qcom.c" "$work/drivers/spi/"
cp "$src/include/linux/dma/qcom-gpi-dma.h" "$work/include/linux/dma/"
cp "$src/include/dt-bindings/dma/qcom-gpi.h" "$work/include/dt-bindings/dma/"
cd "$work"
patch --batch -p1 < "$repo/kernel/modules/qcom-qspi/gpi.patch"
patch --batch --fuzz=0 -p1 < "$repo/spi-geni-qcom-ubuntu-7.3.0-31.patch"
python3 <<'PYCODE'
from pathlib import Path
for name in ("drivers/dma/qcom/gpi.c", "drivers/spi/spi-geni-qcom.c"):
    p = Path(name)
    s = p.read_text()
    for header in ("dt-bindings/dma/qcom-gpi.h", "linux/dma/qcom-gpi-dma.h"):
        s = s.replace(f"<{header}>", f'"{Path("include", header).resolve()}"')
    p.write_text(s)
Path("drivers/dma/qcom/Makefile").write_text("obj-m += gpi.o\n")
Path("drivers/spi/Makefile").write_text("obj-m += spi-geni-qcom.o\n")
PYCODE
make -C /lib/modules/$(uname -r)/build M="$work/drivers/dma/qcom" -j2 modules
make -C /lib/modules/$(uname -r)/build M="$work/drivers/spi" -j2 modules
make -C /lib/modules/$(uname -r)/build M="$repo/kernel/modules/spi-hid" -j2 modules
)
```


All three modules compiled with exit status 0 during the session. Missing BTF information and the nominal gcc/aarch64-linux-gnu-gcc name difference did not prevent compilation. The kernel reports the missing signature, but loaded the modules with Secure Boot disabled. This does not establish compatibility with Secure Boot enabled.
## 8. Device Tree, separate initramfs and GRUB


The overlay enables spi19 at 20 MHz, 1-4-4 transfers, a controller compatible with qcom,geni-spi-qspi, and a hid-over-spi child. It was first tested against a dump of the active Device Tree. The original /sys/firmware/fdt blob was used for the boot file to preserve its memory reservations.

```bash
sudo apt install device-tree-compiler
cd ~/touchpad-surface/build-qspi
# The session used x1e-nixos; this path uses the embedded source archive.
cpp -P -nostdinc -undef -x assembler-with-cpp ~/touchpad-surface/archivio/kernel/dtb-overlays/surface-laptop-7-touchpad.dts -o touchpad-overlay.dts
dtc -@ -I dts -O dtb -o touchpad-overlay.dtbo touchpad-overlay.dts
sudo cat /sys/firmware/fdt > surface-original.dtb
fdtoverlay -i surface-original.dtb -o surface-touchpad-boot.dtb touchpad-overlay.dtbo
```


Create the module staging copy and dedicated initramfs. When rebuilding, adapt the SPI-HID path if using the repository rather than the archive. Do not overwrite the normal initramfs.

```bash
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
```


**The decisive change:** on the first boot, modules were loaded but spi@88c000 was still disabled in the active Device Tree. Adding `stubble.dtb_override=false` allowed Stubble to use the external Device Tree, and the touchpad was detected. Do not rely on a devicetree command alone without checking this parameter.

GRUB entry tested on the machine. **Replace ROOT_FILESYSTEM_UUID with the UUID of your own root filesystem**: on a fresh installation, check it with lsblk -f and use the generated Ubuntu entry as a reference. This block records the session configuration; do not copy it blindly to another drive.

```bash
sudo tee /etc/grub.d/41_surface_touchpad_test >/dev/null <<'GRUBEOF'
#!/bin/sh
exec tail -n +3 $0
menuentry 'Ubuntu - Surface touchpad test' --id surface-touchpad-test {
    insmod part_gpt
    insmod ext2
    search --no-floppy --fs-uuid --set=root ROOT_FILESYSTEM_UUID
    linux /boot/vmlinuz-7.3.0-31-qcom-x1e root=UUID=ROOT_FILESYSTEM_UUID ro clk_ignore_unused pd_ignore_unused cma=128M efi=noruntime console=tty0 stubble.dtb_override=false
    devicetree /boot/surface-touchpad-test.dtb
    initrd /boot/initrd.img-surface-touchpad-test
}
GRUBEOF
sudo chmod +x /etc/grub.d/41_surface_touchpad_test
sudo update-grub
sudo grub-script-check /boot/grub/grub.cfg
```


Save open documents, reboot and select the test entry. If boot fails, return to the normal entry. The touchpad module changes are inside the dedicated initramfs; they were not installed into the system module directory.
## 9. Multitouch: building and automatically starting iptsd


Device detection alone was not enough: the Mouse interface moved the pointer while the multitouch Touchpad interface produced no events. This explained the missing scrolling. Locally compiled iptsd processed the touchpad data and enabled scrolling.

The older ELLX .deb had produced SIGILL (“Illegal instruction”) and was later no longer installed. The precise instruction causing the crash was not identified. The local build succeeded and the manual test connected to 045E:0C77 in Touchpad mode.

```bash
sudo apt install git build-essential meson ninja-build cmake pkg-config libcli11-dev libeigen3-dev libfmt-dev libinih-dev libgsl-dev libspdlog-dev
cd ~/touchpad-surface
git clone --depth 1 https://github.com/alex-lentz/iptsd.git iptsd-source
cd iptsd-source
meson setup build --buildtype=release -Dwerror=false -Db_lto=false -Ddebug_tools=calibrate -Dcpp_args=-march=armv8-a
meson compile -C build -j 2
./build/src/iptsd --help
```


Technical note: the Meson log also showed an armv8.2-a architecture option in the project. It was not established that all final flags came solely from -Dcpp_args; the compiled binary was verified to work on this Surface. Meson downloaded Microsoft.GSL automatically; the libgsl-dev package is a different library.

Identify the device before testing: hidraw numbering changes. In one successful session hidraw0 was the touchpad; earlier hidraw1 was the wireless receiver, so it must not be calibrated as a touchpad.

```bash
grep -H -E 'HID_NAME|HID_ID' /sys/class/hidraw/*/device/uevent
sudo modprobe uinput
# ONLY if /dev/hidraw0 corresponds to 045E:0C77:
sudo ./build/src/iptsd /dev/hidraw0
```


Keep the program open and test two-finger scrolling, then press Ctrl+C. The “Interrupted system call” message immediately after Ctrl+C resulted from stopping the program. The “Stylus is disabled” warning did not prevent scrolling. The user confirmed this test worked.

```bash
sudo apt install systemd-dev
cd ~/touchpad-surface/iptsd-source
meson setup --reconfigure build --prefix=/usr --sysconfdir=/etc
meson compile -C build -j 2
sudo meson install -C build
sudo systemctl daemon-reload
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=hidraw --action=add
sudo udevadm settle
systemctl list-units --all --no-pager 'iptsd*'
```


Observed result: iptsd@dev-hidraw0.service loaded active running. Scrolling also worked without starting the daemon manually. udev associates the service with the device; systemctl enable was not used for a fixed hidraw number. Calibration was not required to achieve the confirmed result.
## 10. Selection, dragging, copy and paste


```bash
gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled true
gsettings set org.gnome.desktop.peripherals.touchpad edge-scrolling-enabled false
gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
gsettings set org.gnome.desktop.peripherals.touchpad tap-and-drag true
```


Run gsettings as the graphical-session user, without sudo. To select text, tap twice quickly, keep your finger down on the second tap, and drag. Alternatively, hold a physical click with one finger while moving another, if physical clicking is handled correctly. Selection and copy/paste were confirmed after these settings.

| Context | Copy | Paste |
| --- | --- | --- |
| Browser / documents | Ctrl+C | Ctrl+V |
| Terminal | Ctrl+Shift+C | Ctrl+Shift+V |

## 11. Touchscreen: I²C overlay and additional boot entry


The touchscreen was absent from the Device Tree. I2C_HID, I2C_HID_OF and HID_MULTITOUCH drivers were already available as modules. The HID-over-I²C controller was described on i2c8 at address 0x34, with HID descriptor register 0 and GPIO38 interrupt with pull-up. No kernel rebuild was needed for the touchscreen.

```bash
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
```


Duplicate the touchpad entry with controlled replacements. The 41_surface_touchpad_test file must already contain stubble.dtb_override=false.

```bash
sudo python3 <<'PYCODE'
from pathlib import Path
s = Path("/etc/grub.d/41_surface_touchpad_test").read_text()
changes = {
    "Ubuntu - Surface touchpad test": "Ubuntu - Touchpad and touchscreen test",
    "--id surface-touchpad-test": "--id surface-touchscreen-test",
    "/boot/surface-touchpad-test.dtb": "/boot/surface-touchpad-touchscreen-test.dtb",
}
for old, new in changes.items():
    if s.count(old) != 1:
        raise SystemExit("Unexpected entry: stop here")
    s = s.replace(old, new, 1)
p = Path("/etc/grub.d/42_surface_touchscreen_test")
p.write_text(s)
p.chmod(0o755)
PYCODE
sudo update-grub
sudo grub-script-check /boot/grub/grub.cfg
```


Reboot and select “Ubuntu - Touchpad and touchscreen test”. Observed result: hid-over-i2c 1FD2:3001, eventually handled by hid-multitouch. The vdd/vddl dummy regulator warnings did not prevent operation. The libinput test maintained continuous contact for 3.524 seconds until the finger was deliberately lifted. No calibration matrix or hardware sensitivity adjustment was applied. The reported difficulty concerned small interface elements; increasing display scaling was suggested, but a change was not confirmed.

```bash
sudo libinput list-devices
# Identify device 1FD2:3001 and its current eventN node.
# It was event6 during testing; numbering may change:
sudo libinput debug-events --device /dev/input/event6
```

## 12. Webcam: Device Tree, capture and preview


Camera files from the verified procedure, retained here in case the upstream project changes:

[Download camera-overlay.dts](../overlays/camera-overlay.dts)

[Download 0004-OV02C10-camera-device-tree.patch](../patches/0004-OV02C10-camera-device-tree.patch)

[Download ov02c10.yaml](../config/ov02c10.yaml)

The kernel already supports CAMSS, CCI, the OV02C10 sensor and Qualcomm MIPI CSI2 PHY. The camss, cci1 and csiphy4 nodes existed but were disabled. The sensor was enabled with an overlay derived from community project patch 0004, adding PM8010 supplies, clocks, pins and pipeline links. Driver metadata patch 0005 was not applied: the camera captured images despite crop rectangle warnings.

```bash
mkdir -p ~/camera-surface
cd ~/camera-surface
git clone --depth 1 https://github.com/bryce-hoehn/linux-surface-laptop-7.git
# Record the downloaded revision for future rebuilding:
git -C linux-surface-laptop-7 rev-parse HEAD
mkdir -p ~/camera-surface/build
cd ~/camera-surface/build
```


The following generator expects the three-hunk patch version examined during the session. If the project changes, it stops rather than guessing. It does not patch the kernel source.

```bash
python3 <<'PYCODE'
from pathlib import Path
import re
patch = (Path.home() / "camera-surface/linux-surface-laptop-7/patches/"
         "outgoing/ov02c10/0004-OV02C10-camera-device-tree.patch").read_text()
hunks = re.split(r"^@@[^\n]*\n", patch, flags=re.M)[1:]
if len(hunks) != 3:
    raise SystemExit("Unexpected patch: stop here")
added = ["\n".join(line[1:] for line in h.splitlines()
                   if line.startswith("+") and not line.startswith("+++"))
         for h in hunks]
if ("regulators-8" not in added[0] or "&camss" not in added[1]
    or "cam_rgb_default:" not in added[2]):
    raise SystemExit("Unexpected structure: stop here")
overlay = """
/dts-v1/;
/plugin/;
#include <dt-bindings/gpio/gpio.h>
#include <dt-bindings/regulator/qcom,rpmh-regulator.h>
#include <dt-bindings/clock/qcom,x1e80100-camcc.h>
/ { compatible = "microsoft,romulus13", "qcom,x1e80100"; };
&{/soc@0/rsc@17500000} {
""" + added[0] + "\n};\n" + added[1] + "\n&tlmm {\n" + added[2] + "\n};\n"
Path("camera-overlay.dts").write_text(overlay)
print("Camera overlay prepared")
PYCODE
cpp -P -nostdinc -undef -x assembler-with-cpp -I "$HOME/wifi-surface-kernel/linux-qcom-x1e-7.3.0/include" camera-overlay.dts -o camera-overlay-preprocessed.dts
dtc -@ -I dts -O dtb -o camera-overlay.dtbo camera-overlay-preprocessed.dts
fdtoverlay -i /boot/surface-touchpad-touchscreen-test.dtb -o surface-camera-test.dtb camera-overlay.dtbo
```


Compiling the standalone overlay produced reg and address-cells warnings. In the merged Device Tree, bus cells 1/0, compatible ovti,ov02c10, reg=36, endpoint properties and a consistent remote-endpoint link were verified. This explains this specific result; it does not mean all DTC warnings can be ignored on other versions.

```bash
fdtget -t x surface-camera-test.dtb /soc@0/cci@ac16000/i2c-bus@1 '#address-cells'
fdtget -t x surface-camera-test.dtb /soc@0/cci@ac16000/i2c-bus@1 '#size-cells'
fdtget -t s surface-camera-test.dtb /soc@0/cci@ac16000/i2c-bus@1/camera@36 compatible
fdtget -t x surface-camera-test.dtb /soc@0/cci@ac16000/i2c-bus@1/camera@36 reg
# Link check: both values must match.
fdtget -t x surface-camera-test.dtb /soc@0/isp@acb7000/ports/port@3/endpoint@0 remote-endpoint
fdtget -t x surface-camera-test.dtb /soc@0/cci@ac16000/i2c-bus@1/camera@36/port/endpoint phandle
```


```bash
sudo install -m 644 "$HOME/camera-surface/build/surface-camera-test.dtb" /boot/surface-camera-test.dtb
sudo python3 <<'PYCODE'
from pathlib import Path
s = Path("/etc/grub.d/42_surface_touchscreen_test").read_text()
changes = {
    "Ubuntu - Touchpad and touchscreen test": "Ubuntu - Camera test",
    "--id surface-touchscreen-test": "--id surface-camera-test",
    "/boot/surface-touchpad-touchscreen-test.dtb": "/boot/surface-camera-test.dtb",
}
for old, new in changes.items():
    if s.count(old) != 1:
        raise SystemExit("Unexpected entry: stop here")
    s = s.replace(old, new, 1)
p = Path("/etc/grub.d/43_surface_camera_test")
p.write_text(s)
p.chmod(0o755)
PYCODE
sudo update-grub
sudo grub-script-check /boot/grub/grub.cfg
```


Reboot and select “Ubuntu - Camera test”. This entry still uses the custom touchpad initramfs. If it fails, return to “Ubuntu - Touchpad and touchscreen test”. Previous boot files are not overwritten.

```bash
sudo apt install v4l-utils libcamera-tools qcam
ls -l /dev/video* /dev/media* 2>/dev/null
media-ctl -d /dev/media0 -p
cam -l
mkdir -p ~/camera-surface/prova
cd ~/camera-surface/prova
cam -c 1 --capture=5 --file='fotogramma-#.bin'
qcam
```


Observed results: /dev/media0 and sixteen /dev/video nodes; ov02c10 9-0036 sensor in the pipeline; “Internal front camera” in cam -l; five files of about 8 MB captured; visible preview in qcam. Multiple video nodes are outputs from the same pipeline, not sixteen cameras. The .bin files are raw buffers rather than ordinary photographs.
## 13. Google Meet and image quality


PipeWire listed ov02c10 [libcamera] and “Fotocamera frontale integrata” (integrated front camera) as a source. Meet in Firefox initially did not see it; enabling PipeWire camera access made it work. No virtual V4L2 camera or further driver changes were required.

**Firefox steps:** close qcam; open about:config; find media.webrtc.camera.allow-pipewire and set it to true if the preference exists; fully close and reopen Firefox; open Meet and allow access; select the integrated front camera and Internal microphones. The user confirmed this worked.

The project’s colour profile was then installed. libcamera was not rebuilt, no global exposure patch was applied, and the software_isp: mode: cpu workaround was not enabled. Coloured noise observed in a very dark scene remains a limitation; its exact cause was not measured. The user chose to leave image quality as it was for the time being.

```bash
# Close qcam and Meet tabs first.
sudo python3 <<'PYCODE'
from pathlib import Path
import shutil
import os
src = Path(os.environ.get("SUDO_USER", "surface"))
src = Path("/home") / src / "camera-surface/linux-surface-laptop-7/config/OV02C10-camera/ov02c10.yaml"
dst = Path("/usr/share/libcamera/ipa/simple/ov02c10.yaml")
backup = dst.with_suffix(".yaml.pre-tuning")
if dst.exists() and not backup.exists():
    shutil.copy2(dst, backup)
dst.parent.mkdir(parents=True, exist_ok=True)
shutil.copy2(src, dst)
PYCODE
qcam
```


To undo the profile, restore ov02c10.yaml.pre-tuning if it exists; otherwise remove only ov02c10.yaml. Do not run both alternatives in sequence. Lighting the face from the front helps assess and improve the result; increasing Meet resolution does not remove sensor noise.
## 14. Final CPU fix: 10-core Snapdragon X Plus


**For the 10-core X1P64100 only.** SMBIOS reported Core Count/Core Enabled = 10, but the Device Tree contained 12 nodes and the kernel failed to start CPU7 and CPU9. Setting `status=disabled` alone was insufficient. The confirmed solution removed both nodes from the boot copy and corrected `cpu-map`; after reboot `lscpu` showed 10 online CPUs numbered 0–9, without CPU startup errors.

The following block starts from the camera Device Tree containing all peripherals. It reads phandles from the file instead of hardcoding the 0x1a/0x1c values observed during the session. Paths remain specific to this configuration.

```bash
mkdir -p ~/cpu-surface
cd ~/cpu-surface
cp /boot/surface-camera-test.dtb surface-10core-v2.dtb
python3 <<'PYCODE'
import subprocess as sp
f = "surface-10core-v2.dtb"
def get(node, prop, kind="x"):
    return sp.check_output(["fdtget", "-t", kind, f, node, prop], text=True).strip()
def put(*args):
    sp.run(["fdtput", *args], check=True)
a, b = "/cpus/cpu@10300", "/cpus/cpu@20100"
if get(a, "reg") != "0 10300" or get(b, "reg") != "0 20100":
    raise SystemExit("Unexpected CPU nodes")
if get("/cpus/cpu-map/cluster1/core3", "cpu") != get(a, "phandle"):
    raise SystemExit("Unexpected cluster1 topology")
if get("/cpus/cpu-map/cluster2/core1", "cpu") != get(b, "phandle"):
    raise SystemExit("Unexpected cluster2 topology")
c2 = get("/cpus/cpu-map/cluster2/core2", "cpu")
c3 = get("/cpus/cpu-map/cluster2/core3", "cpu")
put("-r", f, "/cpus/cpu-map/cluster1/core3")
put("-t", "x", f, "/cpus/cpu-map/cluster2/core1", "cpu", c2)
put("-t", "x", f, "/cpus/cpu-map/cluster2/core2", "cpu", c3)
put("-r", f, "/cpus/cpu-map/cluster2/core3")
put("-r", f, a)
put("-r", f, b)
removed = {a, b, "/cpus/cpu-map/cluster1/core3", "/cpus/cpu-map/cluster2/core3"}
for name in sp.check_output(["fdtget", "-p", f, "/__symbols__"], text=True).split():
    if get("/__symbols__", name, "s") in removed:
        put("-d", f, "/__symbols__", name)
print("10-core Device Tree prepared")
PYCODE
dtc -I dtb -O dts surface-10core-v2.dtb -o surface-10core-v2.dts 2> verifica-v2.log
fdtget -l surface-10core-v2.dtb /cpus
grep -Ei 'cpu|phandle|cooling|reference' verifica-v2.log || true
```


Check that 10 cpu@ nodes remain and that the check prints no warnings about CPU references, phandles or cooling. Otherwise stop before installation. The tested case produced no such warnings.

```bash
sudo install -m 644 ~/cpu-surface/surface-10core-v2.dtb /boot/surface-all-peripherals-10core-v2.dtb
sudo python3 <<'PYCODE'
from pathlib import Path
import re
s = Path("/etc/grub.d/43_surface_camera_test").read_text()
s, n = re.subn(r"menuentry '[^']*'", "menuentry 'Ubuntu 7.3.0-31-qcom-x1e all peripherals - 10 core'", s)
if n != 1:
    raise SystemExit("Unexpected title")
for old, new in {
    "--id surface-camera-test": "--id surface-all-peripherals-10core",
    "/boot/surface-camera-test.dtb": "/boot/surface-all-peripherals-10core-v2.dtb",
}.items():
    if s.count(old) != 1:
        raise SystemExit("Unexpected entry: " + old)
    s = s.replace(old, new, 1)
if "stubble.dtb_override=false" not in s:
    raise SystemExit("Missing Stubble parameter")
p = Path("/etc/grub.d/44_surface_10core_test")
p.write_text(s)
p.chmod(0o755)
PYCODE
sudo update-grub
sudo grub-script-check /boot/grub/grub.cfg
```


Reboot and select **Ubuntu 7.3.0-31-qcom-x1e all peripherals - 10 core**. The kernel and initramfs remain the already tested versions; the Device Tree changes. The previous camera entry remains available as a fallback.

```bash
lscpu
cat /sys/devices/system/cpu/online
sudo journalctl -b -k --no-pager | grep -Ei 'failed to boot CPU|CPU[0-9]+: failed to boot'
```


Confirmed result: CPU(s): 10, online: 0-9; the last command prints no errors. This does not increase performance: all ten physical cores provided by the processor were already active.
## 15. Audio, microphone and suspend: successful checks

## Bluetooth: recovering and configuring the original address

If `bluetoothctl` reports `No default controller available`, check whether the controller requires a public Bluetooth address:

```bash
sudo btmgmt config
```

This procedure applies when the output includes:

```text
Unconfigured controller
supported options: public-address
missing options: public-address
```

### 1. Retrieve the original address from Windows

1. Boot Windows.
2. Open **Device Manager → Bluetooth**.
3. Open the properties of the **Qualcomm Bluetooth adapter**, not a paired mouse, speaker or headset.
4. On the **Advanced** tab, look for **Bluetooth Radio Information → Address**.
5. If unavailable, check the **Details** tab for a Bluetooth device address property.

Record the original address. For example:

```text
AA:BB:CC:DD:EE:FF
```

**This is an example only. Do not use it unchanged. Do not substitute the Wi-Fi MAC address.**

### 2. Test the address in Ubuntu

Boot Ubuntu and replace the example below with your adapter’s original address:

```bash
sudo btmgmt --index 0 public-addr AA:BB:CC:DD:EE:FF
```

Check the controller:

```bash
bluetoothctl list
bluetoothctl show
bluetoothctl power on
```

Before making the change persistent, pair a Bluetooth device and verify that it works.

### 3. Make the address persistent

The following commands assume that the guide’s working 10-core Device Tree already exists.

Create a separate copy:

```bash
mkdir -p ~/bluetooth-surface
cd ~/bluetooth-surface

cp /boot/surface-all-peripherals-10core-v2.dtb \
surface-all-peripherals-bluetooth.dtb
```

The `local-bd-address` property stores the six address bytes in reverse order.

For the example address:

```text
Normal notation: AA:BB:CC:DD:EE:FF
Device Tree:     ff ee dd cc bb aa
```

Replace those example bytes with your own address, reversed:

```bash
fdtput -t bx surface-all-peripherals-bluetooth.dtb \
/soc@0/geniqup@ac0000/serial@a98000/bluetooth \
local-bd-address ff ee dd cc bb aa
```

Verify the stored bytes:

```bash
fdtget -t bx surface-all-peripherals-bluetooth.dtb \
/soc@0/geniqup@ac0000/serial@a98000/bluetooth \
local-bd-address
```

Install the new Device Tree:

```bash
sudo install -m 644 surface-all-peripherals-bluetooth.dtb \
/boot/surface-all-peripherals-bluetooth.dtb
```

Create an additional GRUB entry while preserving the previous working entry:

```bash
sudo python3 <<'PY'
from pathlib import Path
import re

s = Path("/etc/grub.d/44_surface_10core_test").read_text()

s, count = re.subn(
    r"menuentry '[^']*'",
    "menuentry 'Ubuntu 7.3.0-31-qcom-x1e - all peripherals'",
    s,
)
if count != 1:
    raise SystemExit("Unexpected GRUB entry: stopped.")

changes = {
    "--id surface-all-peripherals-10core":
        "--id surface-all-peripherals-bluetooth",
    "/boot/surface-all-peripherals-10core-v2.dtb":
        "/boot/surface-all-peripherals-bluetooth.dtb",
}
for old, new in changes.items():
    if s.count(old) != 1:
        raise SystemExit("Unexpected configuration: " + old)
    s = s.replace(old, new, 1)

if "stubble.dtb_override=false" not in s:
    raise SystemExit("Missing Stubble parameter: stopped.")

p = Path("/etc/grub.d/45_surface_bluetooth_test")
p.write_text(s)
p.chmod(0o755)
PY

sudo update-grub
sudo grub-script-check /boot/grub/grub.cfg
```

### 4. Verify after reboot

Select:

**Ubuntu 7.3.0-31-qcom-x1e - all peripherals**

Without running `btmgmt public-addr` again, check:

```bash
bluetoothctl list
bluetoothctl show
```

The controller should appear with its original address. Reconnect the paired device and test it again.

Keep the previous GRUB entry as a fallback. Do not publish your machine-specific Device Tree or original Bluetooth address in this repository.


The speakers and internal microphone were confirmed working. On a later boot the speakers were silent even though Firefox sent audio to the correct sink. After restarting user services and setting mute/volume, audio returned and remained working after reboot. It was not established which step was decisive. The initial microphone report did not require a patch: a targeted recording subsequently worked. The correct source was Internal microphones, not Headset microphone. Do not enable all DMIC switches indiscriminately; the path in use was VA DMIC0/DMIC1.

If the correct output is “Speaker playback” but remains silent, pause playback and run these commands as the graphical user, without sudo:

```bash
systemctl --user restart pipewire pipewire-pulse wireplumber
wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.30
```


Resume playback and check again after reboot. If it remains silent, collect SoundWire logs; do not enable amplifier switches blindly.

```bash
wpctl status
speaker-test -c 2 -t wav -l 1
# Speak for 8 seconds; timeout ends the recording.
timeout --signal=INT 8s pw-record --target=alsa_input.platform-sound.HiFi__Mic__source --rate=48000 --channels=2 /tmp/microfono-interno.wav
pw-play /tmp/microfono-interno.wav
```


Closing the lid entered deep suspend at 01:49:53; opening it resumed the machine at 01:49:57. The user confirmed peripherals still worked. mem_sleep, suspend parameters and services were not changed. This was a short test, not a certification of battery life or stability after hours of suspension.

```bash
sudo journalctl -b --since "10 minutes ago" --no-pager | grep -Ei 'PM: suspend|PM: resume|suspend entry|suspend exit|systemd-sleep|Lid closed|Lid opened'
```


The fwupd-refresh.service error was later resolved by downloading metadata and restarting the service. These commands did not install a firmware update:

```bash
sudo fwupdmgr refresh --force
sudo systemctl restart fwupd-refresh.service
systemctl --failed --no-pager
```


GeoClue is not required for these peripherals. Location services were left disabled at the user’s request; do not restart GeoClue as a general fix.

## 16. Battery: retained settings and limitations


qcom_battmgr detects the battery and AC adapter. UPower reported 43.99 Wh full capacity versus 52.33 Wh design capacity, approximately 84%; this is the controller’s estimate, not a laboratory measurement. Thresholds of 75/80% were exposed, but their actual enforcement was not verified during the session; they are not changed here.

```bash
upower -i /org/freedesktop/UPower/devices/battery_qcom_battmgr_bat
powerprofilesctl get
powerprofilesctl list
cat /sys/power/mem_sleep
cat /sys/devices/system/cpu/cpuidle/current_driver
```


Results: balanced/power-saver profiles with a placeholder PlatformDriver; no CPUFreq policies exposed; psci_idle CPU idle driver and deep suspend. A direct frequency reduction from changing profiles was not demonstrated. TLP and competing power managers were not installed.

Settings applied as the graphical user:

```bash
gsettings set org.gnome.settings-daemon.plugins.power idle-dim true
gsettings set org.gnome.desktop.session idle-delay 300
powerprofilesctl set power-saver
```


The delay controls display blanking after inactivity; by itself it does not configure system suspend. Wi-Fi power saving was already enabled. Short measurements: balanced 7.68 W, power-saver 7.33 W; the difference was inconclusive. HS6209 USB receiver unplugged: 6.27 W, plugged back in: 6.86 W; a plausible contribution rather than a precise measurement of that device alone. The initial 3.5–4.2 W reading was not reproduced in later tests.

**Final mouse preference:** no automatic receiver suspension, to retain immediate response to movement. The power/control=auto test required a click to wake the mouse and was undone. Do not create `80-hs6209-power-save.rules`. Daily energy savings from that test were not measured.

Do not globally disable USB, audio, GPU or regulators. The 99-qcom-ac-refresh.rules file was mentioned during another diagnostic session, but its full contents are unavailable: retain it if present; do not recreate it by guessing.
## 17. Reverted attempts and interpreting logs


ELLX kernel 7.3.0-rc3+ was installed with headers to test its integrated support; it produced a black screen and reboot. It was removed and then purged. The collected logs showed the Ubuntu kernel, not a useful ELLX boot trace, so the exact cause was not established. Do not reinstall it as a required step in this guide.

APT interprets a trailing + in package arguments as an operational suffix. Remaining ELLX package configuration was purged with dpkg using the exact name:

```bash
sudo dpkg --purge 'linux-image-7.3.0-rc3+'
```


The warning that /lib/modules was not empty was expected: it holds other kernels’ modules, which must be retained. Do not delete /lib/modules or use autoremove as a shortcut for this procedure.

The examined call traces concerned generic_edp_panel_probe / panel_edp: the log reported an unknown LGD 0x0780 panel and conservative timings, then boot continued. They were not evidence of a touchpad crash. Initial gen70500_sqe.fw errors were followed by GPU firmware loading from a new location.
## 18. Final boot files and acceptance checks


| File or item | Configuration to retain |
| --- | --- |
| Kernel | /boot/vmlinuz-7.3.0-31-qcom-x1e |
| Custom initramfs | /boot/initrd.img-surface-touchpad-test |
| Complete Device Tree | /boot/surface-all-peripherals-10core-v2.dtb |
| GRUB entry generator | /etc/grub.d/44_surface_10core_test |
| GRUB ID | surface-all-peripherals-10core |
| Title | Ubuntu 7.3.0-31-qcom-x1e all peripherals - 10 core |
| Required parameter | stubble.dtb_override=false |


It was not confirmed that this entry had been made the default. Select it from GRUB. The kernel name in uname does not distinguish these entries; also check the active Device Tree and peripherals.

```bash
uname -r
cat /proc/cmdline
lscpu
rfkill list
nmcli device status
systemctl list-units --all --no-pager 'iptsd*'
wpctl status
cam -l
systemctl --failed --no-pager
sudo journalctl -b -k -p err --no-pager
```


Practical checks: Wi-Fi browsing; touchpad pointer, two-finger scrolling and selection; touchscreen taps; qcam and Meet image; both speakers; microphone recording; lid close/open; battery discharge and AC connection/disconnection. Bluetooth initialized in the logs, but pairing was not documented. Fingerprint reader, IR/face recognition, pen and external docks are not validated by this guide.

Distinguish these log messages: O/E flags indicate custom unsigned modules; “drm panic” during framebuffer registration is not a kernel panic; a panel_edp warning does not prove a crash; initially missing Adreno firmware followed by successful loading does not mean the GPU is absent. SoundWire errors require an actual audio test even if PipeWire lists an output.
## 19. Optional cleanup after testing


The older 7.3.0-15 kernel and ELLX packages were not needed for the final configuration and were removed. Do not remove 7.3.0-31, its headers or the qcom-x1e metapackages. Always inspect the dry run before autoremove:

```bash
uname -r
sudo apt autoremove --dry-run
sudo apt clean
df -h /
```


Modified sources were compressed and verified, then the extracted directory was deleted. The final archive name on the machine is `~/wifi-surface-kernel/linux-qcom-x1e-7.3.0-surface_laptop7.tar.xz`, about 180 MB. To extract it again if the directory does not exist:

```bash
cd ~/wifi-surface-kernel
test ! -e linux-qcom-x1e-7.3.0 && tar -xJf linux-qcom-x1e-7.3.0-surface_laptop7.tar.xz
```


Do not delete test-root, build-qspi or iptsd-source before making a verified backup: they are needed for rebuilding. Do not delete /boot files merely because their names contain “test”. Cleanup reduced used space from about 17 GB to 14 GB, leaving approximately 104 GB available on the Surface filesystem.
## 20. Backing up important files


This guide embeds the original touchpad sources, not the binaries built on the Surface, the actual battery configuration or firmware extracted from Windows. A backup of the working machine is therefore useful. The following command archives essential files and skips missing ones. It does not update software or change boot settings.

```bash
sudo python3 <<'PYCODE'
from pathlib import Path
import tarfile
import os, pwd
home = Path(pwd.getpwnam(os.environ.get("SUDO_USER", "surface")).pw_dir)
items = [
    Path("/boot/initrd.img-surface-touchpad-test"),
    Path("/boot/surface-touchpad-test.dtb"),
    Path("/boot/surface-touchpad-touchscreen-test.dtb"),
    Path("/boot/surface-camera-test.dtb"),
    Path("/boot/surface-all-peripherals-10core-v2.dtb"),
    Path("/etc/grub.d/44_surface_10core_test"),
    home / "cpu-surface",
    home / "wifi-surface-kernel/linux-qcom-x1e-7.3.0-surface_laptop7.tar.xz",
    Path("/etc/grub.d/42_surface_touchscreen_test"),
    Path("/etc/grub.d/43_surface_camera_test"),
    Path("/usr/share/libcamera/ipa/simple/ov02c10.yaml"),
    home / "camera-surface",
    home / "touchpad-surface/touchscreen-test",
    Path("/boot/vmlinuz-7.3.0-31-qcom-x1e"),
    Path("/boot/initrd.img-7.3.0-31-qcom-x1e"),
    Path("/etc/grub.d/41_surface_touchpad_test"),
    Path("/etc/default/grub.d"),
    Path("/etc/udev/rules.d"),
    Path("/etc/iptsd.d"),
    Path("/etc/iptsd.conf"),
    Path("/usr/bin/iptsd"),
    Path("/usr/bin/iptsd-calibrate"),
    Path("/usr/lib/systemd/system/iptsd@.service"),
    home / "touchpad-surface/test-root",
    Path("/lib/firmware/ath12k/WCN7850/hw2.0"),
    Path("/lib/modules/7.3.0-31-qcom-x1e/updates/surface-wifi"),
    home / "touchpad-surface/iptsd-source",
    home / "touchpad-surface/build-qspi",
    home / "touchpad-sorgenti.tar.gz",
    home / "wifi-surface-fix",
]
out = home / "backup-surface-ubuntu-2026-11-01.tar.gz"
if out.exists():
    raise SystemExit("Backup already exists: keep or rename it before continuing")
with tarfile.open(out, "w:gz") as t:
    for item in items:
        if item.exists():
            t.add(item, arcname=str(item).lstrip("/"))
print(out)
PYCODE
sudo chown "$USER:$(id -gn)" ~/backup-surface-ubuntu-2026-11-01.tar.gz
```


Also retain ~/wifi-surface-kernel/linux-qcom-x1e-7.3.0-surface_laptop7.tar.xz, ~/touchpad-surface/x1e-nixos, the extracted firmware .deb and command history. The backup above is not a full disk image: the touchpad initramfs contains the test modules, but rebuilding or updating requires sources and instructions.
## 21. Recovery and updates


**Recovery path:** if the camera causes problems, choose “Ubuntu - Touchpad and touchscreen test”; if the touchscreen causes problems, choose “Ubuntu - Surface touchpad test”; to return to normal Ubuntu boot files, select the standard 7.3.0-31-qcom-x1e entry. These entries use the same kernel release but different Device Trees/initramfs files. Keep working entries.

**First recovery option:** boot the normal Ubuntu 7.3.0-31-qcom-x1e entry from GRUB. Do not delete test files until that entry has been checked. To remove only the additional touchpad entry:

```bash
sudo rm -f /etc/grub.d/41_surface_touchpad_test
sudo update-grub
```


To stop iptsd temporarily, use the actual service name shown by systemctl; during one test it was:

```bash
sudo systemctl stop iptsd@dev-hidraw0.service
```


To undo the Wi-Fi workaround, only if genuinely necessary:

```bash
sudo rm -f /lib/firmware/ath12k/WCN7850/hw2.0/board-2.bin
sudo rm -f /lib/modules/7.3.0-31-qcom-x1e/updates/surface-wifi/ath12k{,_wifi7}.ko
sudo depmod -a 7.3.0-31-qcom-x1e
sudo update-initramfs -u -k 7.3.0-31-qcom-x1e
```


These last commands undo the Wi-Fi fix and do not update the old test initramfs, which retains its own copies of modules and firmware. For a consistent rollback, boot the normal entry. Do not use these commands as routine maintenance on a working system.

**Updates:** custom modules and the touchpad initramfs are specific to kernel 7.3.0-31. DKMS and automatic test-initramfs rebuilding were not configured. Test a future kernel separately: it may integrate the fixes or require rebuilding. Keep the working kernel, sources and recovery entry. initrd.img-surface-touchpad-test does not update itself when the system changes.
## 22. Projects and references


References consulted during the work; online content may change. The observed results, recorded x1e-nixos commit and embedded source files are the basis for this guide.

[Ubuntu Concept Snapdragon X Elite](https://discourse.ubuntu.com/t/ubuntu-concept-snapdragon-x-elite/48800)

[Surface RF-kill workaround](https://lists.openwall.net/linux-kernel/2026/10/06/333)

[x1e-nixos: modules and overlays](https://github.com/scuggo/x1e-nixos)

[Stubble: Device Tree selection](https://github.com/ubuntu/stubble)

[iptsd fork used during testing](https://github.com/alex-lentz/iptsd)

[Community Surface Laptop 7 ARM guide](https://github.com/bryce-hoehn/linux-surface-laptop-7)

[ELLX archive — reverted attempt](https://public.hgci.org/software/ELLX/)

[ELLX sources](https://github.com/ProgrammerIn-wonderland/ELLX-Kernel)
