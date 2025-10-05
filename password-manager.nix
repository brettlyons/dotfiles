{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.passwordManager;
  normalUsers = builtins.attrNames (lib.filterAttrs 
    (name: user: user.isNormalUser) 
    config.users.users);
in
{
  options.services.passwordManager = {
    enable = mkEnableOption "password manager";

    provider = mkOption {
      type = types.enum [ "1password" "bitwarden" ];
      default = "1password";
      description = "Which password manager to use";
    };

    gui = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable GUI applications";
    };

    cli = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to enable CLI tools";
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # 1Password configuration
    (mkIf (cfg.provider == "1password") {
      programs._1password = mkIf cfg.cli {
        enable = true;
      };

      programs._1password-gui = mkIf cfg.gui {
        enable = true;
        polkitPolicyOwners = normalUsers;
      };
    })

    # Bitwarden configuration
    (mkIf (cfg.provider == "bitwarden") {
      environment.systemPackages = with pkgs; 
        (optional cfg.cli rbw) ++
        (optional cfg.gui goldwarden);

      # Optional: Configure rbw for CLI usage
      environment.etc."rbw/config.json" = mkIf cfg.cli {
        text = builtins.toJSON {
          email = ""; # User should set this
          base_url = "https://vault.bitwarden.com/";
          identity_url = "https://identity.bitwarden.com/";
          notifications_url = "https://notifications.bitwarden.com/";
        };
      };
    })
  ]);
}