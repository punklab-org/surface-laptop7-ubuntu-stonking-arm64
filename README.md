# Ubuntu 26.10 ARM64 on Surface Laptop 7

Post-installation guide, source files and step-by-step scripts for **Microsoft Surface Laptop 7 13.8-inch with a 10-core Snapdragon X Plus X1P-64-100**, using Ubuntu 26.10 `stonking-desktop-arm64-x1e` and kernel **7.3.0-31-qcom-x1e / 7.3.0-31.31**.

**Language: English.** Technical paths and identifiers retain the names used in the tested configuration.

## Notice and disclaimer

This material is provided **“as is”, without warranties**, and is intended only for the hardware and software configuration listed above. It modifies drivers, firmware files, the Device Tree and boot configuration. Incorrect or incompatible changes may cause data loss, boot failure, malfunction or damage. Back up your data and prepare recovery media before use.

**Use this guide and its scripts at your own risk. To the extent permitted by applicable law, the author and contributors disclaim liability for direct or indirect damage, data loss or other problems arising from their use.** This notice does not override applicable law or third-party licences. Read the [full disclaimer](DISCLAIMER.md).

The underlying fixes were tested on one Surface during 31 October–1 November 2026. **The assembled scripts are new: syntax and patch application were checked, but the scripts have not been tested end to end on a fresh ARM64 installation.** This is not a universal or one-click installer. Stop at each checkpoint and reboot where required.

## Surface Laptop 7 — Snapdragon X Plus

| Device / Feature | Status | Notes |
|---|:---:|---|
| Snapdragon X Plus CPU | ✅ Working | All 10 cores online |
| Adreno X1-85 GPU | ✅ Working | OpenGL hardware acceleration and Vulkan |
| Wi-Fi | ✅ Working | Connection and web browsing tested |
| Bluetooth | ✅ Working | External speaker connected; controller available after reboot |
| Built-in keyboard | ✅ Working | Basic typing tested |
| Touchpad | ✅ Working | Pointer movement, two-finger scrolling and selection |
| Touchscreen | ✅ Working | Touch input tested |
| RGB webcam | ✅ Working | qcam and Google Meet; noise in low light |
| Built-in speakers | ✅ Working | Audio works after reboot |
| Built-in microphone | ✅ Working | Recording tested |
| Battery and AC adapter | ✅ Working | Charging/discharging status detected |
| Suspend and resume | ✅ Working | Suspend and wake-up tested |
| USB wireless mouse | ✅ Working | Immediate response to movement |
| IR camera / face recognition | ⚪ Not tested | Functionality not verified |
| External docks and monitors | ⚪ Not tested | Functionality not verified |

**Tested configuration:** Surface Laptop 7 13.8-inch, Snapdragon X Plus
X1P-64-100, Ubuntu 26.10 ARM64, kernel `7.3.0-31-qcom-x1e`,
custom modules and Device Tree.

**Boot entry:** `Ubuntu 7.3.0-31-qcom-x1e - all peripherals`

“Working” refers to the tests performed on this configuration, not a
guarantee of compatibility with other hardware or kernel versions.

## Documentation

- [Complete post-installation guide](docs/GUIDE_EN.md)
- [Printable HTML guide with embedded files](docs/post-install-guide.html): download and open locally in a browser.
- [Validation report and limitations](docs/VALIDATION.md)
- [Source provenance and third-party licences](THIRD_PARTY.md)
- [Source revisions and hashes](SOURCES.json)

## Requirements

- The exact model and kernel above. **Do not apply the 10-core fix to a 12-core processor.**
- USB Ethernet initially; a USB keyboard/mouse while the touchpad is unavailable.
- Windows still available for firmware extraction, or your own saved model-specific firmware .deb.
- Secure Boot was disabled in the tested setup. The custom modules are unsigned.
- Approximately 4 GB free for source and build work.
- For automatic GRUB generation, `/boot` must be on the same ext4 root filesystem. Separate `/boot` layouts require manual adaptation.
- Enable source indexes for the relevant Ubuntu Concept repository before step 02 (`Types: deb deb-src` in the correct Deb822 source, or Software & Updates). Do not disable signature checks.

If the exact kernel or source version is no longer available, stop and adapt the patches instead of blindly substituting another version. The scripts do not add the Concept repository or install/downgrade the running kernel.

## Installation sequence

Read the full guide and each script first. Run scripts **as the graphical-session user, without sudo before bash**; individual privileged operations invoke sudo themselves.

Example, from the repository root:

```bash
bash scripts/00-check-dependencies.sh
```

| Step | Script | Checkpoint before proceeding |
|---|---|---|
| 00 | `00-check-dependencies.sh` | Exact hardware and kernel confirmed; dependencies installed |
| 01 | `01-extract-windows-firmware.sh` | Keep the generated firmware .deb; reboot |
| 02 | `02-fix-wifi.sh` | Reboot; rfkill unblocked and Wi-Fi can connect |
| 03 | `03-check-adreno.sh` | Adreno renderer and hardware acceleration detected |
| 04 | `04-build-touchpad-modules.sh` | All three modules compile successfully |
| 05 | `05-configure-touchpad-boot.sh` | Reboot using “Ubuntu - Surface touchpad test”; pointer works |
| 06 | `06-build-install-iptsd.sh` | iptsd active; two-finger scrolling and selection work |
| 07 | `07-enable-touchscreen.sh` | Reboot using the touchscreen entry; touch works |
| 08 | `08-enable-camera.sh` | Reboot using “all peripherals”; verify with qcam |
| 09 | `09-fix-10core-topology.sh` | Reboot using “all peripherals - 10 core”; CPUs online 0–9 |
| 10 | `10-restore-audio.sh` | Only if audio is silent; check Speaker playback |
| 11 | `11-battery-settings-optional.sh` | Optional dimming, 5-minute display timeout, power-saver profile |
| 12 | `12-check-system.sh` | Check all peripherals and logs |
| 13 | `13-camera-tuning-optional.sh` | Optional tested colour profile |

Errors stop the scripts. Keep the previous working GRUB entry. No script changes the default boot entry. Do not force live reloading of Wi-Fi or GPI/SPI modules to test the changes.

Existing work directories are not disposable: some steps deliberately stop if a previous build exists. Preserve or rename it and inspect the situation rather than deleting it blindly. Settings and commands for an already working installation should not be applied twice.

To connect to Wi-Fi:

```bash
nmcli --ask device wifi connect "YOUR_NETWORK_NAME"
```

For Firefox/Meet: close qcam, open `about:config`, set `media.webrtc.camera.allow-pipewire=true` if the preference exists, restart Firefox and grant camera access. Select the integrated front camera and Internal microphones.

## Final boot configuration

| Item | Value |
|---|---|
| Kernel | `7.3.0-31-qcom-x1e` |
| Custom initramfs | `/boot/initrd.img-surface-touchpad-test` |
| Device Tree | `/boot/surface-all-peripherals-10core-v2.dtb` |
| GRUB generator | `/etc/grub.d/44_surface_10core_test` |
| GRUB ID | `surface-all-peripherals-10core` |
| GRUB title | `Ubuntu 7.3.0-31-qcom-x1e all peripherals - 10 core` |
| Required parameter | `stubble.dtb_override=false` |

The automatic GRUB helper detects your root UUID. Manual examples in the guide use `ROOT_FILESYSTEM_UUID`; replace that placeholder before using them. Do not remove the custom initramfs or Device Tree merely because their names contain “test”.

## External files and network requirements

The ZIP is **not an offline installer**. It does not include:

- Proprietary firmware. Obtain it from your Windows installation or your own saved `qcom-x1e-firmware-extracted-x1e80100-microsoft-romulus` .deb. Do not publish it here.
- Kernel image/header packages or the complete kernel source. Obtain the exact version through APT or your saved packages.
- The personal `linux-qcom-x1e-7.3.0-surface_laptop7.tar.xz` archive (about 180 MB). It is optional if APT can retrieve the exact source and is ignored by Git.
- APT packages and any dependencies downloaded by Meson.

`vendor/iptsd/` is a pinned, identified snapshot. Its commit is in `SOURCES.json`; the exact revision of the originally tested build was not recorded. Preserve its licence and validate the resulting build on your device.

## Tested features and limits

Wi-Fi, Adreno graphics, touchpad, touchscreen, RGB webcam, microphone, speakers and suspend/resume were tested in the documented configuration. IR/Windows Hello, fingerprints, pen input, Bluetooth pairing and external docks were not validated.

Low-light webcam noise remains. No battery-life guarantee is made: short balanced/power-saver measurements were inconclusive. The USB receiver autosuspend rule was not retained because the user preferred immediate wake on mouse movement.

Custom modules are tied to this kernel. DKMS and automatic custom-initramfs rebuilding are not configured. Test future kernels separately and keep a working fallback.

## Uploading to GitHub

Extract this ZIP and upload the **contents** of the directory containing this README. Do not upload the ZIP as the project and do not add an extra nested project directory. See [UPLOAD_TO_GITHUB.md](UPLOAD_TO_GITHUB.md) for commands.

Review third-party licence terms before public redistribution. Do not add firmware, private logs, keys or machine backups to the repository. Retain the supplied `.gitignore`.
