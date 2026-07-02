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
      # docker_28 is marked unmaintained/insecure in nixos-25.11; pin the
      # default `docker` alias to docker_29 so every consumer (the
      # virtualisation module, github-runners, etc.) gets a non-insecure
      # build without touching each call site.
      docker = prev.docker_29;
    })
  ];
}
