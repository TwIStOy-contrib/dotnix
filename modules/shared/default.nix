{dotnix-utils, ...}: {
  imports =
    [
      ../../lib/pkgs
    ]
    ++ dotnix-utils.path.listModules ./.;
}
