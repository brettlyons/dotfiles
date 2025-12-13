{
  config,
  lib,
  pkgs,
  userConfig,
  ...
}:

{
  imports = [
    # ./notes-sync.nix
  ];

  # Disable Stylix for Neovim (LazyVim will manage configuration)
  stylix.targets.neovim.enable = false;

  # Basic user info
  home = {
    username = userConfig.username;
    homeDirectory = "/home/${userConfig.username}";
    stateVersion = "25.05";

    # Explicitly set session variables for systemd user session
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };

    # Ensure screenshot and recording directories exist
    file = {
      "Pictures/screenshots/.keep".text = "";
      "Videos/recordings/.keep".text = "";

      # helix-everywhere script
      ".local/bin/helix-everywhere" = {
        source = ../scripts/helix-everywhere;
        executable = true;
      };

      # hypr-help script
      ".local/bin/hypr-help" = {
        source = ../scripts/hypr-help;
        executable = true;
      };

      # clipboard-manager script
      ".local/bin/clipboard-manager" = {
        source = ../scripts/clipboard-manager;
        executable = true;
      };

      # marksman wrapper (aliases markdown-oxide)
      ".local/bin/marksman" = {
        source = ../scripts/marksman;
        executable = true;
      };

      # breathe-reminder script
      ".local/bin/breathe-reminder" = {
        source = ../scripts/breathe-reminder;
        executable = true;
      };

      # eye-relief script
      ".local/bin/eye-relief" = {
        source = ../scripts/eye-relief;
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
        max_line_length = 80;
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
    extraPackages =
      epkgs: with epkgs; [
        vterm
        # mu4e # Commented out due to build failure
      ];
  };

  # Packages
  home.packages = with pkgs; [
    # Communication
    zoom-us
    slack
    webcord
    discord

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
    ffuf # Web fuzzer
    feroxbuster # Recursive content discovery

    # Forensics & analysis tools
    binutils # strings, objdump, etc.
    file # File type identifier
    exiftool # EXIF metadata tool
    cyberchef # Data analysis Swiss Army knife
    unzip # Archive extraction
    p7zip # 7z archive support
    volatility3 # Memory forensics framework
    swayimg # Image viewer for Wayland/Hyprland
    sqlite # SQLite database CLI
    john # John the Ripper password cracker
    hashcat # GPU-accelerated password cracker
    wordlists
    sleuthkit # Disk forensics toolkit
    foremost # File carving tool
    bulk_extractor # Extract information from disk images

    # Development
    vscode
    firefox
    tridactyl-native # Native messenger for Tridactyl Firefox extension
    claude-code
    python3 # Python interpreter (needed for taskwarrior)
    timewarrior
    gh # GitHub CLI

    # System tools
    htop
    btop
    tree
    curl
    wget
    jq
    ripgrep # Fast grep with PCRE2 support
    fd # Fast find alternative
    bat # Better cat with syntax highlighting
    tealdeer # tldr man pages
    wtype # Wayland text typing tool (xdotool for Wayland)
    wl-clipboard # Wayland clipboard utilities
    pwvucontrol # PipeWire audio device manager
    wlogout # Logout menu
    hyprlock # Screen locker
    hypridle # Idle management daemon
    brightnessctl # Screen brightness control
    qalculate-gtk # Calculator (qalc CLI for Walker)
    libnotify # Desktop notifications (notify-send)
    bc

    # Screenshot & recording tools
    grim # Screenshot utility for Wayland
    slurp # Region selector for Wayland
    wf-recorder # Screen recording for wlroots compositors
    hyprpicker # Color picker for Hyprland

    # Container tools
    distrobox # Container-based Linux distributions

    # Editor
    helix
    zk
    yazi # Terminal file manager

    # Neovim dependencies and LSP servers
    gcc # C compiler for treesitter
    gnumake # Build tool
    tree-sitter # Tree-sitter CLI for nvim-treesitter
    nodejs # Node.js runtime for many LSP servers
    cargo # Rust toolchain for rust-analyzer
    ripgrep # Required by telescope.nvim
    fd # Required by telescope.nvim

    # LSP servers (managed by Nix, not mason.nvim)
    lua-language-server
    nil # Nix LSP
    rust-analyzer
    pyright # Python LSP
    nodePackages.typescript-language-server
    nodePackages.bash-language-server
    nodePackages.vscode-langservers-extracted # HTML/CSS/JSON/ESLint
    markdown-oxide # Markdown LSP (Obsidian-inspired)

    # Formatters and linters
    stylua # Lua formatter
    nixfmt-rfc-style # Nix formatter
    black # Python formatter
    nodePackages.prettier
    markdownlint-cli2 # Markdown linter

    # Dictionary wordlist for prose autocomplete in Neovim
    scowl # Comprehensive English wordlist

    # Keyboard configuration
    keymapp # ZSA keyboard configuration (Ergodox EZ, Moonlander, etc.)

    # Media
    mpv
    vlc

    # Office suite
    libreoffice-fresh

    # Document conversion
    pandoc
  ];

  home.pointerCursor = {
    gtk.enable = true;
    package = pkgs.graphite-cursors;
    name = "graphite-light";
  };

  gtk = {
    enable = true;

    iconTheme = {
      package = pkgs.colloid-icon-theme;
      name = "Colloid-Dark";
    };
  };

  # Chromium with Bitwarden extension
  programs.chromium = {
    enable = true;
    extensions = [
      "nngceckbapebfimnlniiiahkandclblb" # Bitwarden
    ];
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
        ",preferred,auto,2,bitdepth,10,cm,auto" # All monitors: preferred resolution, auto position, 2x scale, 10-bit color, auto color management
      ];

      misc = {
        vfr = true; # Variable refresh rate
        vrr = 0; # Adaptive sync (disabled - testing for flickering fix)
      };

      cursor = {
        inactive_timeout = 2; # Hide cursor after 2 seconds of inactivity
        hide_on_key_press = true; # Hide cursor when typing
      };

      render = {
        direct_scanout = true; # Allow direct scanout for fullscreen windows
      };

      # Dynamic cursor plugin configuration
      "plugin:dynamic-cursors" = {
        enabled = true;
        mode = "stretch"; # Options: none, tilt, rotate, stretch

        # Shake to find configuration
        shake = {
          enabled = true;
          threshold = 4.0; # Sensitivity
          factor = 1.5; # How much bigger the cursor gets
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
        accel_profile = "adaptive"; # Options: adaptive, flat
      };

      bind = [
        "$mod, Return, exec, alacritty"
        "$mod, B, exec, firefox"
        "$mod, Q, killactive"
        "$mod, Escape, exec, wlogout"
        "$mod, O, exec, alacritty -e yazi"
        "$mod, V, togglefloating"
        "$mod, D, exec, walker"
        "$mod, P, exec, cliphist list | fuzzel --dmenu | cliphist decode | wl-copy"
        "$mod SHIFT, P, exec, $HOME/.local/bin/clipboard-manager"
        "$mod, T, pseudo"
        "$mod, J, togglesplit"
        "$mod, L, exec, hyprlock"
        "$mod, F, fullscreen"

        # Move focus (Colemak-DH: m=left, n=down, e=up, i=right)
        "$mod, m, movefocus, l"
        "$mod, i, movefocus, r"
        "$mod, e, movefocus, u"
        "$mod, n, movefocus, d"

        # Move windows (Colemak-DH)
        "$mod SHIFT, m, movewindow, l"
        "$mod SHIFT, i, movewindow, r"
        "$mod SHIFT, e, movewindow, u"
        "$mod SHIFT, n, movewindow, d"

        # Scratchpad
        "$mod, S, togglespecialworkspace, scratchpad"
        "$mod SHIFT, S, movetoworkspace, special:scratchpad"

        # Screenshots & Recording (Omarchy-style)
        ", Print, exec, grim -g \"$(slurp)\" ~/Pictures/screenshots/$(date +%Y%m%d_%H%M%S).png"
        "SHIFT, Print, exec, grim -g \"$(hyprctl activewindow -j | jq -r '\"\\(.at[0]),\\(.at[1]) \\(.size[0])x\\(.size[1])\"')\" ~/Pictures/screenshots/$(date +%Y%m%d_%H%M%S).png"
        "CTRL, Print, exec, grim ~/Pictures/screenshots/$(date +%Y%m%d_%H%M%S).png"
        "ALT, Print, exec, pkill -x wf-recorder || wf-recorder -g \"$(slurp)\" -f ~/Videos/recordings/$(date +%Y%m%d_%H%M%S).mp4"
        "CTRL ALT, Print, exec, pkill -x wf-recorder || wf-recorder -f ~/Videos/recordings/$(date +%Y%m%d_%H%M%S).mp4"
        "SUPER, Print, exec, hyprpicker -a"

        # Notifications
        "$mod, comma, exec, makoctl dismiss"
        "$mod SHIFT, comma, exec, makoctl dismiss --all"

        # Helix Everywhere - edit text from anywhere
        "$mod SHIFT, H, exec, $HOME/.local/bin/helix-everywhere"

        # Help - show keybindings reference
        "$mod, slash, exec, $HOME/.local/bin/hypr-help"

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
        "$mod, mouse:272, movewindow" # SUPER + left-click to move
        "$mod, mouse:273, resizewindow" # SUPER + right-click to resize
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
      };

      # Subtle breathing animations
      animations = {
        enabled = true;
        bezier = [
          "breathe, 0.37, 0, 0.63, 1" # Smooth breathing ease curve
        ];
        animation = [
          "windows, 1, 5, breathe, slide"
          "windowsOut, 1, 5, breathe, slide"
          "border, 1, 10, breathe"
          "borderangle, 1, 15, breathe, loop"
          "fade, 1, 5, breathe"
          "workspaces, 1, 6, breathe, slide"
        ];
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
        "float, class:^(hypr-help)$"
        "size 60% 70%, class:^(hypr-help)$"
        "center, class:^(hypr-help)$"
      ];

      # Autostart applications
      exec-once = [
        "usbguard-notifier" # GUI notifications for USB device authorization
      ];
    };
  };

  # ZSH shell
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      kali = "sudo podman exec -it kali bash";
      cat = "bat";
      ls = "eza";
    };

    history = {
      size = 10000;
      path = "${config.home.homeDirectory}/.zsh_history";
    };

    initContent = ''
      # Case-insensitive completion
      zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'

      # Better completion menu
      zstyle ':completion:*' menu select

      # Colored completion
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
    '';
  };

  # Keep bash as fallback
  programs.bash = {
    enable = true;
    shellAliases = {
      kali = "sudo podman exec -it kali bash";
    };
  };

  # direnv - automatic environment switching
  programs.direnv = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    nix-direnv.enable = true; # Better Nix integration with caching
    config.global.hide_env_diff = true; # Suppress verbose export list
  };

  # fzf - command-line fuzzy finder
  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    defaultCommand = "fd --type f --hidden --exclude .git";
    defaultOptions = [
      "--height 40%"
      "--border"
      "--layout=reverse"
    ];
  };

  # Neovim with LazyVim support
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # Extra packages for mason.nvim compatibility
    extraPackages = with pkgs; [
      # Core build dependencies
      gcc
      gnumake
      unzip
      curl
      git
    ];
  };

  # Fuzzel launcher (styled by Stylix)
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        terminal = "${pkgs.alacritty}/bin/alacritty";
        layer = "overlay";
      };
    };
  };

  # Terminal (font handled by Stylix)
  programs.alacritty = {
    enable = true;
    settings = {
      window = {
        opacity = lib.mkForce 1.0; # Disable transparency to fix flickering
        blur = false; # Don't request blur from Alacritty, let Hyprland handle it
        padding = {
          x = 5;
          y = 5;
        };
      };

      # Removed debug renderer overrides - use Alacritty defaults
    };
  };

  # eza - modern ls replacement with icons
  programs.eza = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
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
    enableZshIntegration = true;
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
      #custom-recording {
        padding: 0 8px;
        color: #ff5555;
        font-weight: bold;
        animation: blink 1s ease-in-out infinite;
      }
      @keyframes blink {
        0% { opacity: 1; }
        50% { opacity: 0.5; }
        100% { opacity: 1; }
      }
    '';
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 36;

        modules-left = [
          "hyprland/workspaces"
          "hyprland/window"
        ];
        modules-center = [ "clock" ];
        modules-right = [
          "custom/recording"
          "pulseaudio"
          "custom/separator"
          "custom/hypridle"
          "custom/separator"
          "power-profiles-daemon"
          "custom/separator"
          "cpu"
          "memory"
          "custom/separator"
          "network"
          "battery"
          "custom/separator"
          "tray"
        ];

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
            default = [
              "󰕿"
              "󰖀"
              "󰕾"
            ];
          };
          on-click = "pwvucontrol";
        };

        "custom/recording" = {
          format = "{}";
          exec = "pgrep -x wf-recorder >/dev/null && echo '󰑊' || echo ''";
          interval = 1;
          tooltip-format = "Screen recording active";
        };

        "custom/hypridle" = {
          format = "{}";
          exec = "systemctl --user is-active hypridle.service &>/dev/null && echo '󰾪' || echo '󰅶'";
          interval = 2;
          signal = 8;
          on-click = "systemctl --user is-active hypridle.service &>/dev/null && (systemctl --user stop hypridle.service && notify-send 'Hypridle' 'Disabled - screen will not lock') || (systemctl --user start hypridle.service && notify-send 'Hypridle' 'Enabled - screen will lock after idle'); pkill -RTMIN+8 waybar";
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
          format-icons = [
            "󰂎"
            "󰁺"
            "󰁻"
            "󰁼"
            "󰁽"
            "󰁾"
            "󰁿"
            "󰂀"
            "󰂁"
            "󰂂"
            "󰁹"
          ];
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
    extraConfig = ''
      default-timeout=5000

      [app-name=breathe]
      anchor=center
      font=monospace 48
      width=1200
      height=400
      border-size=0
      background-color=#00000000
      text-color=#FFFFFFDD
      default-timeout=500
    '';
  };

  # Breathing reminder systemd service
  systemd.user.services.breathe-reminder = {
    Unit = {
      Description = "Subtle breathing reminder";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${config.home.homeDirectory}/.local/bin/breathe-reminder";
    };
  };

  # Breathing reminder timer - triggers randomly between 20s-30min
  systemd.user.timers.breathe-reminder = {
    Unit = {
      Description = "Timer for breathing reminders";
    };
    Timer = {
      OnBootSec = "1min"; # First trigger 1 minute after boot
      OnUnitActiveSec = "20s"; # Base interval of 20 seconds
      RandomizedDelaySec = "30min"; # Add random delay up to 30 minutes
      Persistent = false;
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };

  # Eye relief reminder systemd service
  systemd.user.services.eye-relief = {
    Unit = {
      Description = "Eye relief reminder (20-20-20 rule)";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${config.home.homeDirectory}/.local/bin/eye-relief";
    };
  };

  # Eye relief timer - triggers every 20 minutes
  systemd.user.timers.eye-relief = {
    Unit = {
      Description = "Timer for eye relief reminders";
    };
    Timer = {
      OnBootSec = "20min"; # First trigger 20 minutes after boot
      OnUnitActiveSec = "20min"; # Repeat every 20 minutes
      Persistent = false;
    };
    Install = {
      WantedBy = [ "timers.target" ];
    };
  };

  # Cliphist - clipboard history manager
  services.cliphist = {
    enable = true;
    allowImages = true;
  };

  # Hypridle - automatic idle management
  services.hypridle = {
    enable = true;
    settings = {
      general = {
        lock_cmd = "pidof hyprlock || hyprlock"; # Lock command (avoid starting hyprlock if already running)
        before_sleep_cmd = "loginctl lock-session"; # Lock before suspend
        after_sleep_cmd = "hyprctl dispatch dpms on"; # Turn display back on after resume
      };

      listener = [
        {
          timeout = 180; # 3 minutes
          on-timeout = "brightnessctl -s set 10%"; # Dim screen to 10%
          on-resume = "brightnessctl -r"; # Restore brightness
        }
        {
          timeout = 600; # 10 minutes
          on-timeout = "loginctl lock-session"; # Lock the session
        }
        {
          timeout = 630; # 10.5 minutes
          on-timeout = "hyprctl dispatch dpms off"; # Turn off display
          on-resume = "hyprctl dispatch dpms on"; # Turn display back on
        }
      ];
    };
  };

  # Gammastep - color temperature adjustment for day/night
  services.gammastep = {
    enable = true;
    provider = "manual";
    latitude = 39.7;  # Denver, CO (adjust to your location)
    longitude = -104.9;
    temperature = {
      day = 6500;    # Neutral white during day
      night = 3500;  # Warm at night (reduces blue light)
    };
    settings = {
      general.adjustment-method = "wayland";
    };
  };

  # zoxide - smarter cd command
  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };

  # Let Home Manager manage itself
  programs.home-manager.enable = true;
}
