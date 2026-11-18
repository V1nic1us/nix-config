#!/usr/bin/env bash
set -euo pipefail

# Execute a partir da ISO minimal do NixOS, em modo UEFI.
repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
export NIX_CONFIG="experimental-features = nix-command flakes"

if [[ ${EUID} -ne 0 ]]; then
  printf 'Execute como root: sudo bash install.sh\n' >&2
  exit 1
fi
if [[ ! -d /sys/firmware/efi ]]; then
  printf 'Esta instalação exige inicialização UEFI. Reinicie a ISO em modo UEFI.\n' >&2
  exit 1
fi
for tool in lsblk parted partprobe udevadm mkfs.fat mkfs.ext4 mount mountpoint findmnt nix nixos-generate-config nixos-install nixos-enter mkswap swapon; do
  command -v "$tool" >/dev/null || { printf 'Comando ausente: %s\n' "$tool" >&2; exit 1; }
done
if ! mountpoint -q /iso; then
  printf 'Execute este instalador pela ISO minimal do NixOS.\n' >&2
  exit 1
fi
if mountpoint -q /mnt; then
  printf '/mnt já está montado; desmonte a instalação anterior.\n' >&2
  exit 1
fi

mapfile -t disks < <(lsblk -dnpo NAME,TYPE,RM,TRAN | awk '$2 == "disk" && $3 == "0" && $4 != "usb" && $1 !~ /^\/dev\/(zram|ram|nbd|loop)/ {print $1}')
if (( ${#disks[@]} == 0 )); then
  printf 'Nenhum SSD ou HD interno foi encontrado.\n' >&2
  exit 1
fi
printf 'Discos encontrados:\n'
for index in "${!disks[@]}"; do
  printf '%s) %s  %s\n' "$((index + 1))" "${disks[index]}" "$(lsblk -dnro SIZE,MODEL -- "${disks[index]}")"
done
if (( ${#disks[@]} == 1 )); then
  disk=${disks[0]}
  printf 'Disco selecionado automaticamente: %s\n' "$disk"
else
  read -r -p 'Número do disco para instalar o NixOS: ' disk_choice
  if [[ ! $disk_choice =~ ^[1-9][0-9]*$ ]] || (( 10#$disk_choice > ${#disks[@]} )); then
    printf 'Escolha um número da lista.\n' >&2
    exit 1
  fi
  disk=${disks[10#$disk_choice - 1]}
fi

mapfile -t disk_devices < <(lsblk -nrpo NAME -- "$disk")
for device in "${disk_devices[@]}"; do
  if findmnt -rn -S "$device" >/dev/null || swapon --noheadings --raw --show=NAME | grep -Fxq "$device"; then
    printf 'O dispositivo %s está montado ou em uso como swap. Desmonte-o antes de instalar.\n' "$device" >&2
    exit 1
  fi
done

read -r -p 'Swap em GiB [16] (0 para desativar): ' swap_gib
swap_gib=${swap_gib:-16}
if [[ ! $swap_gib =~ ^(0|[1-9][0-9]*)$ ]] || (( swap_gib > 1024 )); then
  printf 'Informe um número inteiro de 0 a 1024 GiB.\n' >&2
  exit 1
fi
disk_bytes=$(lsblk -bdnro SIZE -- "$disk")
if (( disk_bytes < (swap_gib + 17) * 1024 * 1024 * 1024 + 2 * 1024 * 1024 )); then
  printf 'O disco precisa ter pelo menos swap + 17 GiB e uma pequena margem para as partições.\n' >&2
  exit 1
fi

printf '\nATENÇÃO: TODAS as partições e dados de %s serão apagados.\n' "$disk"
printf 'Será criada uma partição EFI FAT32 de 1 GiB e outra para o NixOS. Swap: %s GiB.\n' "$swap_gib"
read -r -p 'Digite APAGAR para iniciar: ' confirmation
[[ $confirmation == APAGAR ]] || { printf 'Instalação cancelada.\n'; exit 1; }

parted -s "$disk" mklabel gpt
parted -s "$disk" mkpart ESP fat32 1MiB 1025MiB
parted -s "$disk" set 1 esp on
parted -s "$disk" mkpart nixos ext4 1025MiB 100%
partprobe "$disk"
udevadm settle
esp_part=$(lsblk -nrpo NAME,PARTN -- "$disk" | awk '$2 == 1 {print $1; exit}')
root_part=$(lsblk -nrpo NAME,PARTN -- "$disk" | awk '$2 == 2 {print $1; exit}')
if [[ ! -b $esp_part || ! -b $root_part ]]; then
  printf 'Não foi possível localizar as novas partições de %s.\n' "$disk" >&2
  exit 1
fi
mkfs.fat -F 32 "$esp_part"
mkfs.ext4 -F -- "$root_part"
mount -t ext4 -- "$root_part" /mnt
mkdir -p /mnt/boot
mount -t vfat -- "$esp_part" /mnt/boot

if (( swap_gib > 0 )); then
  dd if=/dev/zero of=/mnt/swapfile bs=1M count=$((swap_gib * 1024)) status=progress
  chmod 600 /mnt/swapfile
  mkswap /mnt/swapfile
  swapon /mnt/swapfile
fi

nixos-generate-config --root /mnt
mkdir -p /mnt/etc/nixos/nix-config
cp -a "$repo_dir"/flake.nix "$repo_dir"/home.nix "$repo_dir"/modules "$repo_dir"/assets /mnt/etc/nixos/nix-config/
if [[ -f $repo_dir/flake.lock ]]; then
  cp -a "$repo_dir/flake.lock" /mnt/etc/nixos/nix-config/
fi

cat > /mnt/etc/nixos/flake.nix <<'EOF'
{
  description = "NixOS portátil de viniv";
  inputs.nix-config.url = "path:./nix-config";
  inputs.nixpkgs.follows = "nix-config/nixpkgs";
  outputs = { self, nixpkgs, nix-config, ... }: {
    nixosConfigurations.portable = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./hardware-configuration.nix
        ./configuration.nix
        nix-config.nixosModules.portable
      ];
    };
  };
}
EOF

swap_config=''
if (( swap_gib > 0 )); then
  swap_config='swapDevices = [ { device = "/swapfile"; } ];'
fi
cat > /mnt/etc/nixos/configuration.nix <<EOF
{ ... }:
{
  networking.hostName = "nixos-viniv";
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  users.users.root.hashedPassword = "!";
  $swap_config
}
EOF
chmod 600 /mnt/etc/nixos/configuration.nix

nix flake lock /mnt/etc/nixos
install_log=/mnt/nix-config-install.log
printf 'Instalando o NixOS. Registro: %s\n' "$install_log"
if ! nixos-install --flake /mnt/etc/nixos#portable --no-root-passwd --no-channel-copy > "$install_log" 2>&1; then
  tail -n 50 "$install_log" >&2
  exit 1
fi
printf '%s\n' 'viniv:vini16' | nixos-enter --root /mnt --command 'chpasswd'
printf '\nInstalação concluída. Remova a ISO e reinicie. Usuário: viniv.\n'
