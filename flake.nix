{
  description = "Substitute secrets into files using agenix.";

  outputs = { ... }: {
    nixosModules.default = import ./modules/nixos.nix;
    homeManagerModules.default = import ./modules/hm.nix;
  };
}