{inputs, ...}:
{
  
   service.emacs = {
      enable = true;
   };
   imports =
   [
      # ./hardware-configuration.nix
      # inputs.home-manager.nixosModules.default
      inputs.doom-emacs.hmModule
   ];
}
