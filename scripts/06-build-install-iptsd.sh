#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
check_kernel

sudo apt install git build-essential meson ninja-build cmake pkg-config libcli11-dev libeigen3-dev libfmt-dev libinih-dev libgsl-dev libspdlog-dev
cd ~/touchpad-surface
[ ! -e iptsd-source ] || { echo "iptsd-source already exists: do not overwrite it" >&2; exit 1; }
cp -a "$BUNDLE_ROOT/vendor/iptsd" iptsd-source
cd iptsd-source
meson setup build --buildtype=release -Dwerror=false -Db_lto=false -Ddebug_tools=calibrate -Dcpp_args=-march=armv8-a
meson compile -C build -j 2
./build/src/iptsd --help
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
gsettings set org.gnome.desktop.peripherals.touchpad two-finger-scrolling-enabled true
gsettings set org.gnome.desktop.peripherals.touchpad edge-scrolling-enabled false
gsettings set org.gnome.desktop.peripherals.touchpad tap-to-click true
gsettings set org.gnome.desktop.peripherals.touchpad tap-and-drag true
