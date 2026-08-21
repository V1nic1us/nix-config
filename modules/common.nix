{ pkgs, ... }:
{
  home.packages = with pkgs; [
    android-studio
    bat
    btop
    curl
    discord
    fd
    jq
    ripgrep
    tree
    zed-editor
  ];

  programs = {
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
    fzf.enable = true;
  };
}
