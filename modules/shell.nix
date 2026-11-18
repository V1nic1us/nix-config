{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    shellAliases = {
      ll = "ls -lah";
      nix-update = "if [ -f /etc/nixos/flake.nix ]; then sudo nixos-rebuild switch --flake /etc/nixos#portable; else home-manager switch --flake ~/nix-config#viniv; fi";
    };
  };
}
