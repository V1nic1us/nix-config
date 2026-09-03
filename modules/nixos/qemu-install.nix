{ config, ... }:
{
  imports = [ ./vm.nix ];

  boot.loader.grub = {
    enable = true;
    device = config.disko.devices.disk.main.device;
  };
}
