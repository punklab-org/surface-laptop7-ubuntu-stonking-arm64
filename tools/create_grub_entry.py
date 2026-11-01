#!/usr/bin/env python3
from pathlib import Path
import subprocess as sp, sys, re
if len(sys.argv) != 5:
    raise SystemExit("Usage: output-name title id dtb")
name,title,ident,dtb=sys.argv[1:]
if not re.fullmatch(r"4[1-4]_surface_[a-z0-9_]+",name):raise SystemExit("Unexpected filename")
if not re.fullmatch(r"[A-Za-z0-9 -]+",title):raise SystemExit("Unexpected title")
if not re.fullmatch(r"[a-z0-9-]+",ident):raise SystemExit("Unexpected ID")
if not re.fullmatch(r"/boot/[a-zA-Z0-9_.-]+[.]dtb",dtb):raise SystemExit("Unexpected DTB path")
root=sp.check_output(["findmnt","-no","UUID","/"],text=True).strip()
if not re.fullmatch(r"[a-fA-F0-9-]+",root):raise SystemExit("Unsupported root UUID")
boot=sp.check_output(["findmnt","-no","TARGET","-T","/boot"],text=True).strip()
if boot != "/":raise SystemExit("Separate /boot partition: adapt the GRUB entry manually")
for item in [dtb,"/boot/vmlinuz-7.3.0-31-qcom-x1e","/boot/initrd.img-surface-touchpad-test"]:
    if not Path(item).is_file():raise SystemExit("Missing file: "+item)
p=Path("/etc/grub.d")/name
s=f"""#!/bin/sh
exec tail -n +3 $0
menuentry '{title}' --id {ident} {{
    insmod part_gpt
    insmod ext2
    search --no-floppy --fs-uuid --set=root {root}
    linux /boot/vmlinuz-7.3.0-31-qcom-x1e root=UUID={root} ro clk_ignore_unused pd_ignore_unused cma=128M efi=noruntime console=tty0 stubble.dtb_override=false
    devicetree {dtb}
    initrd /boot/initrd.img-surface-touchpad-test
}}
"""
if p.exists():
    backup=p.with_suffix(".pre-guide")
    if not backup.exists():
        backup.write_bytes(p.read_bytes())
        backup.chmod(0o644)
p.write_text(s);p.chmod(0o755)
print(p)
