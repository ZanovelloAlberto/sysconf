{
  description = "nixos conf";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-23.05";
    #nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-23.05";
      # home manager use our nixpkgs and not its own
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim-nightly-overlay = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim-plugins = {
      url = "github:LongerHV/neovim-plugins-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    #nvim-config = {
    #   url = "github:the-argus/nvim-config/67e6def89dd1dd32bfcd1be9077a554cf06e1cc4";
    #   inputs.nixpkgs.follows = "nixpkgs-unstable";
    # };

  };

  outputs =
    { self
    , nixpkgs
    , neovim-plugins
    , neovim-nightly-overlay
    , home-manager
    , ...
    }@inputs:
    let
      # forAllSystems = nixpkgs.lib.genAttrs flake-utils.lib.defaultSystems;

      system = "x86_64-linux";


      overlays = rec {
        neovimNightly = neovim-nightly-overlay.overlay;
        neovimPlugins = neovim-plugins.overlays.default;
      };
      legacyPackages =
        import nixpkgs {
          inherit system;
          overlays = builtins.attrValues overlays;
          config.allowUnfree = true;
        };

    in
    {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        pkgs = legacyPackages;
        specialArgs = inputs;
        modules = [ ./configuration.nix ];
      };

    };
}
