{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}: let
  cfg = config.dotnix.apps.ollama;
in {
  options.dotnix.apps.ollama = {
    enable = lib.mkEnableOption "Enable module dotnix.apps.ollama";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs-unstable; [
      ollama
    ];

    services = lib.optionalAttrs (!pkgs.stdenv.hostPlatform.isDarwin) {
      ollama = {
        enable = true;
        package = pkgs-unstable.ollama;
      };
    };
  };
}
