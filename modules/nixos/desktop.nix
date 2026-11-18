{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;

  # Kernel mais atual disponível no canal nixos-unstable.
  boot.kernelPackages = pkgs.linuxPackages;

  # O módulo disponível no nixpkgs atual é o Plasma 6.
  services = {
    desktopManager.plasma6.enable = true;
    orca.enable = false;
    speechd.enable = false;
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
    etc."xdg/kdeglobals".source = "${pkgs.kdePackages.breeze}/share/color-schemes/BreezeDark.colors";
    etc."xdg/plasmarc".text = ''
      [Theme]
      name=breeze-dark
    '';
    systemPackages = [ pkgs.kitty ];
    sessionVariables.TERMINAL = "kitty";
  };
}
