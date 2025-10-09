{ config, lib, pkgs, userConfig, ... }:

{
  # Basic user info
  home = {
    username = userConfig.username;
    homeDirectory = "/home/${userConfig.username}";
    stateVersion = "25.05";

    # Ensure screenshot and recording directories exist
    file = {
      "Pictures/screenshots/.keep".text = "";
      "Videos/recordings/.keep".text = "";

      # helix-everywhere script
      ".local/bin/helix-everywhere" = {
        source = ../scripts/helix-everywhere;
        executable = true;
      };
    };
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

  # EditorConfig - universal editor settings
  editorconfig = {
    enable = true;
    settings = {
      "*" = {
        charset = "utf-8";
        end_of_line = "lf";
        trim_trailing_whitespace = true;
        insert_final_newline = true;
        indent_style = "space";
        indent_size = 2;
      };
      "*.{py}" = {
        indent_size = 4;
      };
      "*.{go,c,cpp,h,hpp,rs}" = {
        indent_size = 4;
      };
      "*.{md,txt}" = {
        trim_trailing_whitespace = false;
      };
      "Makefile" = {
        indent_style = "tab";
      };
    };
  };

  # Emacs configuration for doom-emacs
  programs.emacs = {
    enable = true;
    package = pkgs.emacs-pgtk;
    extraPackages = epkgs: with epkgs; [
      vterm
      # mu4e  # Commented out due to build failure
    ];
  };

  # Packages
  home.packages = with pkgs; [
    # Communication
    zoom-us
    slack
    webcord

    # Sandboxing tools
    firejail
    bubblewrap

    # Security tools
    wireshark
    nmap
    netcat-gnu
    tcpdump
    burpsuite
    caido

    # Forensics & analysis tools
    binutils     # strings, objdump, etc.
    file         # File type identifier
    exiftool     # EXIF metadata tool
    cyberchef    # Data analysis Swiss Army knife
    unzip        # Archive extraction
    p7zip        # 7z archive support
    volatility3  # Memory forensics framework
    swayimg      # Image viewer for Wayland/Hyprland
    sqlite       # SQLite database CLI
    john         # John the Ripper password cracker
    hashcat      # GPU-accelerated password cracker
    sleuthkit    # Disk forensics toolkit
    foremost     # File carving tool
    bulk_extractor  # Extract information from disk images

    # Development
    vscode
    firefox
    tridactyl-native  # Native messenger for Tridactyl Firefox extension
    claude-code

    # System tools
    htop
    btop
    tree
    curl
    wget
    jq
    ripgrep      # Fast grep with PCRE2 support
    fd           # Fast find alternative
    wtype        # Wayland text typing tool (xdotool for Wayland)
    pwvucontrol  # PipeWire audio device manager
    wlogout      # Logout menu
    hyprlock     # Screen locker
    qalculate-gtk  # Calculator (qalc CLI for Walker)
    libnotify    # Desktop notifications (notify-send)

    # Screenshot & recording tools
    grim         # Screenshot utility for Wayland
    slurp        # Region selector for Wayland
    wf-recorder  # Screen recording for wlroots compositors

    # Container tools
    distrobox    # Container-based Linux distributions

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
    plugins = [
      pkgs.hyprlandPlugins.hypr-dynamic-cursors
    ];
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

      # Dynamic cursor plugin configuration
      "plugin:dynamic-cursors" = {
        enabled = true;
        mode = "rotate";  # Options: none, tilt, rotate, stretch

        # Shake to find configuration
        shake = {
          enabled = true;
          threshold = 4.0;  # Sensitivity
          factor = 1.5;     # How much bigger the cursor gets
        };
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
        accel_profile = "adaptive";  # Options: adaptive, flat
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
        "$mod, F, fullscreen"

        # Move focus (Colemak-DH: m=left, n=down, e=up, i=right)
        "$mod, m, movefocus, l"
        "$mod, i, movefocus, r"
        "$mod, e, movefocus, u"
        "$mod, n, movefocus, d"

        # Scratchpad
        "$mod, S, togglespecialworkspace, scratchpad"
        "$mod SHIFT, S, movetoworkspace, special:scratchpad"

        # Screenshots & Recording
        ", Print, exec, grim -g \"$(slurp)\" ~/Pictures/screenshots/$(date +%Y%m%d_%H%M%S).png"
        "SHIFT, Print, exec, grim -g \"$(hyprctl activewindow -j | jq -r '\"\\(.at[0]),\\(.at[1]) \\(.size[0])x\\(.size[1])\"')\" ~/Pictures/screenshots/$(date +%Y%m%d_%H%M%S).png"
        "ALT, Print, exec, killall -s SIGINT wf-recorder || wf-recorder -g \"$(slurp)\" -f ~/Videos/recordings/$(date +%Y%m%d_%H%M%S).mp4"

        # Notifications
        "$mod, comma, exec, makoctl dismiss"
        "$mod SHIFT, comma, exec, makoctl dismiss --all"

        # Helix Everywhere - edit text from anywhere
        "$mod SHIFT, H, exec, $HOME/.local/bin/helix-everywhere"

        # Switch to workspace
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"
        "$mod, 0, workspace, 10"

        # Move active window to workspace
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"
        "$mod SHIFT, 0, movetoworkspace, 10"
      ];

      # Mouse bindings
      bindm = [
        "$mod, mouse:272, movewindow"      # SUPER + left-click to move
        "$mod, mouse:273, resizewindow"    # SUPER + right-click to resize
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
        active_opacity = 1.0;
        inactive_opacity = 0.85;
        # drop_shadow = true;
        # shadow_range = 4;
        # shadow_render_power = 3;
      };

      # Workspace rules
      workspace = [
        "special:scratchpad, on-created-empty:alacritty"
      ];

      # Window rules for scratchpad
      windowrulev2 = [
        "float, onworkspace:special:scratchpad"
        "float, class:^(helix-everywhere)$"
        "size 80% 80%, class:^(helix-everywhere)$"
        "center, class:^(helix-everywhere)$"
      ];
    };
  };

  # Bash shell
  programs.bash = {
    enable = true;
    shellAliases = {
      kali = "distrobox enter kali --root";
    };
  };

  # direnv - automatic environment switching
  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    nix-direnv.enable = true;  # Better Nix integration with caching
  };

  # Terminal (font handled by Stylix)
  programs.alacritty = {
    enable = true;
    settings = {
      window.opacity = lib.mkForce 0.99;  # Enable transparency support for Hyprland
    };
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
    style = ''
      #custom-hypridle {
        padding: 0 8px;
        min-width: 20px;
      }
    '';
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 36;

        modules-left = [ "hyprland/workspaces" "hyprland/window" ];
        modules-center = [ "clock" ];
        modules-right = [ "pulseaudio" "custom/separator" "custom/hypridle" "custom/separator" "power-profiles-daemon" "custom/separator" "cpu" "memory" "custom/separator" "network" "battery" "custom/separator" "tray" ];

        "hyprland/workspaces" = {
          format = "{icon}";
          on-click = "activate";
          sort-by-number = true;
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

        "custom/hypridle" = {
          format = "{}";
          exec = "systemctl --user is-active hypridle-inhibit.service &>/dev/null && echo '󰅶' || echo '󰾪'";
          interval = 2;
          signal = 8;
          on-click = "systemctl --user is-active hypridle-inhibit.service &>/dev/null && (systemctl --user stop hypridle-inhibit.service && notify-send 'Hypridle' 'Enabled') || (systemd-run --user --unit=hypridle-inhibit.service systemd-inhibit --what=idle --who=waybar --why='User disabled idle' --mode=block sleep infinity && notify-send 'Hypridle' 'Disabled'); pkill -RTMIN+8 waybar";
          tooltip-format = "Click to toggle idle timeout";
        };

        "custom/separator" = {
          format = "|";
          tooltip = false;
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

  # Taskwarrior
  programs.taskwarrior = {
    enable = true;
    package = pkgs.taskwarrior3;
  };

  # Mako notification daemon
  services.mako = {
    enable = true;
    settings = {
      default-timeout = 5000;  # Auto-dismiss after 5 seconds
    };
  };

  # Let Home Manager manage itself
  programs.home-manager.enable = true;
}
