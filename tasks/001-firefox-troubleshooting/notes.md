# Notes: Firefox Troubleshooting

## System Context

### Recent Changes
- `flake.lock` updated: nixpkgs, home-manager, nixos-hardware, llm-agents.nix
- `system.nix` modified: added `virtio-win` package
- Recent commits don't touch Firefox/font config directly

### Firefox Configuration
- Firefox installed via `home.packages` (line 171 of home/default.nix)
- `tridactyl-native` also in home.packages (line 172)
- **NOT using `programs.firefox.enable`** - this is the issue for native messaging

### Font Configuration
- System fonts in system.nix (lines 121-139):
  - `noto-fonts`, `noto-fonts-cjk-sans`, `noto-fonts-color-emoji`
  - `CaskaydiaMono Nerd Font` for monospace
  - `Noto Serif` for serif, `Noto Sans` for sansSerif
- Stylix enables Tokyo Night Dark theme
- Only monospace font explicitly set in Stylix

### Native Messaging Setup
- System manifest exists: `/run/current-system/sw/lib/mozilla/native-messaging-hosts/org.kde.plasma.browser_integration.json`
- User manifests: `~/.mozilla/native-messaging-hosts/` has bitwarden and tridactyl only
- Per-user profile: only tridactyl
- **Gap**: plasma-browser-integration manifest not in Firefox's search path for user installs

## Root Cause Analysis

### Issue 1: Font Display in Right-Click Menu
**Root cause**: Corrupt fontconfig cache files
- Found: 6 invalid cache files in `~/.cache/fontconfig/`
- **Fix applied**: Cleared cache with `rm -rf ~/.cache/fontconfig/* && fc-cache -fv`
- **Action needed**: Restart Firefox to pick up new cache

### Issue 2: Plasma Integration Missing Native Backend
**Root cause**: Firefox installed via `home.packages` instead of `programs.firefox`
- `programs.firefox.nativeMessagingHosts` option exists in Home Manager
- When using `home.packages = [ pkgs.firefox ]`, native messaging hosts aren't auto-configured
- Need to switch to `programs.firefox.enable = true` with `nativeMessagingHosts` option

## Solution

### For fonts (immediate)
Restart Firefox after cache rebuild

### For Plasma integration (config change)
Change home/default.nix:
```nix
# Remove from home.packages:
# firefox

# Add programs.firefox configuration:
programs.firefox = {
  enable = true;
  nativeMessagingHosts = [
    pkgs.plasma-browser-integration
    pkgs.tridactyl-native
  ];
};
```

## Sources
- Home Manager options: programs.firefox.nativeMessagingHosts
- System file analysis: home/default.nix, system.nix, flake.nix
