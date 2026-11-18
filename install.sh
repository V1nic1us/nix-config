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
for tool in lsblk blkid mkfs.ext4 mount mountpoint findmnt nix nixos-generate-config nixos-install nixos-enter mkswap swapon; do
  command -v "$tool" >/dev/null || { printf 'Comando ausente: %s\n' "$tool" >&2; exit 1; }
done

printf 'Partições disponíveis:\n'
lsblk -o NAME,SIZE,FSTYPE,PARTTYPE,MOUNTPOINTS,MODEL
read -r -p 'Partição para o NixOS (ex.: /dev/nvme0n1p3): ' root_part
if [[ ! -b $root_part || $(lsblk -dnro TYPE -- "$root_part") != part ]]; then
  printf 'Escolha uma partição de bloco válida.\n' >&2
  exit 1
fi
if findmnt -rn -S "$root_part" >/dev/null; then
  printf 'A partição selecionada já está montada.\n' >&2
  exit 1
fi
disk="/dev/$(lsblk -dnro PKNAME -- "$root_part")"
mapfile -t esp_parts < <(lsblk -rnpo NAME,PARTTYPE -- "$disk" | awk 'tolower($2)=="c12a7328-f81f-11d2-ba4b-00a0c93ec93b" {print $1}')
if [[ ${#esp_parts[@]} -ne 1 ]]; then
  printf 'É necessária exatamente uma partição EFI no mesmo disco (%s); encontradas: %s.\n' "$disk" "${#esp_parts[@]}" >&2
  exit 1
fi
esp_part=${esp_parts[0]}
if [[ $root_part -ef $esp_part ]]; then
  printf 'A partição do sistema não pode ser a partição EFI.\n' >&2
  exit 1
fi
esp_type=$(blkid -s TYPE -o value -- "$esp_part" || true)
if [[ $esp_type != vfat ]]; then
  printf 'A partição EFI %s precisa estar formatada como FAT32; encontrada: %s.\n' "$esp_part" "$esp_type" >&2
  exit 1
fi
if findmnt -rn -S "$esp_part" >/dev/null; then
  printf 'A partição EFI já está montada.\n' >&2
  exit 1
fi
read -r -p 'Swap em GiB (0 para desativar): ' swap_gib
if [[ ! $swap_gib =~ ^(0|[1-9][0-9]*)$ ]] || (( swap_gib > 1024 )); then
  printf 'Informe um número inteiro de 0 a 1024 GiB.\n' >&2
  exit 1
fi
root_bytes=$(lsblk -bdnro SIZE -- "$root_part")
if (( root_bytes < (swap_gib + 16) * 1024 * 1024 * 1024 )); then
  printf 'A partição precisa ter pelo menos swap + 16 GiB para o sistema.\n' >&2
  exit 1
fi

printf '\nA partição %s será formatada em ext4. O conteúdo dela será apagado.\n' "$root_part"
printf 'A partição EFI %s será reutilizada sem formatação. Swap: %s GiB.\n' "$esp_part" "$swap_gib"
read -r -p 'Digite APAGAR para iniciar: ' confirmation
[[ $confirmation == APAGAR ]] || { printf 'Instalação cancelada.\n'; exit 1; }

if mountpoint -q /mnt; then
  printf '/mnt já está montado; desmonte a instalação anterior.\n' >&2
  exit 1
fi
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
