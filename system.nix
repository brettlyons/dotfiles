{ config, lib, pkgs, userConfig, ... }:

{
  # No imports here - hardware config handled in flake.nix

  # Bootloader configuration - Limine for Secure Boot
  boot = {
    # Liquorix kernel for desktop performance
    kernelPackages = pkgs.linuxKernel.packages.linux_lqx;

    loader.efi.canTouchEfiVariables = true;

    # Limine bootloader configuration
    loader.limine = {
      enable = true;
      efiSupport = true;
      biosSupport = false;
      secureBoot.enable = true;
    };

    # Fast boot - minimal bootloader timeout
    loader.timeout = 0;

    blacklistedKernelModules = [ "nouveau" ];

    # Kernel parameters
    kernelParams = [
      "quiet"                  # Minimal kernel messages
      "splash"                 # Show Plymouth splash screen
      "udev.log_level=3"       # Reduce udev logging
      "vt.global_cursor_default=0"  # Hide cursor
      "rd.systemd.show_status=false"  # Hide systemd status during initrd
      "rd.udev.log_level=3"            # Quiet udev in initrd
      "plymouth.ignore-serial-consoles" # Prevent Plymouth from fighting with serial
    ];

    # Silent boot configuration
    consoleLogLevel = 0;
    initrd.verbose = false;

    # Plymouth boot splash
    plymouth.enable = true;

    # tmpfs for /tmp - faster temporary files
    tmp.useTmpfs = true;

    # LUKS encryption support
    initrd.luks.devices."crypted" = {
      device = "/dev/disk/by-uuid/09e74f96-8cc7-490a-a254-84f89f320795";
      crypttabExtraOpts = [ "tpm2-device=auto" ];
    };

    # Additional kernel modules for LVM/LUKS/BTRFS
    initrd.kernelModules = [ "dm-mod" "dm-crypt" "dm-snapshot" ];

    # TPM2 support for auto-unlock
    initrd.systemd.enable = true;
    initrd.systemd.tpm2.enable = true;

    # Impermanence root wiping (systemd-based for stage 1)
    initrd.systemd.services.rollback = {
      description = "Rollback BTRFS root subvolume to a pristine state";
      wantedBy = [ "initrd.target" ];
      after = [ "systemd-cryptsetup@crypted.service" ];
      before = [ "sysroot.mount" ];
      unitConfig.DefaultDependencies = "no";
      serviceConfig.Type = "oneshot";
      script = ''
        mkdir -p /mnt
        mount -o subvol=/ /dev/mapper/root_vg-root /mnt

        # Move current root to old_roots with timestamp
        if [[ -e /mnt/root ]]; then
            mkdir -p /mnt/old_roots
            timestamp=$(date --date="@$(stat -c %Y /mnt/root)" "+%Y-%m-%d_%H:%M:%S")
            mv /mnt/root "/mnt/old_roots/$timestamp"
        fi

        # Delete old root subvolumes (older than 30 days)
        delete_subvolume_recursively() {
            IFS=$'\n'
            for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
                delete_subvolume_recursively "/mnt/$i"
            done
            btrfs subvolume delete "$1"
        }

        for i in $(find /mnt/old_roots/ -maxdepth 1 -mtime +30); do
            delete_subvolume_recursively "$i"
        done

        # Create fresh root subvolume
        btrfs subvolume create /mnt/root
        umount /mnt
      '';
    };
  };

  # Hardware graphics acceleration
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver  # VA-API for Intel GPUs (Broadwell+)
    ];
  };

  # ZSA keyboard support (ErgoDox EZ, Moonlander, etc.)
  hardware.keyboard.zsa.enable = true;

  # Thunderbolt device management
  services.hardware.bolt.enable = true;

  # System fonts
  fonts = {
    packages = with pkgs; [
      nerd-fonts.caskaydia-mono
      nerd-fonts.symbols-only
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
    sbctl           # Secure Boot key management

    # USB and filesystem tools
    ntfs3g          # NTFS support
    exfat           # exFAT support
    dosfstools      # FAT32 support
    parted          # Partition management
    lsof            # List open files (useful for umount)
    usbutils        # lsusb and USB device info
    usbguard-notifier  # GUI notifications for USB device authorization

    # Focusrite Scarlett firmware updater
    scarlett2

    # Spell checking for editors (Doom Emacs, Neovim)
    hunspell
    hunspellDicts.en_US-large

    # Remote desktop client
    freerdp         # RDP client (xfreerdp)
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
      safe.directory = "/home/blyons/workspace/dotfiles";  # Allow root to access user-owned repo
    };
  };

  # User account
  users.users.${userConfig.username} = {
    isNormalUser = true;
    description = userConfig.full_name;
    extraGroups = [ "networkmanager" "wheel" "wireshark" "plugdev" "docker" "podman" "audio" ];
    shell = pkgs.zsh;
    hashedPasswordFile = config.sops.secrets.blyons_password.path;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICNyK0e6k0fOGbwGWi3Yg03Cg31OPgkIjA4ZKdc+rLIy blyons@fastmail.com"
    ];
  };

  # Enable ZSH system-wide
  programs.zsh.enable = true;

  # Networking
  networking = {
    hostName = "bamboo";
    networkmanager.enable = true;
    firewall = {
      enable = true;
      # Allow Tailscale traffic
      trustedInterfaces = [ "tailscale0" ];
      checkReversePath = "loose";  # Required for Tailscale
    };
  };

  time.timeZone = "America/Denver";

  # Security
  security = {
    rtkit.enable = true;
    polkit.enable = true;
    sudo.wheelNeedsPassword = false;
    apparmor.enable = true;
  };

  # USBGuard - USB device authorization
  services.usbguard = {
    enable = true;
    dbus.enable = true;  # Enable DBus interface for GUI tools
    IPCAllowedGroups = [ "wheel" ];  # Allow wheel group to manage USBGuard
    rules = ''
      # USB Host Controllers
      allow id 1d6b:0002 serial "0000:00:14.0" name "xHCI Host Controller" hash "jEP/6WzviqdJ5VSeTUY8PatCNBKeaREvo2OqdplND/o=" parent-hash "rV9bfLq7c2eA4tYjVjwO4bxhm+y6GgZpl9J60L0fBkY=" with-interface 09:00:00 with-connect-type ""
      allow id 1d6b:0003 serial "0000:00:14.0" name "xHCI Host Controller" hash "prM+Jby/bFHCn2lNjQdAMbgc6tse3xVx+hZwjOPHSdQ=" parent-hash "rV9bfLq7c2eA4tYjVjwO4bxhm+y6GgZpl9J60L0fBkY=" with-interface 09:00:00 with-connect-type ""
      allow id 1d6b:0002 serial "0000:1f:00.0" name "xHCI Host Controller" hash "s9V4liDJBlYv0+TNjNWwxkz0EWwkcRoOHjIobLr2uFI=" parent-hash "y/hBL2KpMx2UFGN3ppStuUznESYeHZhJ6Qkt8Mpe+Mo=" with-interface 09:00:00 with-connect-type ""
      allow id 1d6b:0003 serial "0000:1f:00.0" name "xHCI Host Controller" hash "50SSBXfvZ255h/FXcWZ0b593U5ZfiVv3Eyhg7MCzlFU=" parent-hash "y/hBL2KpMx2UFGN3ppStuUznESYeHZhJ6Qkt8Mpe+Mo=" with-interface 09:00:00 with-connect-type ""

      # Audio interface
      allow id 1235:8219 serial "S248F3E53ADA1C" name "Scarlett 2i2 4th Gen" hash "Rnoy9xBy42cKIsCQKa1JuIv9332uLEhk5DGhPcO0IsE=" parent-hash "jEP/6WzviqdJ5VSeTUY8PatCNBKeaREvo2OqdplND/o=" with-interface { 01:01:20 01:02:20 01:02:20 01:02:20 01:02:20 ff:01:20 } with-connect-type "hotplug"

      # Mouse
      allow id 1bcf:0005 serial "" name "USB Optical Mouse" hash "MZJHJAlLoXHFOsLGDiCcWprsu32/NU61IupjvjY6Lgs=" parent-hash "jEP/6WzviqdJ5VSeTUY8PatCNBKeaREvo2OqdplND/o=" via-port "1-3" with-interface 03:01:02 with-connect-type "hotplug"

      # Webcam
      allow id 046d:0825 serial "E5AF8F00" name "C270 HD WEBCAM" hash "Qv/xAJAykpwDlrjYh0gXVDZokVu6C3vBT56kPzn/DHg=" parent-hash "jEP/6WzviqdJ5VSeTUY8PatCNBKeaREvo2OqdplND/o=" with-interface { 0e:01:00 0e:02:00 0e:02:00 0e:02:00 0e:02:00 0e:02:00 0e:02:00 0e:02:00 0e:02:00 0e:02:00 0e:02:00 0e:02:00 0e:02:00 01:01:00 01:02:00 01:02:00 01:02:00 01:02:00 01:02:00 } with-connect-type "hotplug"

      # Keyboard - Ergodox EZ
      allow id 3297:4974 serial "LzWGM/B4wQwQ" name "Ergodox EZ" hash "D1io106SVqdPNqtz31CiQ6CCx2VLgEOs3kQ3Dq7jKms=" parent-hash "jEP/6WzviqdJ5VSeTUY8PatCNBKeaREvo2OqdplND/o=" with-interface { 03:01:01 03:00:00 03:01:02 03:00:00 } with-connect-type "hotplug"

      # USB Flash Drives
      allow id 154b:1006 serial "900049E75567BD58" name "USB 3.2.1 FD" hash "l+gVvaerBZulS5lJuAcqjpwoIMPefZzsIDkmArNvDt0=" parent-hash "prM+Jby/bFHCn2lNjQdAMbgc6tse3xVx+hZwjOPHSdQ=" with-interface 08:06:50 with-connect-type "hotplug"
      allow id 125f:db8a serial "26324232500701AC" name "ADATA USB Flash Drive" hash "MvN59p6tTlMJ0qTouhGVdfXybiyltuOCLQE6wDccdZQ=" parent-hash "prM+Jby/bFHCn2lNjQdAMbgc6tse3xVx+hZwjOPHSdQ=" with-interface 08:06:50 with-connect-type "hotplug"
    '';
  };

  # Docker
  virtualisation.docker.enable = true;

  # Podman - for Distrobox
  virtualisation.podman = {
    enable = true;
    dockerCompat = false;  # Keep docker separate
    defaultNetwork.settings.dns_enabled = true;
  };

  # Kali Linux declarative container
  virtualisation.oci-containers = {
    backend = "podman";
    containers.kali = {
      image = "docker.io/kalilinux/kali-rolling:latest";
      autoStart = true;
      extraOptions = [
        "--cap-add=NET_RAW"
        "--cap-add=NET_ADMIN"
        "--cap-add=SYS_PTRACE"  # For debugging tools
        "--security-opt=apparmor=unconfined"  # Required for some security tools
        "--privileged"  # Kali security tools need elevated privileges
      ];
      volumes = [
        "/persist/system/kali/home:/root:rw"  # Persistent home directory
        "/persist/system/kali/data:/data:rw"  # Persistent data directory
      ];
      # Keep container running
      cmd = [ "sleep" "infinity" ];
    };
  };

  # Automatic Kali tools installation - timer-based, non-blocking
  systemd.services.kali-setup = {
    description = "Install Kali Linux headless tools on first boot";
    after = [ "podman-kali.service" ];
    requires = [ "podman-kali.service" ];
    # Non-blocking: triggered by timer, not wanted by any target

    unitConfig = {
      DefaultDependencies = false;  # Don't block any system targets
    };

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # Wait for container to be fully ready
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 10";
      # Only run if kali-linux-headless is not already installed
      ExecCondition = pkgs.writeShellScript "kali-check-setup" ''
        if ${pkgs.podman}/bin/podman exec kali dpkg -l kali-linux-headless 2>/dev/null | grep -q '^ii'; then
          echo "Kali tools already installed, skipping setup"
          exit 1  # Skip execution
        fi
        exit 0  # Proceed with installation
      '';
      ExecStart = pkgs.writeShellScript "kali-setup" ''
        set -e
        echo "Installing Kali Linux headless tools..."

        # Update and install kali-linux-headless
        ${pkgs.podman}/bin/podman exec kali bash -c "
          export DEBIAN_FRONTEND=noninteractive
          apt update
          apt full-upgrade -y
          apt install -y kali-linux-headless
          apt clean
        "

        # Copy Kali default shell configs
        echo "Configuring shell environment..."
        ${pkgs.podman}/bin/podman exec kali bash -c "
          cp -n /etc/skel/.zshrc /root/.zshrc 2>/dev/null || true
          cp -n /etc/skel/.bashrc /root/.bashrc 2>/dev/null || true
        "

        echo "Kali Linux setup complete!"
      '';
    };
  };

  # Timer to trigger kali-setup 2 minutes after boot
  systemd.timers.kali-setup = {
    description = "Timer for Kali Linux setup";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "2min";  # Run 2 minutes after boot
      Unit = "kali-setup.service";
    };
  };

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

  # SMART disk monitoring
  services.smartd = {
    enable = true;
    notifications.wall.enable = true;
  };

  # Hyprland
  programs.hyprland = {
    enable = true;
    withUWSM = true;
    xwayland.enable = true;
  };

  # Firejail sandboxing
  programs.firejail = {
    enable = true;
    wrappedBinaries = {
      slack = {
        executable = "${pkgs.slack}/bin/slack";
        profile = "${pkgs.firejail}/etc/firejail/slack.profile";
      };
      # webcord removed from firejail to enable screensharing
      # webcord = {
      #   executable = "${pkgs.webcord}/bin/webcord";
      #   profile = "${pkgs.firejail}/etc/firejail/discord.profile";
      # };
    };
  };

  # Display manager - greetd with regreet
  services.greetd.enable = true;

  programs.regreet = {
    enable = true;
    # Regreet will automatically configure greetd to launch in cage compositor
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

  # Automatic store optimization
  nix.optimise.automatic = true;

  # Automatic system updates
  system.autoUpgrade = {
    enable = true;
    flake = "/home/blyons/workspace/dotfiles#bamboo";
    dates = "04:00";  # Run daily at 4 AM
    allowReboot = false;  # Don't automatically reboot
  };

  # System version
  system.stateVersion = "25.05";
}
