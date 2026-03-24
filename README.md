# Minimal Linux-Based Operating System

This repository contains a **basic Linux-based operating system build scaffold** that creates:

1. A minimal Debian root filesystem (via `debootstrap`)
2. A bootable disk image
3. A GRUB bootloader configuration
4. An optional QEMU run target

> This is intentionally simple and educational, not production-hardened.

## Project structure

- `scripts/build-os.sh` — end-to-end build script (rootfs + image + GRUB)
- `configs/grub.cfg` — GRUB menu for booting the generated Linux kernel
- `Makefile` — convenience targets

## Prerequisites (Ubuntu/Debian host)

Install required tools:

```bash
sudo apt update
sudo apt install -y debootstrap grub-pc-bin xorriso mtools qemu-system-x86 parted dosfstools rsync
```

## Build the OS image

```bash
make build
```

Artifacts are written to `build/`:

- `build/rootfs/` — generated root filesystem
- `build/os.img` — bootable disk image

## Run in QEMU

```bash
make run
```

## Clean

```bash
make clean
```

## Notes

- The build script supports x86_64 and uses Debian stable packages.
- A host Linux kernel (`/boot/vmlinuz-*`) is copied into the image as a simple bootstrap approach.
- For a fully self-contained distro, replace host-kernel copy with a reproducible kernel build step.
