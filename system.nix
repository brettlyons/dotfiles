{ config, lib, pkgs, userConfig, ... }:

{
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
  system.stateVersion = "24.05";
}