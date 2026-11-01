#!/usr/bin/env bash
# Run as a regular user; privileged operations use sudo.
set -euo pipefail
BUNDLE_ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
KVER=7.3.0-31-qcom-x1e
check_kernel() {
    [ "$(id -u)" != 0 ] || { echo "Run the script without sudo" >&2; exit 1; }
    [ "$(uname -r)" = "$KVER" ] || { echo "Required kernel: $KVER" >&2; exit 1; }
    tr '\0' '\n' < /sys/firmware/devicetree/base/compatible | grep -qx microsoft,romulus13 || {
        echo "Unsupported model" >&2; exit 1;
    }
}
create_entry() {
    sudo python3 "$BUNDLE_ROOT/tools/create_grub_entry.py" "$@"
    sudo update-grub
    sudo grub-script-check /boot/grub/grub.cfg
}
