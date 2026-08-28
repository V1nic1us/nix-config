{ username, ... }:
{
  networking.hostName = "nix-config-vm";

  # Perfil descartável para validar o módulo desktop em uma VM QEMU.
  users.users.${username} = {
    isNormalUser = true;
    description = "Test user";
    extraGroups = [ "wheel" ];
    initialPassword = "nixos";
  };
  security.sudo.wheelNeedsPassword = false;

  virtualisation = {
    graphics = true;
    memorySize = 4096;
    cores = 4;
    diskSize = 20480;
  };

  system.stateVersion = "24.11";
}
