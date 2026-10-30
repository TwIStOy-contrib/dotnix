{
  config,
  lib,
  pkgs,
  dotnix-utils,
  ...
}: let
  cfg = config.dotnix.apps.terminal-browser;
  # The bundle lives read-only in the store, so `terminal-browser upgrade`
  # cannot work; bump version/hashes in ./package.nix instead.
  terminal-browser = pkgs.callPackage ./package.nix {};
in {
  options.dotnix.apps.terminal-browser = {
    enable = lib.mkEnableOption "terminal-browser, a Chromium browser rendered inside the terminal";
  };

  config = lib.mkIf cfg.enable {
    dotnix.hm.packages = [
      terminal-browser
    ];
  };
}
