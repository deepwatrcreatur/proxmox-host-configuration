{
  description = "Home Manager configuration";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      homeConfigurations = {
        root = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./modules/home.nix ];
        };
        # Optionally keep your other variants:
        "${pkgs.stdenv.hostPlatform.system}" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [ ./modules/home.nix ];
        };
      };
    };
}
