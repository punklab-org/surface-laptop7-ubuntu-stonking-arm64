#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
check_kernel

sudo apt install libgl1-mesa-dri libegl-mesa0 mesa-vulkan-drivers mesa-utils vulkan-tools linux-firmware-qualcomm-graphics
glxinfo -B
vulkaninfo --summary
