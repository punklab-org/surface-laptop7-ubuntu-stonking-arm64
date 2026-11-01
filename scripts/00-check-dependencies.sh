#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
check_kernel

cat /etc/os-release
uname -r
tr '\0' '\n' < /sys/firmware/devicetree/base/compatible
sudo dmidecode -t processor
mokutil --sb-state
lsblk -f
apt-cache policy linux-image-qcom-x1e linux-headers-qcom-x1e
sudo apt update
sudo apt install build-essential git curl zstd xz-utils patch python3 libelf-dev libssl-dev device-tree-compiler dracut-core linux-headers-$(uname -r)
test "$(uname -r)" = "7.3.0-31-qcom-x1e"
