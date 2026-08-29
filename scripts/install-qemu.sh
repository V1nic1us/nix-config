#!/usr/bin/env bash
set -euo pipefail

disk=/dev/vda
repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)

if [[ ${EUID} -ne 0 ]]; then
  printf 'Execute como root: sudo %s --yes\n' "$0" >&2
  exit 1
fi

if [[ ${1:-} != "--yes" ]]; then
  printf 'Este comando APAGA %s. Execute novamente com --yes para confirmar.\n' "$disk" >&2
  exit 1
fi

if [[ ! -b "$disk" ]]; then
  printf 'Disco da VM não encontrado: %s\n' "$disk" >&2
  exit 1
fi

loadkeys br-abnt2 || true

if mountpoint -q /mnt; then
  umount -R /mnt
fi

parted --script --align optimal "$disk" mklabel msdos
parted --script --align optimal "$disk" mkpart primary ext4 1MiB 100%
partprobe "$disk"
udevadm settle

mkfs.ext4 -F -L nixos "${disk}1"
mount "${disk}1" /mnt

nixos-install --no-root-passwd --flake "${repo_dir}#qemu-install"
