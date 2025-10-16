{ config, lib, pkgs, userConfig, ... }:

{
  # SOPS-nix configuration to avoid timing issues with impermanence
  sops = {
    defaultSopsFile = "/persist/system/etc/nixos/secrets/secrets.yaml";
    age.keyFile = "/persist/system/etc/nixos/secrets/keys.txt";
    # Disable SSH key paths to avoid timing issues with impermanence
    age.sshKeyPaths = [];
    gnupg.sshKeyPaths = [];
    # Disable validation for impermanence (file exists at runtime, not build time)
    validateSopsFiles = false;

    secrets.blyons_password = {
      neededForUsers = true;
    };
  };

  # Impermanence configuration - matches current system setup  
  environment.persistence."/persist/system" = {
    hideMounts = true;
    
    directories = [
      # System directories (needed for boot)
      { directory = "/var/lib/nixos"; user = "root"; group = "root"; mode = "0755"; }
      { directory = "/etc/nixos"; user = "root"; group = "root"; mode = "0755"; }
      { directory = "/etc/nixos/secrets"; user = "root"; group = "root"; mode = "0700"; }
      
      # Boot-critical paths
      { directory = "/etc/ssh"; user = "root"; group = "root"; mode = "0755"; }
      { directory = "/etc/secureboot"; user = "root"; group = "root"; mode = "0755"; }
      { directory = "/usr/share/secureboot"; user = "root"; group = "root"; mode = "0755"; }
      { directory = "/var/lib/sbctl"; user = "root"; group = "root"; mode = "0755"; }
      
      # System directories (not boot-critical)
      "/var/log"
      "/var/lib/systemd/coredump"
      
      # Network configuration
      "/etc/NetworkManager/system-connections"
      
      # Hardware/services
      "/var/lib/bluetooth"
      "/var/lib/colord"
      "/var/lib/tailscale"
      
      # Container/virtualization
      "/var/lib/containers"
      "/var/lib/docker"
      "/var/lib/libvirt"
      "/var/lib/postgresql"

      # Kali container persistent storage
      { directory = "/persist/system/kali/home"; user = "root"; group = "root"; mode = "0700"; }
      { directory = "/persist/system/kali/data"; user = "root"; group = "root"; mode = "0755"; }

      # User home directory
      "/home/${userConfig.username}"
    ];
    
    files = [
      # Machine ID file
      "/etc/machine-id"
    ];
    
    users.${userConfig.username} = {
      directories = [
        # User config
        ".config"
        ".gnupg"
        ".ssh"
        ".claude"
        ".nixops"
        
        # Browser data (profiles, logins, bookmarks)
        ".mozilla"
        
        # Application data
        ".BurpSuite"
        ".java"
        
        # User data directories
        "Documents"
        "Downloads" 
        "Music"
        "Pictures"
        "Videos"
        "Notes"
        "VMs"
        "finances"
        "org"
        "workspace"
        
        # Development tools
        ".local/bin"
        ".local/share/direnv"
        ".local/share/nvim"  # Neovim plugin data and lazy.nvim cache
        ".local/share/task"
        ".local/share/timewarrior"
        ".local/share/keyrings"
        
        # Applications
        ".local/share/Steam"
        ".local/share/containers"
        ".local/share/docker"
        ".local/share/qutebrowser"
        ".local/share/rancher-desktop"
        ".local/share/amphetype"
        
        # Cache (selective)
        ".cache/cliphist"
        ".cache/distrobox"
        ".cache/nvim"  # Neovim lazy.nvim download cache
        ".cache/qutebrowser"
        ".cache/rancher-desktop"
        
        # State
        ".local/state/nvim"  # Neovim shada, view, swap files
        ".local/state/wireplumber"
        
        # Rancher Desktop
        ".rd"
      ];
      
      files = [
        ".justfile"
      ];
    };
  };
}