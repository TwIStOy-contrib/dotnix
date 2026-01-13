{
  config,
  lib,
  dotnix-utils,
  pkgs,
  ...
}: let
  cfg = config.dotnix.apps.lazygit;
in {
  options.dotnix.apps.lazygit = {
    enable = lib.mkEnableOption "Enable module dotnix.apps.lazygit";
  };

  config = lib.mkIf cfg.enable {
    home-manager = dotnix-utils.hm.hmConfig {
      programs.lazygit = {
        enable = true;
        package = pkgs.lazygit;
        settings = {
          gui = {
            mouseEvents = true;
            nerdFontsVersion = "3";
            border = "single";
          };
          notARepository = "skip";
          git = {
            parseEmoji = true;
            pagers = [
              {
                pager = "delta --dark --paging=never";
              }
              {
                externalDiffCommand = "difft --color=always";
              }
            ];
          };
        };
      };
    };
  };
}
