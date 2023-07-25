{
  description = "the-argus nixos system configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-23.05";
    #nixpkgs-unstable.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager/release-23.05";
      # home manager use our nixpkgs and not its own
      inputs.nixpkgs.follows = "nixpkgs";
    };

    };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    ...
  } : {
    createNixosConfiguration = nixpkgs.lib.nixosSystem {

      };

   
};
}
