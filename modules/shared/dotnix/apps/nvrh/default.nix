{
  config,
  lib,
  pkgs,
  dotnix-utils,
  ...
}: let
  cfg = config.dotnix.apps.nvrh;

  settingsFormat = pkgs.formats.yaml {};

  # Mirrors NvrhConfigServer from src/nvrh_config/main.go — the exact set of
  # keys nvrh reads from config.yml. Unset options (null / []) are stripped
  # before generating YAML: a key that is present-but-empty is treated by
  # nvrh as an explicit override that masks env vars and platform defaults
  # (e.g. use-ports defaulting to true on Windows).
  serverSettings = {
    nvim-cmd = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = ''
        Command to run nvim with on the remote server. Defaults to just
        `nvim`; useful when nvim is not on the default remote PATH, e.g.
        `[ "mise" "exec" "--" "nvim" ]`.
      '';
    };

    use-ports = lib.mkOption {
      type = lib.types.nullOr lib.types.bool;
      default = null;
      description = ''
        Use TCP ports instead of sockets for the tunnel. Defaults to false,
        or true when the local/remote machine is Windows.
      '';
    };

    ssh-arg = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Additional arguments to pass to the SSH command.";
    };

    ssh-path = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Which SSH client to use: "binary" for the system SSH binary,
        "internal" for the built-in SSH client, or an absolute path to an
        SSH binary.
      '';
    };

    local-editor = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = ''
        Local editor command to launch. {{SOCKET_PATH}} is replaced with
        the tunnel socket path. Defaults to
        `[ "nvim" "--server" "{{SOCKET_PATH}}" "--remote-ui" ]`.
      '';
    };

    server-env = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = ''
        Environment variables to set on the remote server, as FOO=bar
        strings.
      '';
    };

    insecure-direct-connect = lib.mkOption {
      type = lib.types.nullOr (lib.types.either lib.types.bool lib.types.str);
      default = null;
      description = ''
        Opens a public port on the server and connects directly to it.
        `true` connects to the server you're already passing; a string
        gives an explicit address to connect to instead.
      '';
    };

    use-nvim-embed = lib.mkOption {
      type = lib.types.nullOr lib.types.bool;
      default = null;
      description = "Start the remote nvim with --embed instead of --headless.";
    };
  };

  cleanServer = settings:
    lib.filterAttrs (_: v: v != null && v != []) settings;

  cleanDefault = cleanServer cfg.settings.default;
  cleanServers = lib.mapAttrs (_: cleanServer) cfg.settings.servers;

  # Shallow merge: extraSettings may override whole sections as an escape
  # hatch for keys added by newer nvrh versions.
  nvrhConfig =
    (lib.optionalAttrs (cleanDefault != {}) {default = cleanDefault;})
    // (lib.optionalAttrs (cleanServers != {}) {servers = cleanServers;})
    // cfg.extraSettings;

  configFile = settingsFormat.generate "config.yml" nvrhConfig;
in {
  options.dotnix.apps.nvrh = {
    enable = lib.mkEnableOption "nvrh, a remote helper for Neovim (VSCode Remote-like)";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.callPackage ./package.nix {};
      description = "The nvrh package to use.";
    };

    settings = lib.mkOption {
      type = lib.types.submodule {
        options = {
          default = lib.mkOption {
            type = lib.types.submodule {options = serverSettings;};
            default = {};
            description = ''
              The `default` section of the config, applied to every server
              unless overridden per-server.
            '';
          };

          servers = lib.mkOption {
            type = lib.types.attrsOf (lib.types.submodule {options = serverSettings;});
            default = {};
            description = ''
              The `servers` section: per-server overrides keyed by the SSH
              host alias passed to `nvrh client open`. Quote names that
              contain dots, e.g. servers."poi.remote". Same fields as the
              `default` section.
            '';
          };
        };
      };
      default = {};
      description = ''
        Declarative content of ~/.config/nvrh/config.yml. Only the fields
        nvrh actually reads from the config file are declared; `--debug`
        and `--enable-automap-ports` are CLI/env only.
      '';
    };

    extraSettings = lib.mkOption {
      type = lib.types.attrs;
      default = {};
      description = ''
        Extra attributes shallow-merged over the generated config, for keys
        not covered by `settings`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    dotnix.hm.packages = [
      cfg.package
    ];

    home-manager = dotnix-utils.hm.hmConfig {
      # nvrh hardcodes the path ~/.config/nvrh/config.yml in
      # src/nvrh_config/main.go DefaultConfigPath() — .yml, not .yaml.
      xdg.configFile."nvrh/config.yml" = {
        source = configFile;
        force = true;
      };
    };
  };
}
