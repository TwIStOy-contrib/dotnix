{
  config,
  pkgs,
  pkgs-unstable,
  lib,
  dotnix-utils,
  ...
}: let
  cfg = config.dotnix.development.languages.typescript;
in {
  options.dotnix.development.languages.typescript = {
    enable = lib.mkEnableOption "Enable dev lang typescript";
  };

  config = lib.mkIf cfg.enable {
    dotnix.hm.packages =
      (with pkgs-unstable.nodePackages; [
        typescript
        typescript-language-server
        prettier
      ])
      ++ (with pkgs; [
        bun
        mise
      ]);

    home-manager = dotnix-utils.hm.hmConfig {};
  };
}
