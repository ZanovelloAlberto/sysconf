{
  description = "nixos conf";
  inputs = {
    nixpkgs = {
      # url = "github:nixos/nixpkgs";
      # url = "github:nixos/nixpkgs/master";
      url = "nixpkgs/nixos-23.05";
 };
    #nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    # doom-emacs = {
    #   url = "github:nix-community/nix-doom-emacs";
    # };

    home-manager = {
      url = "github:nix-community/home-manager/release-23.05";
      # home manager use our nixpkgs and not its own
      inputs.nixpkgs.follows = "nixpkgs";
    };
   
  };

  outputs =
    { self
    , nixpkgs
      # , neovim-plugins
      # , neovim-nightly-overlay
      # , home-manager
    , ...
    }@inputs:
    let
      # forAllSystems = nixpkgs.lib.genAttrs flake-utils.lib.defaultSystems;

      system = "x86_64-linux";


      # overlays = rec {
      #   neovimNightly = neovim-nightly-overlay.overlay;
      #   neovimPlugins = neovim-plugins.overlays.default;
      # };
      # legacyPackages =
      #   import nixpkgs {
      #     inherit system;
      #     overlays = builtins.attrValues overlays;
      #     config.allowUnfree = true;
      #   };

    in
    rec
    {

      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        inherit system;
        # pkgs = legacyPackages;
        specialArgs = {
          inherit inputs;
        };
        # specialArgs = inputs;
        modules = [ ./configuration.nix ];
      };

    };
}
