{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  dotnix-constants,
  dotnix-utils,
  ...
}
: let
  cfg = config.dotnix.apps.hammerspoon;
  inherit (dotnix-constants) user;
  homeDir = config.users.users."${user.name}".home;
  inherit (pkgs-unstable) yabai;

  hammerspoon = pkgs.writeShellScriptBin "hs" ''
    #!${pkgs.bash}/bin/bash
    /opt/homebrew/bin/hs "$@"
  '';

  stackline-src = pkgs.fetchFromGitHub {
    owner = "TwIStOy";
    repo = "stackline";
    rev = "master";
    sha256 = "sha256-x7SIgKR6rwkoVVbaAvjFr1N7wTF3atni/d6xGLBBRN4=";
  };

  init-stackline = ''
    local stackline = require "stackline"
    stackline:init({
      paths = {
        yabai = "${yabai}/bin/yabai",
      }
    })
    stackline.config:set('appearance.size', 40)
  '';

  init-ipc-aarch = ''
    hs.ipc.cliInstall("/opt/homebrew")
  '';

  init-ipc-x86 = ''
    hs.ipc.cliInstall()
  '';
in {
  options.dotnix.apps.hammerspoon = {
    enable = lib.mkEnableOption "Hammerspoon";
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = pkgs.stdenv.hostPlatform.isDarwin;
        message = "Hammerspoon only works on macOS";
      }
    ];

    homebrew = {
      casks = [
        "hammerspoon"
      ];
    };

    # setup the Hammerspoon configuration
    home-manager = dotnix-utils.hm.hmConfig {
      home = {
        packages = lib.lists.optionals (with pkgs.stdenv; (isDarwin && (isAarch32 || isAarch64))) [
          hammerspoon
        ];

        # TODO(hawtian): link stackline and init-stackline
        file = {
          "${homeDir}/.hammerspoon/init.lua" = {
            text =
              if (pkgs.stdenv.isAarch32 || pkgs.stdenv.isAarch64)
              then ''
                ${init-ipc-aarch}
                ${init-stackline}
              ''
              else ''
                ${init-ipc-x86}
                ${init-stackline}
              '';
            force = true;
          };
          "${homeDir}/.hammerspoon/stackline" = {
            source = stackline-src;
            force = true;
          };
        };
      };
    };
  };
}
