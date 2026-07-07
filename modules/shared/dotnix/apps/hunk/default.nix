{
  config,
  inputs,
  lib,
  pkgs,
  dotnix-utils,
  ...
}: let
  cfg = config.dotnix.apps.hunk;
  hunk = inputs.hunk.packages.${pkgs.system}.default;
in {
  options.dotnix.apps.hunk = {
    enable = lib.mkEnableOption "Enable module dotnix.apps.hunk";
  };

  config = lib.mkIf cfg.enable {
    dotnix.hm.packages = [
      hunk
    ];
  };
}
