{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;

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
