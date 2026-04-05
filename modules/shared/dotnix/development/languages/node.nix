{
  config,
  pkgs-unstable,
  lib,
  dotnix-utils,
  ...
}: let
  cfg = config.dotnix.development.languages.node;
in {
  options.dotnix.development.languages.node = {
    enable = lib.mkEnableOption "Enable dev lang node";
  };

  config = lib.mkIf cfg.enable {
    dotnix.hm.packages = with pkgs-unstable; [
      nodejs
      yarn
      pnpm
      typescript
      typescript-language-server
      prettier # common code formatter
    ];
    home-manager =
      dotnix-utils.hm.hmConfig {
      };
  };
}
