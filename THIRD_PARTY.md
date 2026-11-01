# Third-party sources and licences

Keep the original copyright notices, SPDX identifiers and licence files. This project does not replace or relicense third-party components.

| Component | Source and provenance |
|---|---|
| `kernel/modules/spi-hid/`, `kernel/modules/qcom-qspi/`, touchpad overlay | [scuggo/x1e-nixos](https://github.com/scuggo/x1e-nixos), session commit `ca7db709ee29ecdd3c00fec679febdfb2ebfaa32`; snapshot supplied during the original session. SPI-HID declares GPL-2.0. Consult each source file and the upstream project for its terms. |
| `patches/spi-geni-qcom-ubuntu-7.3.0-31.patch` | Consolidated adaptation for the Ubuntu GPL driver source. Patch application checked; not rebuilt on ARM64 in this packaging environment. |
| Camera patch, overlay and YAML | [bryce-hoehn/linux-surface-laptop-7](https://github.com/bryce-hoehn/linux-surface-laptop-7), snapshot fetched on 1 November 2026. The overlay is derived from the camera patch. Keep original attribution. Check upstream licence terms before public redistribution: absence of an explicit licence in a file is not, by itself, permission to redistribute it. |
| `vendor/iptsd/` | [alex-lentz/iptsd](https://github.com/alex-lentz/iptsd), with the original licence and attribution retained. The bundled commit is recorded in `SOURCES.json`. This is an identified source snapshot, not the unrecorded historical revision of the binary tested during the original session. |
| `tools/ath12k-bdencoder` | [qca/qca-swiss-army-knife](https://github.com/qca/qca-swiss-army-knife); retain the permission notice and copyright in the source. |

No proprietary firmware, machine Device Tree dump, kernel binary, password, key or Windows-extracted firmware is included. Obtain the full kernel source and model-specific firmware separately.

No new blanket licence is applied to third-party code. The repository owner may choose separate licensing for newly written documentation and scripts without overriding upstream terms. The disclaimer is not a software licence.
