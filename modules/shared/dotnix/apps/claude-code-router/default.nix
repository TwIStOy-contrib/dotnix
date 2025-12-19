{
  pkgs,
  pkgs-unstable,
  config,
  lib,
  dotnix-utils,
  dotnix-constants,
  ...
}: let
  cfg = config.dotnix.apps.claude-code-router;
  ccr = pkgs.callPackage ./package.nix {};
in {
  options.dotnix.apps.claude-code-router = {
    enable = lib.mkEnableOption "Enable module dotnix.apps.claude-code-router";
  };

  config = lib.mkIf cfg.enable {
    dotnix.hm.packages = [
      ccr
    ];
  };
}
