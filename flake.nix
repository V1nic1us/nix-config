{
  description = "Configuração Nix portátil para múltiplos dispositivos";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    disko = {
      url = "github:nix-community/disko/latest";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, disko, home-manager, ... }:
    let
      system = "x86_64-linux";
      username = "viniv";
    in {
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt-rfc-style;

      # Importe este módulo na configuração NixOS de cada dispositivo.
      nixosModules.desktop = import ./modules/nixos/desktop.nix;

      nixosConfigurations.desktop-vm = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit username; };
        modules = [
          ./modules/nixos/desktop.nix
          ./modules/nixos/vm.nix
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit username; };
              users.${username} = import ./home.nix;
            };
          }
        ];
      };

      nixosConfigurations.qemu-install = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit username; };
        modules = [
          disko.nixosModules.disko
          ./modules/nixos/disk-config.nix
          ./modules/nixos/desktop.nix
          ./modules/nixos/qemu-install.nix
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit username; };
              users.${username} = import ./home.nix;
            };
          }
        ];
      };

      homeConfigurations.${username} = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        modules = [ ./home.nix ];
        extraSpecialArgs = { inherit username; };
      };
    };
}
