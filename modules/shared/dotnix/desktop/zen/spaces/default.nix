{
  config,
  lib,
  dotnix-utils,
  ...
}: let
  cfg = config.dotnix.desktop.zen;
in {
  config = lib.mkIf cfg.enable {
    home-manager = dotnix-utils.hm.hmConfig {
      programs.zen-browser.profiles.default.spaces =
        lib.mkMerge (map import (dotnix-utils.path.listModules ./.));
    };
  };
}
