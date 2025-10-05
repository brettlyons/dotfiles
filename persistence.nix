{ config, lib, pkgs, userConfig, ... }:

{
  # SOPS-nix configuration to avoid timing issues with impermanence
  sops = {
    defaultSopsFile = /persist/system/etc/nixos/secrets.yaml;
    age.keyFile = "/persist/system/etc/nixos/secrets/keys.txt";
    # Disable SSH key paths to avoid timing issues with impermanence
    age.sshKeyPaths = [];
    gnupg.sshKeyPaths = [];
    
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
        ".mozilla"
        ".claude"
        ".nixops"
        
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
        ".cache/qutebrowser"
        ".cache/rancher-desktop"
        
        # State
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