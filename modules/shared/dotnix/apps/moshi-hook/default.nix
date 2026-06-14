{
  config,
  lib,
  pkgs,
  dotnix-utils,
  ...
}: let
  cfg = config.dotnix.apps.moshi-hook;
  moshi-hook = pkgs.callPackage ./package.nix {};
in {
  options.dotnix.apps.moshi-hook = {
    enable = lib.mkEnableOption "Enable module dotnix.apps.moshi-hook";
  };

  config = lib.mkIf cfg.enable {
    dotnix.hm.packages = [
      moshi-hook
    ];
  };
}
