# ~/.config/home-manager/home.nix
{ config, pkgs, lib, ... }:

{
  # Home Manager needs a state version.
  home.stateVersion = "24.05"; # Or the version corresponding to your nixpkgs/home-manager inputs

  # Set the username and home directory for Home Manager
  home.username = "root";
  home.homeDirectory = "/root"; # Home directory for the root user

  # Add packages
  home.packages = [
    pkgs.htop
    pkgs.btop
    pkgs.bat
    pkgs.gh
    pkgs.git
    pkgs.helix
    pkgs.rsync
    pkgs.iperf3
    pkgs.lazygit
  ];

  # Configure programs
  programs.git = {
    enable = true;
    userName = "Anwer Khan";
    userEmail = "deepwatrcreatur@gmail.com";
  };

  programs.bash.enable = true; # Example: enable bash integration

  # Let Home Manager manage itself if you want the `home-manager` command available
  programs.home-manager.enable = true;
}
