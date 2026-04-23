{
  config,
  lib,
  pkgs,
  inputs,
  dotnix-utils,
  dotnix-constants,
  isDarwin,
  ...
}: let
  cfg = config.dotnix.development.portal;
  inherit (dotnix-constants) user;
  homeDir = config.users.users."${user.name}".home;

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

    service = lib.mkOption {
      type = lib.types.submodule {
        options = {
          enable = lib.mkEnableOption "Run portal as a background service";
        };
      };
      default = {};
      description = "Portal service configuration";
    };

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
      // lib.optionalAttrs cfg.service.enable (
        if isDarwin
        then {
          launchd.agents.portal = {
            enable = true;
            config = {
              Label = "com.dotnix.portal";
              ProgramArguments = ["${portal}/bin/portal"];
              RunAtLoad = true;
              KeepAlive = true;
              StandardErrorPath = "${homeDir}/Library/Logs/portal.stderr.log";
              StandardOutPath = "${homeDir}/Library/Logs/portal.stdout.log";
            };
          };
        }
        else {
          systemd.user.services.portal = {
            Unit = {
              Description = "Portal SSH tunnel manager";
              After = ["network.target"];
            };
            Service = {
              ExecStart = "${portal}/bin/portal";
              Restart = "always";
              RestartSec = 5;
            };
            Install.WantedBy = ["default.target"];
          };
        }
      )
    );
  };
}
