{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.dotnix.apps.tgt;
  tgt = inputs.tgt.packages.${pkgs.system}.default;
in {
  options.dotnix.apps.tgt = {
    enable = lib.mkEnableOption "Enable module dotnix.apps.tgt";
  };

  config = lib.mkIf cfg.enable {
    dotnix.hm.packages = [
      tgt
    ];
  };
}
