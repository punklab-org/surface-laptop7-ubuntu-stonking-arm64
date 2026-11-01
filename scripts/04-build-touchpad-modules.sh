#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
check_kernel

mkdir -p ~/touchpad-surface/archivio
cp -a "$BUNDLE_ROOT/kernel" ~/touchpad-surface/archivio/
cp "$BUNDLE_ROOT/patches/spi-geni-qcom-ubuntu-7.3.0-31.patch" ~/touchpad-surface/archivio/
[ -d "$HOME/wifi-surface-kernel/linux-qcom-x1e-7.3.0" ] || {
    echo "Prepare the kernel sources using script 02 first" >&2; exit 1;
}
[ ! -d "$HOME/touchpad-surface/build-qspi" ] || {
    echo "build-qspi already exists: retain or rename it; do not apply patches twice" >&2; exit 1;
}
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
