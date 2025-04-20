{ config, pkgs, ... }:

{
  # Required fields
  home.username = "root";  # Replace with your actual username on Proxmox
  home.homeDirectory = "/root";  # Replace with your actual home directory

  # Specify the state version (match your Nixpkgs version, e.g., "23.11" or "24.05")
  home.stateVersion = "23.11";  # Adjust this based on your Nix channel version

  # Packages to install in your user environment
  home.packages = with pkgs; [
    htop      # System monitoring tool
    git       # Version control
    tmux      # Terminal multiplexer
    curl      # HTTP client
    neofetch  # System info display
    helix
  ];

  # Enable and configure programs (optional but useful)
  programs = {
    # Enable and configure Bash
    bash = {
      enable = true;
      shellAliases = {
        ll = "ls -la";  # Example alias
        gs = "git status";
      };
      initExtra = ''
        # Add custom Bash startup commands here
        export PS1="\u@\h:\w\$ "  # Customize prompt
      '';
    };

    # Enable Git with basic configuration
    git = {
      enable = true;
      userName = "Anwer Khan";  # Replace with your name
      userEmail = "anwer@deepwatercreature.com";  # Replace with your email
      extraConfig = {
        init.defaultBranch = "main";
      };
    };

    # Enable Vim with some customization
    vim = {
      enable = true;
      settings = {
        number = true;  # Line numbers
        relativenumber = true;
      };
      extraConfig = ''
        set tabstop=2
        set shiftwidth=2
        set expandtab
      '';
    };
  };

  # Manage dotfiles (e.g., custom .bashrc or other configs)
  home.file = {
    ".custom-script.sh" = {
      text = ''
        #!/bin/sh
        echo "Hello from your custom script!"
      '';
      executable = true;
    };
  };

  # Enable Home Manager to manage itself
  programs.home-manager.enable = true;
}
