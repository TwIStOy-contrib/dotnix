{
  config,
  lib,
  pkgs,
  dotnix-utils,
  dotnix-constants,
  ...
}: let
  cfg = config.dotnix.apps.espanso;
  inherit (dotnix-constants) user;
  homeDir = config.users.users."${user.name}".home;
in {
  options.dotnix.apps.espanso = {
    enable = lib.mkEnableOption "Enable module dotnix.apps.espanso";
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.isDarwin;
        message = "Espanso is currently configured only for macOS in this module";
      }
    ];

    homebrew = {
      casks = ["espanso"];
    };

    home-manager = dotnix-utils.hm.hmConfig {
      home = {
        # Espanso configuration lives under $XDG_CONFIG_HOME/espanso.
        # Concrete match rules and config are intentionally left empty for
        # now and will be wired up incrementally.
        file = {
          "${homeDir}/.config/espanso/config/default.yml" = {
            enable = true;
            text = "";
            force = true;
          };
        };
      };
    };
  };
}
