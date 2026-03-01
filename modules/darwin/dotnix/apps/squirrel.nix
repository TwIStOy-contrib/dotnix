{
  config,
  pkgs,
  lib,
  dotnix-utils,
  ...
}: let
  cfg = config.dotnix.apps.squirrel;
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
          rev = "db7bc4e9c8eb7cbff51e61dcc76f1d88d0255343";
          sha256 = "sha256-39STMvHWcix3C11ZXUicEXg1wa8sj4KinVY3aMQHYE4=";
        };
        recursive = true;
      };
    };
  };
}
