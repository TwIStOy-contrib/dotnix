{inputs, ...}: {
  nixpkgs.overlays = [
    inputs.fenix.overlays.default
    (final: prev: {
      direnv = prev.direnv.overrideAttrs (_: {
        doCheck = false;
      });
      docker = prev.docker_29;
    })
  ];
}
