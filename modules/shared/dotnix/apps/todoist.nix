{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}: let
  cfg = config.dotnix.apps.todoist;
  todoistApiKeyPath = config.age.secrets."todoist-api-key".path;
  todoist = pkgs-unstable.writeShellScriptBin "todoist" ''
    export TODOIST_TOKEN="$(cat ${todoistApiKeyPath})"
    exec ${pkgs-unstable.todoist}/bin/todoist "$@"
  '';
in {
  options.dotnix.apps.todoist = {
    enable = lib.mkEnableOption "Enable module dotnix.apps.todoist";
  };

  config = lib.mkIf cfg.enable {
    dotnix.hm.packages = [
      todoist
    ];

    homebrew = lib.optionalAttrs pkgs.stdenv.isDarwin {
      casks = ["todoist"];
    };
  };
}
