# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## System Overview

This is a NixOS 25.05 flake-based configuration for a security workstation named "bamboo" featuring:
- **Impermanence**: Root filesystem wiped on every boot using BTRFS subvolumes
- **Secure Boot**: Lanzaboote for UEFI Secure Boot support
- **Full Disk Encryption**: LUKS encryption with LVM
- **Window Manager**: Hyprland (Wayland compositor) with Stylix theming
- **Secrets Management**: SOPS-nix with age encryption
- **Home Manager**: User environment configuration

## Common Commands

```bash
# Rebuild and activate configuration
sudo nixos-rebuild switch --flake .#bamboo

# Test configuration without activating
sudo nixos-rebuild test --flake .#bamboo

# Build configuration without activating
sudo nixos-rebuild build --flake .#bamboo

# Update all flake inputs
nix flake update

# Update specific input
nix flake lock --update-input nixpkgs

# Check configuration for errors
nix flake check

# Show flake outputs
nix flake show
```

## Architecture

### Flake Structure

The main `flake.nix` defines:
- **userConfig**: Centralized user settings (username, email, theme) passed to all modules via `specialArgs`
- **nixosConfigurations.bamboo**: Single host configuration
- **Module imports**: Hardware config, system, persistence, password-manager, home-manager

### Key Modules

**system.nix**: Core system configuration
- Bootloader with Lanzaboote (Secure Boot)
- LUKS encryption setup
- Impermanence root wiping script (runs during initrd)
- User accounts with SOPS-encrypted passwords
- Network, audio, SSH, Tailscale
- Logging and debugging configuration

**persistence.nix**: Impermanence configuration
- Defines what persists across reboots in `/persist/system`
- Boot-critical directories must be declared with explicit permissions
- SOPS configuration must reference keyFile in `/persist/system` (not ephemeral paths)
- User home directories and application data

**password-manager.nix**: Reusable module pattern
- Demonstrates how to create custom NixOS modules with options
- Supports multiple providers (1Password, Bitwarden)
- Uses `userConfig` for email configuration
- Shows pattern for filtering normal users with `lib.filterAttrs`

**home/default.nix**: Home Manager configuration
- User packages (security tools: Wireshark, Burp Suite, Caido, etc.)
- Hyprland window manager settings with Colemak-DH keybindings
- Alacritty terminal configuration
- Git configuration using `userConfig`

### Impermanence Implementation

The system wipes root on every boot using a BTRFS script in `boot.initrd.postDeviceCommands`:
1. Mounts root volume group
2. Moves current root to `old_roots/` with timestamp
3. Deletes root snapshots older than 30 days
4. Creates fresh root subvolume

**Critical patterns**:
- Boot-critical paths (SSH keys, Secure Boot PKI, SOPS keys) must be in `/persist/system`
- SOPS `age.keyFile` points to `/persist/system/etc/nixos/secrets/keys.txt`
- `sops.age.sshKeyPaths = []` to avoid timing issues with impermanence
- User secret `blyons_password` has `neededForUsers = true` flag
- Application data requiring persistence must be explicitly listed in `environment.persistence."/persist/system".users.<username>.directories`

### Secrets Management

SOPS-nix configuration:
- Secrets file: `/persist/system/etc/nixos/secrets.yaml`
- Age key: `/persist/system/etc/nixos/secrets/keys.txt`
- All secret paths must be in persistent storage to survive reboots
- User passwords accessed via `config.sops.secrets.<name>.path`

### Hardware Configuration

The `hardware-configuration.nix` defines:
- Filesystem mounts (BTRFS root, boot partition)
- Initial RAM disk modules
- CPU/GPU specific settings

It's typically auto-generated but customized for:
- LVM volume group paths
- BTRFS subvolume layout
- Encryption device mappings

### User Configuration Pattern

The `userConfig` attribute set in `flake.nix` provides centralized user settings:
```nix
userConfig = {
  full_name = "Brett Lyons";
  email_address = "blyons@fastmail.com";
  username = "blyons";
  theme = "tokyo-night";
};
```

Passed to all modules via `specialArgs`, allowing consistent configuration across system and home-manager.

## Hyprland Configuration

Window manager uses Colemak-DH keyboard layout with custom keybindings:
- Movement keys: m (left), n (down), e (up), i (right)
- Modifier: SUPER key
- Terminal: SUPER+Return (Alacritty)
- Application launcher: SUPER+R (Wofi)

Styling (colors, fonts, borders) managed by Stylix with tokyo-night-dark theme.

## Development Workflow

When modifying configuration:
1. Edit relevant `.nix` files
2. Test with `sudo nixos-rebuild test --flake .#bamboo` (non-persistent)
3. Verify no errors with `nix flake check`
4. Apply with `sudo nixos-rebuild switch --flake .#bamboo`
5. Commit changes to git

For persistence changes:
- Always verify boot-critical paths are correctly configured
- Test reboot to ensure system remains bootable
- User data loss can occur if directories not listed in persistence config

## Neovim / LazyVim Setup

Neovim is configured via Home Manager with LSP servers managed by Nix instead of mason.nvim.

**Important:** Stylix Neovim target is disabled (`stylix.targets.neovim.enable = false`) to allow LazyVim to manage the configuration. This prevents conflicts between Stylix's `init.lua` and LazyVim's configuration.

### Theming

To maintain consistent theming with the system (tokyo-night), configure LazyVim's colorscheme:

```lua
-- Add to ~/.config/nvim/lua/config/lazy.lua or create ~/.config/nvim/lua/plugins/colorscheme.lua
return {
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      style = "night",  -- Options: storm, night, moon, day
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight",
    },
  },
}
```

### Initial LazyVim Bootstrap

After rebuilding the system, bootstrap LazyVim:

```bash
# Remove Home Manager's nvim config directory (if it exists)
rm -rf ~/.config/nvim

# Clone LazyVim starter configuration
git clone https://github.com/LazyVim/starter ~/.config/nvim
cd ~/.config/nvim
rm -rf .git  # Remove git to make it your own config

# Launch neovim - LazyVim will install plugins automatically
nvim
```

### LSP Server Configuration

LSP servers are installed via Nix (see `home/default.nix`) and available system-wide:
- `lua-language-server` - Lua
- `nil` - Nix
- `rust-analyzer` - Rust
- `pyright` - Python
- `typescript-language-server` - TypeScript/JavaScript
- `bash-language-server` - Bash
- `vscode-langservers-extracted` - HTML/CSS/JSON/ESLint
- `markdown-oxide` - Markdown (Obsidian-inspired)

LazyVim will automatically detect these without needing mason.nvim installation.

**Note on Markdown LSP:** We use `markdown-oxide` instead of `marksman` because marksman is a pre-built binary with dynamic linking issues on NixOS. markdown-oxide is a Rust-based alternative that works perfectly on NixOS and offers Obsidian-like features (wiki links, daily notes, etc.).

### AI Coding Assistant Options

Several AI plugins work well with LazyVim:

**Option 1: avante.nvim** (Claude integration)
```lua
-- Add to ~/.config/nvim/lua/plugins/avante.lua
return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  opts = {
    provider = "claude",
    claude = {
      endpoint = "https://api.anthropic.com",
      model = "claude-sonnet-4-5-20250929",
      temperature = 0,
      max_tokens = 8000,
    },
  },
  dependencies = {
    "nvim-tree/nvim-web-devicons",
    "stevearc/dressing.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
  },
}
```

**Option 2: codecompanion.nvim** (Multi-provider support)
```lua
-- Add to ~/.config/nvim/lua/plugins/codecompanion.lua
return {
  "olimorris/codecompanion.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-treesitter/nvim-treesitter",
  },
  config = function()
    require("codecompanion").setup({
      adapters = {
        anthropic = require("codecompanion.adapters").use("anthropic", {
          env = {
            api_key = "ANTHROPIC_API_KEY",
          },
        }),
      },
    })
  end,
}
```

**Option 3: CopilotChat.nvim** (GitHub Copilot)
Requires GitHub Copilot subscription. LazyVim has built-in extras for this:
```bash
# In nvim, run:
:LazyExtras
# Enable copilot and copilot-chat
```

### Persistence Notes

Neovim directories are persisted across reboots:
- `~/.config/nvim` - Configuration
- `~/.local/share/nvim` - Plugin data
- `~/.local/state/nvim` - Shada/session files
- `~/.cache/nvim` - Plugin download cache

## Security Notes

- System uses full disk encryption (LUKS)
- Secure Boot enabled via Lanzaboote
- SSH only allows key-based authentication
- Root login disabled
- Firewall enabled by default
- Passwords managed via SOPS (never in cleartext in repo)
