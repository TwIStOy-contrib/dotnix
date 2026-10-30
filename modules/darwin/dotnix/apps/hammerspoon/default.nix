{
  config,
  lib,
  pkgs,
  dotnix-constants,
  dotnix-utils,
  ...
}
: let
  cfg = config.dotnix.apps.hammerspoon;
  inherit (dotnix-constants) user;
  homeDir = config.users.users."${user.name}".home;

  hammerspoon = pkgs.writeShellScriptBin "hs" ''
    #!${pkgs.bash}/bin/bash
    /opt/homebrew/bin/hs "$@"
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
    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Additional Hammerspoon Lua configuration.";
    };
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

        file = {
          "${homeDir}/.hammerspoon/init.lua" = {
            text =
              (
                if (pkgs.stdenv.isAarch32 || pkgs.stdenv.isAarch64)
                then init-ipc-aarch
                else init-ipc-x86
              )
              + cfg.extraConfig;
            force = true;
          };
        };
      };
    };
  };
}
