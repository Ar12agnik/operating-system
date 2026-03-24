#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="${ROOT_DIR}/build"
ROOTFS_DIR="${BUILD_DIR}/rootfs"
MOUNT_DIR="${BUILD_DIR}/mnt"
IMAGE="${BUILD_DIR}/os.img"
IMAGE_SIZE_MB="2048"
DEBIAN_RELEASE="bookworm"
ARCH="amd64"

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "Missing required command: $1" >&2
    exit 1
  fi
}

ensure_prereqs() {
  local cmds=(debootstrap parted mkfs.ext4 grub-install rsync)
  for cmd in "${cmds[@]}"; do
    require_cmd "$cmd"
  done
}

build_rootfs() {
  echo "[1/4] Building root filesystem..."
  sudo mkdir -p "${ROOTFS_DIR}"
  if [ ! -f "${ROOTFS_DIR}/etc/debian_version" ]; then
    sudo debootstrap --arch="${ARCH}" "${DEBIAN_RELEASE}" "${ROOTFS_DIR}" http://deb.debian.org/debian
  else
    echo "Rootfs already exists, skipping debootstrap."
  fi

  echo "basic-os" | sudo tee "${ROOTFS_DIR}/etc/hostname" >/dev/null
  sudo tee "${ROOTFS_DIR}/etc/fstab" >/dev/null <<FSTAB
/dev/sda1 / ext4 defaults 0 1
FSTAB

  sudo tee "${ROOTFS_DIR}/etc/network/interfaces" >/dev/null <<NET
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
NET
}

create_image() {
  echo "[2/4] Creating disk image..."
  mkdir -p "${BUILD_DIR}" "${MOUNT_DIR}"
  rm -f "${IMAGE}"

  truncate -s "${IMAGE_SIZE_MB}M" "${IMAGE}"
  parted -s "${IMAGE}" mklabel msdos
  parted -s "${IMAGE}" mkpart primary ext4 1MiB 100%

  local loopdev
  loopdev="$(sudo losetup --show -fP "${IMAGE}")"
  trap 'sudo losetup -d "${loopdev}" >/dev/null 2>&1 || true' EXIT

  sudo mkfs.ext4 "${loopdev}p1"
  sudo mount "${loopdev}p1" "${MOUNT_DIR}"

  echo "[3/4] Copying rootfs and installing GRUB..."
  sudo rsync -aHAX --numeric-ids "${ROOTFS_DIR}/" "${MOUNT_DIR}/"

  local kernel
  kernel="$(ls -1 /boot/vmlinuz-* 2>/dev/null | head -n1 || true)"
  if [ -z "${kernel}" ]; then
    echo "No host kernel found in /boot/vmlinuz-*" >&2
    sudo umount "${MOUNT_DIR}" || true
    exit 1
  fi

  sudo cp "${kernel}" "${MOUNT_DIR}/boot/vmlinuz"

  if [ -d "${ROOT_DIR}/configs" ]; then
    sudo mkdir -p "${MOUNT_DIR}/boot/grub"
    sudo cp "${ROOT_DIR}/configs/grub.cfg" "${MOUNT_DIR}/boot/grub/grub.cfg"
  fi

  sudo grub-install --target=i386-pc --boot-directory="${MOUNT_DIR}/boot" "${loopdev}"

  sudo umount "${MOUNT_DIR}"
  sudo losetup -d "${loopdev}"
  trap - EXIT

  echo "[4/4] Done. Image created at ${IMAGE}"
}

main() {
  ensure_prereqs
  build_rootfs
  create_image
}

main "$@"
