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
        # home-manager's defaults (forwardAgent=false, compression=false,
        # controlMaster="no", ...) are just OpenSSH's built-in defaults;
        # skip writing them and silence the removal warning.
        enableDefaultConfig = false;
        matchBlocks = {
          "github.com" = {
            identityFile = config.age.secrets.remote-sign-key.path;
            # never consult the agent; a forwarded/broken SSH_AUTH_SOCK must not affect git
            identityAgent = "none";
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
