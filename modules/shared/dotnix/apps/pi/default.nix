{
  config,
  lib,
  dotnix-utils,
  dotnix-pkgs,
  ...
}: let
  cfg = config.dotnix.apps.pi;
in {
  options.dotnix.apps.pi = {
    enable = lib.mkEnableOption "Enable module dotnix.apps.pi";
  };

  config = lib.mkIf cfg.enable {
    dotnix.hm.packages = [
      dotnix-pkgs.wrapped-programs.pi
    ];
  };
}
