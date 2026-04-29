{
  config,
  lib,
  dotnix-utils,
  dotnix-constants,
  ...
}: let
  cfg = config.dotnix.apps.codex;
  inherit (dotnix-constants) user;
  homeDir = config.users.users."${user.name}".home;
  codex = config."dotnix-pkgs".wrappedPrograms.codex;
in {
  options.dotnix.apps.codex = {
    enable = lib.mkEnableOption "Enable module dotnix.apps.codex";
  };

  config = lib.mkIf cfg.enable {
    dotnix.hm.packages = [
      codex
    ];

    home-manager = dotnix-utils.hm.hmConfig {
      home = {
        file = {
          "${homeDir}/.codex/config.toml" = {
            text = builtins.readFile ./config.toml;
            force = true;
          };
        };
      };
    };
  };
}
