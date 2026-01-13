{
  config,
  lib,
  dotnix-utils,
  ...
}: let
  cfg = config.dotnix.apps.difftastic;
in {
  options.dotnix.apps.difftastic = {
    enable = lib.mkEnableOption "Enable module dotnix.apps.difftastic";
  };

  config = lib.mkIf cfg.enable {
    home-manager = dotnix-utils.hm.hmConfig {
      programs.difftastic = {
        enable = true;
        git.enable = true;
      };
    };
  };
}
