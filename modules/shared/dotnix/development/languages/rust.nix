{
  config,
  pkgs-unstable,
  lib,
  dotnix-utils,
  ...
}: let
  cfg = config.dotnix.development.languages.rust;
in {
  options.dotnix.development.languages.rust = {
    enable = lib.mkEnableOption "Enable dev lang rust";
  };

  config = lib.mkIf cfg.enable {
    dotnix.hm.packages = with pkgs-unstable; [
      rust-analyzer
      rustc
      rustfmt
      cargo
      cargo-nextest
      cargo-outdated
      clippy
    ];
    home-manager = dotnix-utils.hm.hmConfig (
      lib.optionalAttrs pkgs-unstable.stdenv.isDarwin {
        home.file.".cargo/config.toml".text = ''
          [build]
          rustflags = ["-C", "link-arg=-L${pkgs-unstable.lib.getLib pkgs-unstable.libiconv}/lib"]
        '';
      }
    );
  };
}
