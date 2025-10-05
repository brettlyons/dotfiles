{ config, lib, pkgs, userConfig, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  # Bootloader configuration - Lanzaboote for Secure Boot
  boot = {
    loader.systemd-boot.enable = lib.mkForce false; # Disabled for Lanzaboote
    loader.efi.canTouchEfiVariables = true;
    
    # Lanzaboote configuration
    lanzaboote = {
      enable = true;
      pkiBundle = "/etc/secureboot";
    };
    blacklistedKernelModules = [ "nouveau" ];

    # Impermanence root wiping
    initrd.postDeviceCommands = lib.mkAfter ''
      mkdir /btrfs_tmp
      mount /dev/disk/by-uuid/c3907d0b-d76d-43e3-9b82-bc6dcee0c1bc /btrfs_tmp
      if [[ -e /btrfs_tmp/root ]]; then
          mkdir -p /btrfs_tmp/old_roots
          timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
          mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
      fi

      delete_subvolume_recursively() {
          IFS=$'\n'
          for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
              delete_subvolume_recursively "/btrfs_tmp/$i"
          done
          btrfs subvolume delete "$1"
      }

      for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30); do
          delete_subvolume_recursively "$i"
      done

      btrfs subvolume create /btrfs_tmp/root
      umount /btrfs_tmp
    '';
  };
  # System fonts
  fonts = {
    packages = with pkgs; [
      (nerdfonts.override { fonts = [ "CascadiaCode" ]; })
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
    ];
    
    fontconfig = {
      defaultFonts = {
        monospace = [ "CaskaydiaMono Nerd Font" ];
        serif = [ "Noto Serif" ];
        sansSerif = [ "Noto Sans" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };

  # Core system packages
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    curl
    sops
    age
  ];

  # Git global configuration
  programs.git = {
    enable = true;
    config = {
      user = {
        name = userConfig.full_name;
        email = userConfig.email_address;
      };
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };

  # User account
  users.users.${userConfig.username} = {
    isNormalUser = true;
    description = userConfig.full_name;
    extraGroups = [ "networkmanager" "wheel" "wireshark" ];
    shell = pkgs.bash;
    hashedPasswordFile = config.sops.secrets.blyons_password.path;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICNyK0e6k0fOGbwGWi3Yg03Cg31OPgkIjA4ZKdc+rLIy blyons@fastmail.com"
    ];
  };

  # Networking
  networking = {
    networkmanager.enable = true;
    firewall.enable = true;
  };

  # Security
  security = {
    rtkit.enable = true;
    polkit.enable = true;
  };

  # Audio
  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # OpenSSH server
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
      X11Forwarding = false;
    };
  };

  # Tailscale VPN
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
  };

  # Display manager - greetd with tuigreet
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd Hyprland";
        user = "greeter";
      };
    };
  };

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # System version
  system.stateVersion = "25.05";
}