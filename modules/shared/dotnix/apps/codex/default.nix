{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  dotnix-utils,
  dotnix-constants,
  ...
}: let
  cfg = config.dotnix.apps.codex;
  inherit (dotnix-constants) user;
  homeDir = config.users.users."${user.name}".home;
  openrouterApiKeyPath = config.age.secrets."openrouter-api-key".path;
  codex = pkgs.writeShellScriptBin "codex" ''
    export OPENROUTER_API_KEY="$(cat ${openrouterApiKeyPath})"
    exec ${pkgs-unstable.codex}/bin/codex "$@"
  '';
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
