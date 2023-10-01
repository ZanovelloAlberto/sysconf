{
  description = "nixos conf";
  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-23.05";
      # url = "github:nixos/nixpkgs/master";
    };

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
      system = "x86_64-linux";
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
