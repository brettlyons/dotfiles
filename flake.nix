{
  description = "Security workstation configuration with Hyprland, Stylix, and tokyo-night theme";

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
  };

  outputs = { self, nixpkgs, home-manager, stylix, hyprland, ... }: 
  let
    system = "x86_64-linux";
    
    # User configuration variables
    userConfig = {
      full_name = "Security Analyst";
      email_address = "analyst@localhost";
      username = "blyons";
      theme = "tokyo-night";
    };
  in {
    nixosConfigurations = {
      # Replace with your hostname
      security-ws = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit userConfig; };
        modules = [
          # Core modules
          stylix.nixosModules.stylix
          hyprland.nixosModules.default
          home-manager.nixosModules.home-manager
          
          # Custom modules
          ./password-manager.nix
          
          # Main configuration
          ({ userConfig, ... }: {
            # Enable Hyprland
            programs.hyprland.enable = true;
            
            # Password manager
            services.passwordManager.enable = true;
            
            # Stylix theming
            stylix = {
              enable = true;
              base16Scheme = "${nixpkgs}/lib/colors/base16/tokyo-night-dark.yaml";
            };
            
            # Home Manager integration
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              extraSpecialArgs = { inherit userConfig; };
              users.${userConfig.username} = {
                imports = [ 
                  stylix.homeManagerModules.stylix
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