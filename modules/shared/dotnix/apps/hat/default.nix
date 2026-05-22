{
  config,
  lib,
  pkgs,
  inputs,
  dotnix-utils,
  dotnix-constants,
  ...
}: let
  cfg = config.dotnix.apps.hat;
  hat = inputs.hat.packages.${pkgs.system}.default;
in {
  options.dotnix.apps.hat = {
    enable = lib.mkEnableOption "Enable module dotnix.apps.hat";
  };

  config = lib.mkIf cfg.enable {
    dotnix.hm.packages = [
      hat
    ];

    home-manager = dotnix-utils.hm.hmConfig {
      xdg.configFile."hat/config.toml" = {
        text = ''
          [database]
          memory_url = "{file:${config.age.secrets."dotcode-memory-db-url".path}}"
        '';
        force = true;
      };
    };
  };
}
