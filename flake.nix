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

    impermanence = {
      url = "github:nix-community/impermanence";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
    };

    llm-agents = {
      url = "github:numtide/llm-agents.nix";
    };
  };

  outputs = { self, nixpkgs, home-manager, stylix, impermanence, sops-nix, nixos-hardware, llm-agents, ... }:
  let
    system = "x86_64-linux";

    # User configuration variables
    userConfig = {
      full_name = "Brett Lyons";
      email_address = "blyons@fastmail.com";
      username = "blyons";
    };
  in {
    nixosConfigurations = {
      homecore-ops = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit userConfig; };
        modules = [
          # Hardware configuration
          ./hardware-configuration.nix
          nixos-hardware.nixosModules.common-gpu-intel  # Disabled: intel-graphics-compiler fails with CMake 4.0

          # Core modules
          stylix.nixosModules.stylix
          home-manager.nixosModules.home-manager
          impermanence.nixosModules.impermanence
          sops-nix.nixosModules.sops

          # Custom modules
          ./password-manager.nix
          ./system.nix
          ./persistence.nix

          # Main configuration
          ({ userConfig, pkgs, ... }: {
            # Allow unfree packages
            nixpkgs.config.allowUnfree = true;

            # Password manager
            services.passwordManager.enable = true;

            # Stylix theming
            stylix = {
              enable = true;
              polarity = "dark";
              image = ./fractals_designs_4k.jpg;
              base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-night-dark.yaml";
              # base16Scheme = "${pkgs.base16-schemes}/share/themes/onedark-dark.yaml";
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
              extraSpecialArgs = { inherit userConfig llm-agents; };
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
