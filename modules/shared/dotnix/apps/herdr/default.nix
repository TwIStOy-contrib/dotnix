{
  config,
  inputs,
  lib,
  pkgs,
  pkgs-unstable,
  dotnix-utils,
  ...
}: let
  cfg = config.dotnix.apps.herdr;
  herdr = inputs.herdr.packages.${pkgs.system}.default;
  settingsFormat = pkgs.formats.toml {};
  fish = pkgs-unstable.fish;
  herdrConfig = {
    terminal = {
      default_shell = "${fish}/bin/fish";
      new_cwd = "follow";
    };
    keys = {
      prefix = "ctrl+g";
    };
  };
in {
  options.dotnix.apps.herdr = {
    enable = lib.mkEnableOption "Enable module dotnix.apps.herdr";
  };

  config = lib.mkIf cfg.enable {
    dotnix.hm.packages = [
      herdr
    ];

    home-manager = dotnix-utils.hm.hmConfig {
      xdg.configFile."herdr/config.toml" = {
        source = settingsFormat.generate "herdr-config.toml" herdrConfig;
        force = true;
      };
    };
  };
}
