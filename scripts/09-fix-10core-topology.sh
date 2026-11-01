#!/usr/bin/env bash
set -euo pipefail
source "$(dirname -- "${BASH_SOURCE[0]}")/common.sh"
check_kernel

sudo dmidecode -t processor | grep -q 'X1P64100' || {
    echo "This workaround is only for the 10-core X1P64100 processor" >&2; exit 1;
}
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
if grep -Ei 'cpu|phandle|cooling|reference' verifica-v2.log; then
    echo "Reference warnings: stop and check before installation" >&2; exit 1
fi
sudo install -m 644 surface-10core-v2.dtb /boot/surface-all-peripherals-10core-v2.dtb
create_entry 44_surface_10core_test "Ubuntu 7.3.0-31-qcom-x1e all peripherals - 10 core" surface-all-peripherals-10core /boot/surface-all-peripherals-10core-v2.dtb
echo "Reboot using the 10-core entry and verify online CPUs 0-9."
