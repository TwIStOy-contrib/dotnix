{
  config,
  lib,
  pkgs,
  inputs,
  dotnix-utils,
  ...
}: let
  cfg = config.dotnix.development.portal;
  portal = pkgs.rustPlatform.buildRustPackage {
    pname = "portal";
    version = "unstable-${inputs.portal.shortRev or "dirty"}";
    src = inputs.portal;
    cargoLock.lockFile = "${inputs.portal}/Cargo.lock";
    nativeBuildInputs = [pkgs.pkg-config];
    buildInputs = [pkgs.openssl];
  };

  tunnelType = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Tunnel name";
      };
      host = lib.mkOption {
        type = lib.types.str;
        description = "SSH host from ~/.ssh/config";
      };
      mode = lib.mkOption {
        type = lib.types.enum ["local" "remote"];
        description = "Forwarding mode";
      };
      local = lib.mkOption {
        type = lib.types.str;
        description = "Local listen address (addr:port)";
      };
      remote = lib.mkOption {
        type = lib.types.str;
        description = "Remote target address (addr:port)";
      };
    };
  };

  portalConfig =
    {}
    // lib.optionalAttrs (cfg.forwards != []) {
      inherit (cfg) forwards;
    }
    // lib.optionalAttrs (cfg.tunnels != []) {
      inherit (cfg) tunnels;
    };
  hasConfig = cfg.forwards != [] || cfg.tunnels != [];
in {
  options.dotnix.development.portal = {
    enable = lib.mkEnableOption "Enable portal SSH tunnel manager";

    forwards = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Short-format forwarding rules: \"<ssh-host> -L|-R <listen-addr> <target-addr>\"";
      example = ["my-server -L 127.0.0.1:15432 127.0.0.1:5432"];
    };

    tunnels = lib.mkOption {
      type = lib.types.listOf tunnelType;
      default = [];
      description = "Verbose-format tunnel definitions";
      example = lib.literalExpression ''
        [{
          name = "postgres";
          host = "my-server";
          mode = "local";
          local = "127.0.0.1:15432";
          remote = "127.0.0.1:5432";
        }]
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    dotnix.hm.packages = [portal];

    home-manager = dotnix-utils.hm.hmConfig (
      lib.optionalAttrs hasConfig {
        xdg.configFile."portal/config.toml" = {
          source = (pkgs.formats.toml {}).generate "portal-config" portalConfig;
          force = true;
        };
      }
    );
  };
}
