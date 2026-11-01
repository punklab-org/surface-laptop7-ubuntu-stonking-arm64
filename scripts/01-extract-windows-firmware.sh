#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
check_kernel

sudo apt install qcom-firmware-extract
sudo qcom-firmware-extract
# After completion, check the Romulus-specific package:
dpkg-query -W 'qcom-x1e-firmware-extracted*' 2>/dev/null
echo "Keep the firmware .deb and reboot before continuing."
