{
  config,
  lib,
  dotnix-constants,
  dotnix-utils,
  ...
}: let
  inherit (dotnix-constants) user;
  cfg = config.dotnix.nixos-shared;
in {
  options.dotnix.nixos-shared = {
    enable = lib.mkEnableOption "Enable module dotnix.nixos-shared";
  };

  config = lib.mkIf cfg.enable {
    home-manager = dotnix-utils.hm.hmConfig {
      home.homeDirectory = lib.mkForce "/home/${user.name}";
      programs.ssh = {
        enable = true;
        matchBlocks = {
          "github.com" = {
            identityFile = config.age.secrets.remote-sign-key.path;
            identitiesOnly = true;
          };
        };
      };
    };

    dotnix.services.vscode-server = {
      enable = true;
    };
  };
}
