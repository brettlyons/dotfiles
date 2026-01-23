# Task Plan: Troubleshoot Firefox Issues

## Goal
Fix Firefox right-click menu font display and restore Plasma integration extension's native backend.

## Phases
- [x] Phase 1: Gather system context and recent changes
- [x] Phase 2: Research Firefox font and native messaging issues on NixOS
- [x] Phase 3: Identify root cause and implement fix
- [x] Phase 4: Test and verify both issues resolved

## Results
- **Fonts**: Working correctly after clearing corrupt fontconfig cache
- **Plasma Integration**: Native backend now detected after switching to `programs.firefox`

## Root Causes
1. **Font issue**: Corrupt fontconfig cache files in `~/.cache/fontconfig/`
2. **Plasma integration**: Firefox was in `home.packages` instead of `programs.firefox`, bypassing native messaging host configuration

## Changes Made
1. Cleared fontconfig cache: `rm -rf ~/.cache/fontconfig/* && fc-cache -fv`
2. Modified `home/default.nix`:
   - Removed `firefox` and `tridactyl-native` from `home.packages`
   - Added `programs.firefox` with `nativeMessagingHosts`:
     - `pkgs.kdePackages.plasma-browser-integration`
     - `pkgs.tridactyl-native`

## Status
**COMPLETE**
