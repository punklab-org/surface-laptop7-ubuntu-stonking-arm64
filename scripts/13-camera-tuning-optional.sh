#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
check_kernel

sudo install -d -m 755 /usr/share/libcamera/ipa/simple
if [ -f /usr/share/libcamera/ipa/simple/ov02c10.yaml ] && \
   [ ! -f /usr/share/libcamera/ipa/simple/ov02c10.yaml.pre-tuning ]; then
    sudo cp -a /usr/share/libcamera/ipa/simple/ov02c10.yaml /usr/share/libcamera/ipa/simple/ov02c10.yaml.pre-tuning
fi
sudo install -m 644 "$BUNDLE_ROOT/config/ov02c10.yaml" /usr/share/libcamera/ipa/simple/ov02c10.yaml
echo "Reopen qcam or Meet to check the colour profile."
