{
  config,
  lib,
  dotnix-utils,
  ...
}: let
  cfg = config.dotnix.darwin-shared-suit;
  inherit (dotnix-utils) enabled enableModules;
in {
  options.dotnix.darwin-shared-suit = {
    enable = lib.mkEnableOption "Enable shared-suit for all darwin hosts.";
  };

  config = lib.mkIf cfg.enable {
    dotnix = {
      shared-suit = enabled;
      suits.desktop = enabled;
      apps = enableModules [
        "aerospace"
        "espanso"
        "hammerspoon"
        "karabiner"
        "obsidian-cli"
        "pbcopy-paste"
        "ssh"
        "zed"
        "squirrel"
      ];
    };
  };
}
