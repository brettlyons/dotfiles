# KDE Bluetooth/WiFi Toggle Hotkey

## Goal
Create a hotkey-activated fzf-style menu to toggle bluetooth and wifi on KDE (Bazzite).

## Requirements
- Hotkey binding in KDE to launch the menu
- fzf-style fuzzy finder interface (e.g., rofi, wofi, or fzf in a terminal)
- Options to toggle:
  - Bluetooth on/off
  - WiFi on/off
- Show current status of each in the menu

## WiFi Network Selection
- List available WiFi networks via fzf menu
- Show signal strength and security type
- Password entry dialog for secured networks (rofi password mode or kdialog)
- Connect to selected network

## Bluetooth Device Selection
- List available/paired Bluetooth devices via fzf menu
- Show device type and connection status
- Pair with new devices (handle PIN entry if needed)
- Connect/disconnect from selected device

## Implementation Ideas
- Use `bluetoothctl` for bluetooth control
- Use `nmcli` for wifi control
- Rofi/wofi script for the menu interface
- KDE custom shortcut to launch the script

## Status
- [ ] Not started
