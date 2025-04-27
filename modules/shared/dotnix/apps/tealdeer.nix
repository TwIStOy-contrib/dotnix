{
  config,
  lib,
  dotnix-utils,
  pkgs,
  pkgs-unstable,
  ...
}: let
  cfg = config.dotnix.apps.tealdeer;
  settingsFormat = pkgs.formats.toml {};
  configFile = settingsFormat.generate "config.toml" {
    updates.auto_update = true;
  };
in {
  options.dotnix.apps.tealdeer = {
    enable = lib.mkEnableOption "Enable module dotnix.apps.tealdeer";
  };

  config = lib.mkIf cfg.enable {
    dotnix.hm.packages = with pkgs-unstable; [
      tealdeer
    ];

    home-manager =
      dotnix-utils.hm.hmConfig
      (
        if pkgs.stdenv.isDarwin
        then {
          home.file."Library/Application Support/tealdeer/config.toml".source = configFile;
        }
        else {
          xdg.configFile."tealdeer/config.toml".source = configFile;
        }
      );
  };
}
