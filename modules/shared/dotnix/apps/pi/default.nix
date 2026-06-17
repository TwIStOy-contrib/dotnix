{
  config,
  lib,
  dotnix-utils,
  dotnix-constants,
  dotnix-pkgs,
  ...
}: let
  cfg = config.dotnix.apps.pi;
  inherit (dotnix-constants) user;
  homeDir = config.users.users."${user.name}".home;
  piAgentKeybindings = {
    "app.session.rename" = "";
  };
in {
  options.dotnix.apps.pi = {
    enable = lib.mkEnableOption "Enable module dotnix.apps.pi";
  };

  config = lib.mkIf cfg.enable {
    dotnix.hm.packages = [
      dotnix-pkgs.wrapped-programs.pi
    ];

    home-manager = dotnix-utils.hm.hmConfig {
      home = {
        file = {
          "${homeDir}/.pi/agent/keybindings.json" = {
            text = builtins.toJSON piAgentKeybindings;
            force = true;
          };
        };
      };
    };
  };
}
