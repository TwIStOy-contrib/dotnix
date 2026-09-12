{
  config,
  lib,
  pkgs,
  inputs,
  dotnix-utils,
  ...
}: let
  cfg = config.dotnix.apps.htw;
  htw = inputs.htw.packages.${pkgs.stdenv.hostPlatform.system}.default;
  htwBin = lib.getExe cfg.package;
  fishCompletion = pkgs.runCommandLocal "htw-fish-completion" {} ''
    ${htwBin} completion fish >"$out"
  '';
  fishIntegration = pkgs.runCommandLocal "htw-fish-integration" {} ''
    export XDG_CONFIG_HOME="$TMPDIR/xdg"
    ${htwBin} shell install >/dev/null
    cp "$XDG_CONFIG_HOME/fish/functions/htw.fish" "$out"
  '';

  tomlFormat = pkgs.formats.toml {};

  # htw's loader treats an absent key like an unset one, but the TOML
  # generator cannot serialize null; drop nulls instead of failing the build.
  dropNulls = value:
    if lib.isAttrs value
    then lib.filterAttrs (_: v: v != null) (lib.mapAttrs (_: dropNulls) value)
    else if lib.isList value
    then map dropNulls value
    else value;

  # The [daemon] table is only emitted when it deviates from htw's defaults
  # (port 7482, bind 127.0.0.1, loopback-only allowlist).
  daemonConfigured =
    cfg.daemon.port
    != null
    || cfg.daemon.bind != null
    || cfg.daemon.allow != [];

  configPayload =
    {sessions = cfg.sessions;}
    // (lib.optionalAttrs daemonConfigured {
      daemon = {
        inherit (cfg.daemon) port bind allow;
      };
    });
in {
  options.dotnix.apps.htw = {
    enable = lib.mkEnableOption "htw, the developer environment manager CLI";

    package = lib.mkOption {
      type = lib.types.package;
      default = htw;
      defaultText = lib.literalExpression "inputs.htw.packages.\${pkgs.stdenv.hostPlatform.system}.default";
      description = "Package providing the htw binary.";
    };

    sessions = lib.mkOption {
      type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
      default = {};
      description = ''
        Named tmux sessions serialized to ~/.config/htw/config.toml (the
        unified htw config; the legacy tmux-sessions.toml is not managed
        here). Each attribute becomes one [sessions.<name>] table with htw's
        own TOML schema: root (tilde-expanded), attach, before_start, stop,
        attach_hook, detach_hook, send_keys_delay, env, and windows — each
        window being name/root/manual/selected/layout/commands plus panes
        (type/root/commands).
      '';
    };

    daemon = lib.mkOption {
      type = lib.types.submodule {
        options = {
          port = lib.mkOption {
            type = lib.types.nullOr lib.types.port;
            default = null;
            description = ''
              Port the agent-sessions daemon listens on. Null leaves htw's
              default (7482).
            '';
          };

          bind = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            description = ''
              Address the daemon binds to. Null leaves htw's default
              (127.0.0.1, loopback only). Binding a non-loopback address
              (e.g. "0.0.0.0") also requires allow — htw fail-closes and
              answers 403 to every non-allowlisted peer.
            '';
          };

          allow = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = ''
              Client IP/CIDR allowlist for non-loopback peers, e.g.
              ["192.168.50.0/24"]. Loopback is always permitted, so empty
              means loopback only.
            '';
          };
        };
      };
      default = {};
      description = ''
        The [daemon] table serialized into ~/.config/htw/config.toml. The
        htw service module runs the daemon without CLI overrides, so these
        values (via the config file) are the single source of truth for both
        the daemon and the `htw agents` dashboard's default connection.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    dotnix.hm.packages = [
      cfg.package
    ];

    home-manager = dotnix-utils.hm.hmConfig (lib.mkMerge [
      (lib.mkIf (cfg.sessions != {} || daemonConfigured) {
        xdg.configFile."htw/config.toml".source =
          tomlFormat.generate "htw-config.toml"
          (dropNulls configPayload);
      })

      (lib.mkIf config.dotnix.apps.fish.enable {
        xdg.configFile = {
          "fish/completions/htw.fish".source = fishCompletion;
          "fish/functions/htw.fish".source = fishIntegration;
        };
      })
    ]);
  };
}
