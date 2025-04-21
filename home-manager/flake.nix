# ~/.config/home-manager/flake.nix
{
  description = "Home Manager configuration";

  inputs = {
    # Specify Nixpkgs version
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; # Or a specific release like nixos-24.05

    # Specify Home Manager version
    home-manager = {
      url = "github:nix-community/home-manager";
      # Match the nixpkgs version for consistency
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs:
    let
      system = "x86_64-linux"; # Adjust if you use a different architecture (e.g., "aarch64-linux")
      pkgs = nixpkgs.legacyPackages.${system};
      # Replace 'your-username' and 'your-hostname' with your actual username and hostname
      # You can find hostname with the command `hostname`
      username = "root";
      hostname = "pve-strix"; # Optional, but good practice if managing multiple machines
    in {
      # Define a home configuration output for your user@host
      # The name format 'username@hostname' is just a convention
      homeConfigurations."${username}@${hostname}" = home-manager.lib.homeManagerConfiguration {
         inherit pkgs;

         # Specify the modules you want to use. home.nix is the primary one.
         modules = [
           ./home.nix
           # You can add more module files here and import them in home.nix if needed
         ];

         # Optionally pass arguments to your modules
         # extraSpecialArgs = { inherit inputs; };
      };

      # You can define configurations for other users or hosts here too
      # homeConfigurations."otheruser@otherhost" = ...;

      # A simpler structure if you only manage one configuration:
      # homeConfigurations."${username}" = home-manager.lib.homeManagerConfiguration { ... };
    };
}

