{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;

  # Kernel mais atual disponível no canal nixos-unstable.
  boot.kernelPackages = pkgs.linuxPackages;

  # O módulo disponível no nixpkgs atual é o Plasma 6.
  services = {
    desktopManager.plasma6.enable = true;
    displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };
  };

  programs = {
    steam.enable = true;
    xwayland.enable = true;
  };

  environment = {
    systemPackages = [ pkgs.kitty ];
    sessionVariables.TERMINAL = "kitty";
  };
}
