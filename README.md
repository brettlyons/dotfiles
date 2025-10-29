# NixOS Dotfiles

Personal NixOS flake configuration for a security workstation with impermanence, Secure Boot, and full disk encryption.

## Features

- **Impermanence**: Root filesystem wiped on boot via BTRFS snapshots
- **Secure Boot**: Lanzaboote for UEFI Secure Boot
- **Full Disk Encryption**: LUKS + LVM
- **Secrets Management**: SOPS-nix with age encryption
- **Desktop**: Hyprland (Wayland) with Stylix theming (Tokyo Night)
- **Security Tools**: Wireshark, Burp Suite, Caido, Nmap, forensics tools
- **Editors**: Neovim/LazyVim, Emacs/Doom, Helix, VSCode

## Quick Start

```bash
# Clone repository
git clone https://github.com/yourusername/dotfiles.git ~/workspace/dotfiles
cd ~/workspace/dotfiles

# Customize userConfig in flake.nix (username, email, theme)
# Set up SOPS age key and secrets (see CLAUDE.md for details)
# Update hardware-configuration.nix for your system

# Build and activate
sudo nixos-rebuild switch --flake .#bamboo
```

## Common Commands

```bash
# Rebuild system
sudo nixos-rebuild switch --flake .#bamboo

# Update all dependencies
nix flake update

# Update specific input
nix flake lock --update-input nixpkgs

# Check configuration
nix flake check
```

## Hyprland Keybindings

Uses Colemak-DH movement keys:

- `SUPER + Return` - Terminal (Alacritty)
- `SUPER + D` - App launcher (Walker)
- `SUPER + B` - Browser (Firefox)
- `SUPER + Q` - Close window
- `SUPER + M/N/E/I` - Move focus left/down/up/right
- `SUPER + L` - Lock screen

Full keybindings in `home/default.nix:313-385`.

## Documentation

- **CLAUDE.md** - Comprehensive architecture and development guide
- **NixOS Manual** - https://nixos.org/manual/nixos/stable/
- **Home Manager** - https://nix-community.github.io/home-manager/
- **Impermanence** - https://github.com/nix-community/impermanence
- **SOPS-nix** - https://github.com/Mic92/sops-nix
- **Hyprland** - https://wiki.hyprland.org/

## Structure

```
flake.nix               # Main configuration entry point
system.nix              # Core system (boot, users, networking)
persistence.nix         # Impermanence declarations
password-manager.nix    # Password manager module
home/default.nix        # User environment & packages
```

## License

Personal configuration - use at your own risk.
