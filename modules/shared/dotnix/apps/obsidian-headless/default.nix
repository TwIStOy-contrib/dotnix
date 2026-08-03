{
  pkgs,
  config,
  lib,
  dotnix-utils,
  dotnix-constants,
  ...
}: let
  cfg = config.dotnix.apps.obsidian-headless;
  obsidian-headless = pkgs.callPackage ./package.nix {};
in {
  options.dotnix.apps.obsidian-headless = {
    enable = lib.mkEnableOption "Enable module dotnix.apps.obsidian-headless";
  };

  config = lib.mkIf cfg.enable {
    dotnix.hm.packages = [
      obsidian-headless
    ];
  };
}
