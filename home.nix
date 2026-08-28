{ username, ... }:
{
  nixpkgs.config.allowUnfree = true;

  imports = [
    ./modules/common.nix
    ./modules/fastfetch.nix
    ./modules/git.nix
    ./modules/kitty.nix
    ./modules/shell.nix
  ];

  home = {
    inherit username;
    homeDirectory = "/home/${username}";

    file = {
      ".face".source = ./assets/sunny-shadow-slave.png;
      ".face.icon".source = ./assets/sunny-shadow-slave.png;
    };

    # Não altere após a primeira aplicação sem consultar a documentação.
    stateVersion = "24.11";
  };

  programs.home-manager.enable = true;
}
