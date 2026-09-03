{
  config,
  lib,
  pkgs,
  dotnix-utils,
  ...
}: let
  cfg = config.dotnix.apps.nvrh;
in {
  options.dotnix.apps.nvrh = {
    enable = lib.mkEnableOption "nvrh, a remote helper for Neovim (VSCode Remote-like)";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ./package.nix {};
      description = "The nvrh package to use.";
    };
  };

  config = lib.mkIf cfg.enable {
    dotnix.hm.packages = [
      cfg.package
    ];
  };
}
