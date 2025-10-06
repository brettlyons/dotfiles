{ config, lib, pkgs, userConfig, ... }:

{
  # Basic user info
  home = {
    username = userConfig.username;
    homeDirectory = "/home/${userConfig.username}";
    stateVersion = "25.05";
  };

  # Git configuration using userConfig
  programs.git = {
    enable = true;
    userName = userConfig.full_name;
    userEmail = userConfig.email_address;
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };

  # Packages
  home.packages = with pkgs; [
    # Communication
    zoom-us

    # Security tools
    wireshark
    nmap
    netcat-gnu
    tcpdump
    burpsuite
    caido

    # Development
    vscode
    firefox
    claude-code

    # System tools
    htop
    btop
    tree
    curl
    wget
    pwvucontrol  # PipeWire audio device manager
    wlogout      # Logout menu
    hyprlock     # Screen locker

    # Editor
    helix
    zk

    # Media
    mpv
    vlc
  ];

  home.pointerCursor = {
    gtk.enable = true;
    package = pkgs.graphite-cursors;
    name = "graphite-light";
    # name = "graphite-dark-nord"
    # name = "graphite-light-nord"
  };

  gtk = {
    enable = true;

    # theme = {
    #   package = pkgs.tokyonight-gtk-theme;
    #   name = "Tokyonight-dark";
    # };

    iconTheme = {
      package = pkgs.colloid-icon-theme;
      name = "Colloid-Dark";
    };
  };

  # Hyprland configuration (colors handled by Stylix)
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      "$mod" = "SUPER";

      # Monitor configuration with HDR and 2x scaling
      monitor = [
        ",preferred,auto,2,bitdepth,10,cm,auto"  # All monitors: preferred resolution, auto position, 2x scale, 10-bit color, auto color management
      ];

      misc = {
        vfr = true;  # Variable refresh rate
        vrr = 1;     # Adaptive sync
      };

      # Keyboard layout
      input = {
        kb_layout = "us";
        # kb_variant = "colemak_dh";
        follow_mouse = 1;
        touchpad = {
          natural_scroll = false;
        };
        sensitivity = 0;
      };
      
      bind = [
        "$mod, Return, exec, alacritty"
        "$mod, B, exec, firefox"
        "$mod, Q, killactive"
        "$mod+SHIFT, M, exec, wlogout"
        "$mod+SHIFT, E, exec, dolphin"
        "$mod, V, togglefloating"
        "$mod, R, exec, walker"
        "$mod, P, pseudo"
        "$mod, J, togglesplit"
        "$mod, L, exec, hyprlock"

        # Move focus (Colemak-DH: m=left, n=down, e=up, i=right)
        "$mod, m, movefocus, l"
        "$mod, i, movefocus, r"
        "$mod, e, movefocus, u"
        "$mod, n, movefocus, d"
      ];
      
      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        layout = "dwindle";
      };
      
      decoration = {
        rounding = 8;
        blur = {
          enabled = true;
          size = 8;
          passes = 1;
        };
        # drop_shadow = true;
        # shadow_range = 4;
        # shadow_render_power = 3;
      };
    };
  };

  # Bash shell
  programs.bash = {
    enable = true;
  };

  # Terminal (font handled by Stylix)
  programs.alacritty = {
    enable = true;
  };

  # eza - modern ls replacement with icons
  programs.eza = {
    enable = true;
    enableBashIntegration = true;
    icons = "always";
    git = true;
    extraOptions = [
      "--group-directories-first"
      "--header"
    ];
  };

  # Starship prompt
  programs.starship = {
    enable = true;
    enableBashIntegration = true;
  };

  # Walker application launcher
  services.walker = {
    enable = true;
    systemd.enable = true;
  };

  # Waybar status bar
  programs.waybar = {
    enable = true;
    systemd.enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;

        modules-left = [ "hyprland/workspaces" "hyprland/window" ];
        modules-center = [ "clock" ];
        modules-right = [ "pulseaudio" "power-profiles-daemon" "cpu" "memory" "network" "battery" "tray" ];

        "hyprland/workspaces" = {
          format = "{icon}";
          on-click = "activate";
        };

        "hyprland/window" = {
          max-length = 50;
        };

        clock = {
          format = "{:%H:%M}";
          format-alt = "{:%Y-%m-%d %H:%M:%S}";
          tooltip-format = "<tt><small>{calendar}</small></tt>";
          calendar = {
            mode = "month";
            mode-mon-col = 3;
            weeks-pos = "right";
            on-scroll = 1;
            format = {
              months = "<span color='#ffead3'><b>{}</b></span>";
              days = "<span color='#ecc6d9'><b>{}</b></span>";
              weeks = "<span color='#99ffdd'><b>W{}</b></span>";
              weekdays = "<span color='#ffcc66'><b>{}</b></span>";
              today = "<span color='#ff6699'><b><u>{}</u></b></span>";
            };
          };
          actions = {
            on-click-right = "mode";
            on-scroll-up = "shift_up";
            on-scroll-down = "shift_down";
          };
        };

        pulseaudio = {
          format = "{icon} {volume}%";
          format-muted = "󰝟 Muted";
          format-icons = {
            default = [ "󰕿" "󰖀" "󰕾" ];
          };
          on-click = "pwvucontrol";
        };

        "power-profiles-daemon" = {
          format = "{icon}";
          tooltip-format = "Power profile: {profile}\nDriver: {driver}";
          tooltip = true;
          format-icons = {
            default = "󰾆";
            performance = "󰓅";
            balanced = "󰾅";
            power-saver = "󰾆";
          };
        };

        cpu = {
          format = "󰻠 {usage}%";
          tooltip = false;
          on-click = "alacritty -e btop";
        };

        memory = {
          format = "󰍛 {percentage}%";
        };

        network = {
          format-wifi = "󰖨 {essid}";
          format-ethernet = "󰈀 Connected";
          format-disconnected = "󰖪 Disconnected";
          tooltip-format = "{ipaddr}/{cidr}";
          on-click = "alacritty -e nmtui";
        };

        battery = {
          format = "{icon} {capacity}%";
          format-icons = [ "󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
          format-charging = "󰂄 {capacity}%";
        };

        tray = {
          spacing = 10;
        };
      };
    };
  };

  # Let Home Manager manage itself
  programs.home-manager.enable = true;
}
