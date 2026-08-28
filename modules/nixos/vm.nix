{ username, ... }:
{
  networking.hostName = "nix-config-vm";
  console.keyMap = "br-abnt2";

  # Perfil descartável para validar o módulo desktop em uma VM QEMU.
  users.users.${username} = {
    isNormalUser = true;
    description = "Test user";
    extraGroups = [ "wheel" ];
    initialPassword = "nixos";
  };
  security.sudo.wheelNeedsPassword = false;
  services.spice-vdagentd.enable = true;

  virtualisation = {
    graphics = true;
    memorySize = 4096;
    diskSize = 20480;
    qemu.options = [ "-smp 4" ];
  };

  system.stateVersion = "24.11";
}
