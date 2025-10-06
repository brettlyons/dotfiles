{
  description = "Workstation configuration with Hyprland, Stylix, and tokyo-night theme";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    impermanence = {
      url = "github:nix-community/impermanence";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, stylix, hyprland, impermanence, sops-nix, lanzaboote, ... }:
  let
    system = "x86_64-linux";

    # User configuration variables
    userConfig = {
      full_name = "Brett Lyons";
      email_address = "blyons@fastmail.com";
      username = "blyons";
      theme = "tokyo-night";
    };
  in {
    nixosConfigurations = {
      bamboo = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit userConfig; };
        modules = [
          # Hardware configuration
          ./hardware-configuration.nix

          # Core modules
          stylix.nixosModules.stylix
          hyprland.nixosModules.default
          home-manager.nixosModules.home-manager
          impermanence.nixosModules.impermanence
          sops-nix.nixosModules.sops
          lanzaboote.nixosModules.lanzaboote

          # Custom modules
          ./password-manager.nix
          ./system.nix
          ./persistence.nix

          # Main configuration
          ({ userConfig, pkgs, ... }: {
            # Allow unfree packages
            nixpkgs.config.allowUnfree = true;

            # # Enable Hyprland
            # programs.hyprland.enable = true;

            # Password manager
            services.passwordManager.enable = true;

            # Stylix theming
            stylix = {
              enable = true;
              polarity = "dark";
              image = ./fractals_designs_4k.jpg;
              base16Scheme = "${pkgs.base16-schemes}/share/themes/onedark-dark.yaml";
              # base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-night-dark.yaml";
              fonts = {
                monospace = {
                  package = pkgs.nerd-fonts.caskaydia-mono;
                  name = "CaskaydiaMono Nerd Font";
                };
              };
            };

            # Home Manager integration
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";
              extraSpecialArgs = { inherit userConfig; };
              users.${userConfig.username} = {
                imports = [
                  ./home/default.nix
                ];
              };
            };
          })
        ];
      };
    };
  };
}
