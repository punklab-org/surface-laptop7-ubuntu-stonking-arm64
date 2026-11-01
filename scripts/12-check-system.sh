#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
check_kernel

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
