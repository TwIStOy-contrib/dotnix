{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}: let
  cfg = config.dotnix.apps.todoist;
in {
  options.dotnix.apps.todoist = {
    enable = lib.mkEnableOption "Enable module dotnix.apps.todoist";
  };

  config = lib.mkIf cfg.enable {
    dotnix.hm.packages = with pkgs-unstable; [
      todoist
    ];

    homebrew = lib.optionalAttrs pkgs.stdenv.isDarwin {
      casks = ["todoist"];
    };
  };
}
