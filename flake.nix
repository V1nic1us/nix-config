{
  description = "Configuração Nix portátil para múltiplos dispositivos";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      username = "viniv";
    in {
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt-rfc-style;

      # Importe este módulo na configuração NixOS de cada dispositivo.
      nixosModules.desktop = import ./modules/nixos/desktop.nix;

      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        modules = [ ./home.nix ];
        extraSpecialArgs = { inherit username; };
      };
    };
}
