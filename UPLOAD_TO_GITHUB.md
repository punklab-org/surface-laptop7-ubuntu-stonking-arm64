# Uploading this project to GitHub

Suggested repository name: **surface-laptop7-ubuntu-stonking-arm64**

Suggested description:

> Post-installation guide and scripts for Ubuntu 26.10 ARM64 on Surface Laptop 7: Wi-Fi, Adreno GPU, touchpad, touchscreen, webcam, audio and Snapdragon X Plus 10-core configuration.

1. Extract the ZIP and open the directory containing `README.md`.
2. Review `DISCLAIMER.md`, `THIRD_PARTY.md` and the files before publishing. Do not add proprietary firmware or private backups.
3. Create an empty GitHub repository. Leave the automatic README, .gitignore and licence options unchecked; this package includes its README and .gitignore. Retain upstream licences and settle the licence scope for newly written material separately.
4. Upload **the contents of the extracted directory**, not the ZIP and not an additional enclosing directory. `README.md` must be at the repository root. Git is convenient for preserving the directory structure and all vendor files.

From inside the extracted project directory:

```bash
git init
git add .
git status
# Review the staged file list before committing.
git commit -m "Add English Ubuntu Stonking post-installation guide for Surface Laptop 7"
git branch -M main
```

After creating the empty repository, replace YOUR_REPOSITORY_URL below with its real HTTPS or SSH URL, then run:

```bash
git remote add origin YOUR_REPOSITORY_URL
git push -u origin main
```

Do not run the placeholder URL unchanged. These instructions do not publish anything automatically. If you already uploaded the Italian package, update that working checkout instead of creating a nested copy; remove obsolete Italian script filenames only after verifying that no documentation still points to them.
