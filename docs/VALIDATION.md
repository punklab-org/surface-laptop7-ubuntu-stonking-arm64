# Validation and scope

Prepared on 1 November 2026.

## Checks performed for this English package

- Shell syntax checked with `bash -n` for all 14 step scripts and `common.sh`.
- Python syntax checked in the GRUB generator and all embedded Python script blocks.
- Shell and embedded Python syntax checked for all 46 command blocks in the English HTML guide.
- Consolidated SPI patch checked using `patch --dry-run --batch --fuzz=0 -p1` against the original source snapshot supplied during the session.
- GPI patch checked against the same source snapshot with `--fuzz=0`; only the documented line offsets were required.
- Markdown links and HTML contents links checked against packaged targets; archive integrity and SHA-256 manifest checked.
- Checked for the original machine UUID and unintended kernel modules, firmware, generated DTBs or private keys.

## What these checks do not establish

The original fixes were exercised by the user on the Surface and enabled the documented peripherals. The assembled English scripts were **not run end to end on a clean ARM64 installation**. Syntax checks do not establish runtime compatibility.

The historical iptsd revision was not recorded. The bundled snapshot has a recorded commit in `SOURCES.json` and must be tested on the device. APT and Meson dependencies require network access; kernel packages and proprietary firmware are external.

The guide describes only the verified model and kernel release. It does not certify other Surface models, future kernels, IR/Windows Hello, fingerprint recognition, a pen, Bluetooth pairing or external docks. Suspend was tested, but long-duration stability and battery endurance were not certified.
