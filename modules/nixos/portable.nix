{ pkgs, ... }:
{
  networking.networkmanager.enable = true;
  time.timeZone = "America/Boa_Vista";
  i18n.defaultLocale = "pt_BR.UTF-8";
  console.keyMap = "br-abnt2";
  services.xserver.xkb.layout = "br";
  services.xserver.xkb.variant = "";

  users.users.viniv = {
    isNormalUser = true;
    description = "Viniv";
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
    ];
    shell = pkgs.zsh;
  };
  programs.zsh.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  security.rtkit.enable = true;
  system.stateVersion = "24.11";
}
