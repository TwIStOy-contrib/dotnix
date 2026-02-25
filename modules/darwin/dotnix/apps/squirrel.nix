{
  config,
  pkgs,
  lib,
  dotnix-utils,
  ...
}: let
  cfg = config.dotnix.apps.squirrel;
  toYAML = pkgs.lib.generators.toYAML {};
in {
  options.dotnix.apps.squirrel = {
    enable = lib.mkEnableOption "Squirrel - Rime for Mac";
  };
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.isDarwin;
        message = "Squirrel only works on macOS";
      }
    ];

    homebrew = {
      casks = ["squirrel-app"];
    };

    home-manager = dotnix-utils.hm.hmConfig {
      home.file."Library/Rime" = {
        source = pkgs.fetchFromGitHub {
          owner = "gaboolic";
          repo = "rime-shuangpin-fuzhuma";
          rev = "1.0.5";
          sha256 = "sha256-1RH4KO9VfG5ln/eMQqwzT/5QNfKevmTmaqCeWwUwnD8=";
        };
        recursive = true;
      };

      home.file."Library/Rime/squirrel.custom.yaml" = {
        force = true;
        source =
          (pkgs.formats.yaml {}).generate "squirrel.custom.yaml"
          {
            patch = {
              style = {
                font_point = 16;
                horizontal = true;
                color_scheme = "wechat_dark";
              };
              app_options = {
                "com.apple.Xcode" = {
                  ascii_mode = true;
                };
                "net.kovidgoyal.kitty" = {
                  ascii_mode = true;
                };
                "com.neovide.neovide" = {
                  ascii_mode = true;
                };
                "com.microsoft.VSCode" = {
                  ascii_mode = true;
                };
                "com.microsoft.VSCodeInsiders" = {
                  ascii_mode = true;
                };
                "com.1password.1password" = {
                  ascii_mode = true;
                };
                "com.runningwithcrayons.Alfred" = {
                  ascii_mode = true;
                };
              };
            };
          };
      };
    };
  };
}
