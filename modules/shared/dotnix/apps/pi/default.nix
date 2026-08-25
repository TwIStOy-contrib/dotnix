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

    recommendedSettings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = {
        theme = "catppuccin-mocha";
      };
      description = "Recommended Pi settings serialized as the top-level JSON object recommended.json.";
    };

    enforcedSettings = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything;
      default = {
        retry.maxRetries = 100;
        tuiMode = "fullscreen";
        terminal.showTerminalProgress = true;
        enableInstallTelemetry = false;
        defaultProjectTrust = "always";
      };
      description = "Enforced Pi settings serialized as the top-level JSON object enforced.json.";
    };
  };

  config = lib.mkIf cfg.enable {
    dotnix.hm.packages = [
      dotnix-pkgs.wrapped-programs.pi
      dotnix-pkgs.wrapped-programs.piReal
    ];

    home-manager = dotnix-utils.hm.hmConfig {
      xdg.configFile = {
        "htw/pi-config/recommended.json".text = builtins.toJSON cfg.recommendedSettings;
        "htw/pi-config/enforced.json".text = builtins.toJSON cfg.enforcedSettings;
      };

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
