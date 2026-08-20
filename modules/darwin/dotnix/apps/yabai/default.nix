{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  dotnix-constants,
  ...
}: let
  cfg = config.dotnix.apps.yabai;
  inherit (dotnix-constants) user;
  homeDir = config.users.users."${user.name}".home;
in {
  options.dotnix.apps.yabai = {
    enable = lib.mkEnableOption "Enable module dotnix.apps.yabai";
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isDarwin;
        message = "yabai is only available on macOS";
      }
    ];

    services.yabai = {
      enable = true;
      package = pkgs-unstable.yabai;

      enableScriptingAddition = true;
      extraConfig = builtins.readFile ./yabairc;
    };

    launchd.user.agents.yabai.serviceConfig = {
      StandardErrorPath = "${homeDir}/Library/Logs/yabai.stderr.log";
      StandardOutPath = "${homeDir}/Library/Logs/yabai.stdout.log";
    };

    launchd.daemons.yabai-sa = {
      # https://github.com/koekeishiya/yabai/issues/1287
      script = lib.mkForce ''
        echo "skip it"
      '';
    };
  };
}
