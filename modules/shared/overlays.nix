{inputs, ...}: {
  nixpkgs.overlays = [
    inputs.fenix.overlays.default
    (final: prev: {
      direnv = prev.direnv.overrideAttrs (_: {
        doCheck = false;
      });
      mise = prev.mise.overrideAttrs (_: {
        doCheck = false;
      });
    })
  ];
}
