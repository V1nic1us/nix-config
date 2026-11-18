{
  description = "Configuração Nix portátil para múltiplos dispositivos";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      username = "viniv";
      # Nesta revisão do nixpkgs, fetchurl recebe curl-dev, que não contém curl.
      fetchurlCurlBin = final: prev: {
        fetchurl = prev.fetchurl.override {
          curl = nixpkgs.legacyPackages.${system}.curlMinimal.bin;
        };
      };
      homePkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        overlays = [ fetchurlCurlBin ];
      };
    in
    {
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt;

      # Importe este módulo na configuração NixOS de cada dispositivo.
      nixosModules.desktop = import ./modules/nixos/desktop.nix;
      nixosModules.portable = { ... }: {
        nixpkgs.overlays = [ fetchurlCurlBin ];
        imports = [
          ./modules/nixos/portable.nix
          ./modules/nixos/desktop.nix
          home-manager.nixosModules.home-manager
        ];
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          extraSpecialArgs = { inherit username; };
          users.${username} = import ./home.nix;
        };
      };

      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        pkgs = homePkgs;
        modules = [ ./home.nix ];
        extraSpecialArgs = { inherit username; };
      };
    };
}
