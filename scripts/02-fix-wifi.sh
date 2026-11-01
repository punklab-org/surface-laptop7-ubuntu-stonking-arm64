#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
check_kernel

sudo apt install curl zstd build-essential libelf-dev libssl-dev linux-headers-$(uname -r)
mkdir -p ~/wifi-surface-fix
cd ~/wifi-surface-fix
zstd -d -f /lib/firmware/ath12k/WCN7850/hw2.0/board-2.bin.zst -o board-2.bin
cp "$BUNDLE_ROOT/tools/ath12k-bdencoder" ./ath12k-bdencoder
python3 ath12k-bdencoder -e board-2.bin
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
mkdir -p ~/wifi-surface-kernel
cd ~/wifi-surface-kernel
if [ ! -d linux-qcom-x1e-7.3.0 ]; then
    if [ -f linux-qcom-x1e-7.3.0-surface_laptop7.tar.xz ]; then
        tar -xJf linux-qcom-x1e-7.3.0-surface_laptop7.tar.xz
    else
        apt-get source --only-source linux-qcom-x1e=7.3.0-31.31
    fi
fi
cd linux-qcom-x1e-7.3.0
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
make -C /lib/modules/$(uname -r)/build M="$PWD/drivers/net/wireless/ath/ath12k" -j2 modules

sudo install -D -m 644 drivers/net/wireless/ath/ath12k/ath12k.ko /lib/modules/7.3.0-31-qcom-x1e/updates/surface-wifi/ath12k.ko
sudo install -D -m 644 drivers/net/wireless/ath/ath12k/wifi7/ath12k_wifi7.ko /lib/modules/7.3.0-31-qcom-x1e/updates/surface-wifi/ath12k_wifi7.ko
sudo depmod -a 7.3.0-31-qcom-x1e
sudo update-initramfs -u -k 7.3.0-31-qcom-x1e
echo "Reboot, then check rfkill and the Wi-Fi connection."
