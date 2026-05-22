{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  dotnix-utils,
  dotnix-constants,
  ...
}: let
  cfg = config.dotnix.apps.boring;
  inherit (dotnix-constants) user;
  homeDir = config.users.users."${user.name}".home;

  boringPkg = pkgs-unstable.boring;

  tunnelType = lib.types.submodule {
    options = {
      name = lib.mkOption {
        type = lib.types.str;
        description = "Tunnel name (required)";
      };
      local = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''Local address. Can be a "$host:$port" or just "$port". Required in local, remote and socks modes.'';
      };
      remote = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''Remote address. Can be a "$host:$port" or just "$port". Required in local, remote and socks-remote modes.'';
      };
      host = lib.mkOption {
        type = lib.types.str;
        description = "SSH host alias (from SSH config) or actual hostname";
      };
      mode = lib.mkOption {
        type = lib.types.enum ["local" "remote" "socks" "socks-remote"];
        default = "local";
        description = "Tunnel mode";
      };
      user = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "SSH user";
      };
      identity = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "SSH identity file path";
      };
      port = lib.mkOption {
        type = lib.types.nullOr (lib.types.either lib.types.int lib.types.str);
        default = null;
        description = "SSH port";
      };
      group = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Group assignment for the tunnel";
      };
      keep_alive = lib.mkOption {
        type = lib.types.nullOr lib.types.int;
        default = null;
        description = "Keep-alive interval in seconds";
      };
    };
  };

  mkTunnel = t:
    {
      inherit (t) name host mode;
    }
    // lib.optionalAttrs (t.local != null) {local = t.local;}
    // lib.optionalAttrs (t.remote != null) {remote = t.remote;}
    // lib.optionalAttrs (t.user != null) {user = t.user;}
    // lib.optionalAttrs (t.identity != null) {identity = t.identity;}
    // lib.optionalAttrs (t.port != null) {port = t.port;}
    // lib.optionalAttrs (t.group != null) {group = t.group;}
    // lib.optionalAttrs (t.keep_alive != null) {keep_alive = t.keep_alive;};

  boringConfig =
    {}
    // lib.optionalAttrs (cfg.keep_alive != null) {inherit (cfg) keep_alive;}
    // lib.optionalAttrs (cfg.tunnels != []) {
      tunnels = map mkTunnel cfg.tunnels;
    };
  hasConfig = cfg.tunnels != [];
in {
  options.dotnix.apps.boring = {
    enable = lib.mkEnableOption "boring SSH tunnel manager";

    package = lib.mkOption {
      type = lib.types.package;
      default = boringPkg;
      description = "boring package to use";
    };

    keep_alive = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      description = "Global keep-alive interval in seconds (default: 120)";
    };

    tunnels = lib.mkOption {
      type = lib.types.listOf tunnelType;
      default = [];
      description = "Tunnel definitions";
      example = lib.literalExpression ''
        [
          {
            name = "dev";
            local = "9000";
            remote = "localhost:9000";
            host = "dev-server";
          }
          {
            name = "prod";
            local = "5001";
            remote = "localhost:5001";
            host = "prod.example.com";
            user = "root";
            identity = "~/.ssh/id_prod";
          }
        ]
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    dotnix.hm.packages = [cfg.package];

    home-manager = dotnix-utils.hm.hmConfig (
      lib.optionalAttrs hasConfig {
        xdg.configFile."boring/.boring.toml" = {
          source = (pkgs.formats.toml {}).generate "boring-config" boringConfig;
          force = true;
        };
        home.sessionVariables = lib.optionalAttrs pkgs.stdenv.isDarwin {
          BORING_CONFIG = "${homeDir}/.config/boring/.boring.toml";
        };
      }
    );
  };
}
