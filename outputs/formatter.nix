{
  flake-utils,
  nixpkgs-unstable,
  supportedSystems,
  ...
}:
flake-utils.lib.eachSystem supportedSystems (system: {
  formatter = nixpkgs-unstable.legacyPackages.${system}.alejandra;
})
