# Pre-Deployment Backup Checklist

## Critical Data Already Persisted ✅
Your current system already persists most data, but verify these are backed up:

### Browser Data
- `~/.mozilla/firefox/` - **Firefox profiles, logins, bookmarks** 
- `~/.config/` - Application configurations

### Development/Security Tools
- `~/.BurpSuite/` - BurpSuite configurations
- `~/.gnupg/` - GPG keys
- `~/.ssh/` - SSH keys

### Personal Data
- `~/Documents/`, `~/Downloads/`, `~/workspace/` etc. - All user directories

## Quick Backup Commands (Optional)
```bash
# Create backup directory
mkdir -p /tmp/nixos-backup

# Backup critical configs not in persistence
sudo cp -r /etc/nixos/ /tmp/nixos-backup/etc-nixos-backup
cp ~/.claude.json /tmp/nixos-backup/claude-settings-backup

# Verify current persistence mounts
mount | grep persist | head -10
```

## Post-Deploy Verification
After `nixos-rebuild switch --flake .#bamboo`:

1. **Browser**: Firefox should retain all logins and bookmarks
2. **SSH**: `ssh-add -l` should show your keys
3. **Git**: `git config --global user.name` should show "Brett Lyons"
4. **Tailscale**: `tailscale status` should show your network
5. **Applications**: BurpSuite, etc. should retain settings

## Emergency Rollback
If something goes wrong:
```bash
# Rollback to previous generation
sudo nixos-rebuild switch --rollback

# Or select generation at boot menu
reboot
# Select previous generation from boot menu
```

Your system is well-prepared with impermanence - most data is already safely persisted!