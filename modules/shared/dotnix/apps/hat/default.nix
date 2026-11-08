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
  # nixpkgs-unstable now forces pkg-config for Rust system libs; hat's package
  # does not declare sqlite yet, so building it from source fails to link.
  hat = inputs.hat.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
    buildInputs = (old.buildInputs or []) ++ [pkgs.sqlite.out];
  });
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
