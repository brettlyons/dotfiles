{ config, lib, pkgs, userConfig, ... }:

{
  # No imports here - hardware config handled in flake.nix

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

    # Kernel parameters
    kernelParams = [
      "console=tty0"
    ];

    # Enable persistent journald logging
    # systemd.services.systemd-journald.environment.SYSTEMD_LOG_LEVEL = "debug";

    # LUKS encryption support
    initrd.luks.devices."crypted" = {
      device = "/dev/disk/by-uuid/09e74f96-8cc7-490a-a254-84f89f320795";
      crypttabExtraOpts = [ "tpm2-device=auto" ];
    };

    # Additional kernel modules for LVM/LUKS/BTRFS
    initrd.kernelModules = [ "dm-mod" "dm-crypt" "dm-snapshot" ];

    # Impermanence root wiping
    initrd.postDeviceCommands = lib.mkAfter ''
      mkdir /btrfs_tmp
      mount /dev/root_vg/root /btrfs_tmp
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
      nerd-fonts.caskaydia-mono
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

    # USB and filesystem tools
    ntfs3g          # NTFS support
    exfat           # exFAT support
    dosfstools      # FAT32 support
    parted          # Partition management
    lsof            # List open files (useful for umount)
    usbutils        # lsusb and USB device info

    # Focusrite Scarlett firmware updater
    scarlett2
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
    extraGroups = [ "networkmanager" "wheel" "wireshark" "plugdev" "docker" "podman" "audio" ];
    shell = pkgs.bash;
    hashedPasswordFile = config.sops.secrets.blyons_password.path;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICNyK0e6k0fOGbwGWi3Yg03Cg31OPgkIjA4ZKdc+rLIy blyons@fastmail.com"
    ];
  };

  # Networking
  networking = {
    hostName = "bamboo";
    networkmanager.enable = true;
    firewall.enable = true;
  };

  time.timeZone = "America/Denver";

  # Security
  security = {
    rtkit.enable = true;
    polkit.enable = true;
    sudo.wheelNeedsPassword = false;
  };

  # Docker
  virtualisation.docker.enable = true;

  # Podman - for Distrobox
  virtualisation.podman = {
    enable = true;
    dockerCompat = false;  # Keep docker separate
    defaultNetwork.settings.dns_enabled = true;
  };

  # Kali Linux distrobox setup - runs once to create container
  system.activationScripts.kaliDistrobox = lib.stringAfter [ "users" ] ''
    # Check if kali distrobox already exists
    if ! ${pkgs.podman}/bin/podman container exists kali 2>/dev/null; then
      echo "Creating Kali Linux distrobox container..."
      ${pkgs.distrobox}/bin/distrobox create \
        --name kali \
        --image docker.io/kalilinux/kali-rolling \
        --root \
        --additional-flags "--cap-add=NET_RAW --cap-add=NET_ADMIN" \
        --init-hooks "apt update && apt full-upgrade -y && apt install -y kali-linux-headless" \
        --yes || true
    fi
  '';

  # ZRAM - Compressed RAM swap
  zramSwap = {
    enable = true;
    algorithm = "zstd";  # Good compression + performance balance
    memoryPercent = 50;  # Use up to 50% of RAM for compressed swap
  };

  # USB and removable media support
  services.udisks2.enable = true;
  services.gvfs.enable = true; # For file manager integration

  # Audio
  services.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Power management
  services.power-profiles-daemon.enable = true;

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

  # Hyprland
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  # Display manager - greetd with tuigreet
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        # command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd Hyprland";
        user = "greeter";
      };
    };
  };

  programs.regreet = {
    enable = true;
    # theme.package = pkgs.tokyonight-gtk-theme;
    # theme.name = "Tokyonight-dark";
  };

  # Enable flakes and build optimizations
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    max-jobs = "auto";  # Build multiple packages in parallel
    cores = 0;          # Use all CPU cores per build (0 = all)
  };

  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";  # Run every Sunday at 03:00
    options = "--delete-older-than 30d";  # Delete unreferenced paths older than 30 days
  };

  # Automatic system updates
  system.autoUpgrade = {
    enable = true;
    flake = "/home/blyons/workspace/dotfiles#bamboo";
    dates = "04:00";  # Run daily at 4 AM
    allowReboot = false;  # Don't automatically reboot
  };

  # # Enhanced logging and debugging for boot issues
  # services.journald = {
  #   extraConfig = ''
  #     Storage=persistent
  #     Compress=yes
  #     SystemMaxUse=1G
  #     SystemMaxFileSize=100M
  #     ForwardToConsole=yes
  #     MaxLevelConsole=debug
  #   '';
  # };

  # # Emergency shell access for boot failures
  # systemd.services."emergency-shell" = {
  #   enable = true;
  #   serviceConfig = {
  #     ExecStart = "/bin/sh";
  #     Type = "idle";
  #     StandardInput = "tty-force";
  #     StandardOutput = "inherit";
  #     StandardError = "inherit";
  #     KillMode = "process";
  #     IgnoreSIGPIPE = false;
  #     SendSIGHUP = true;
  #   };
  # };

  # System version
  system.stateVersion = "25.05";
}
