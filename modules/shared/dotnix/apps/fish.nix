{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  dotnix-utils,
  ...
}: let
  cfg = config.dotnix.apps.fish;
  isLinux = !pkgs.stdenv.isDarwin;

  # Proxy helpers are NixOS-only: they point at the local mihomo mixed-port
  # which only runs on the NixOS hosts. Darwin shells have no local proxy, so
  # registering these commands there (or even the option) would be misleading.
  # Keep all proxyUrl-dependent logic inside this binding so it never evaluates
  # on darwin where `cfg.proxyUrl` does not exist.
  proxyHelpers = let
    # Extract the bare host (no scheme/port) from the proxy URL so it can be
    # added to no_proxy — the proxy itself must never be asked to reach itself.
    proxyHost =
      builtins.head
      (builtins.match "^[a-zA-Z]+://([^:/]+)(:[0-9]+)?/?" cfg.proxyUrl);
    # Build a de-duplicated no_proxy list. localhost/loopback are always
    # direct; add the proxy host only if it isn't already one of them.
    noProxyList = let
      base = ["localhost" "127.0.0.1" "::1"];
      isLocal = builtins.elem proxyHost base;
      extra = lib.optional (!isLocal) proxyHost;
    in
      lib.concatStringsSep "," (base ++ extra);
    # Shared env vars handed to `env` for one-shot commands.
    proxyEnv = {
      http_proxy = cfg.proxyUrl;
      https_proxy = cfg.proxyUrl;
      all_proxy = cfg.proxyUrl;
      HTTP_PROXY = cfg.proxyUrl;
      HTTPS_PROXY = cfg.proxyUrl;
      ALL_PROXY = cfg.proxyUrl;
      no_proxy = noProxyList;
      NO_PROXY = noProxyList;
    };
    # Render an attrset of VAR=VAL pairs as `env` arguments (VAL shell-quoted).
    envArgs = vars:
      lib.concatStringsSep " "
      (lib.mapAttrsToList (n: v: "${n}=${lib.escapeShellArg v}") vars);
  in {
    # The proxyUrl option itself.
    option = {
      proxyUrl = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = "http://127.0.0.1:7890";
        description = ''
          HTTP/SOCKS proxy URL used by the `with-proxy` fish helper to route a
          single command (and by `proxy-on` to route the rest of the shell).
          Set to `null` to disable proxy helpers entirely on a host.

          Defaults to the local mihomo mixed-port (`dotnix.services.mihomo`).
        '';
      };
    };

    # The fish functions block, guarded so an empty proxyUrl registers nothing.
    functions =
      {}
      // lib.optionalAttrs (cfg.proxyUrl != null) {
        # One-shot: route just the next command through the proxy.
        with-proxy = ''
          if test (count $argv) -eq 0
              echo "usage: with-proxy COMMAND..." >&2
              return 1
          end
          env ${envArgs proxyEnv} $argv
        '';
        # One-shot: force the next command to bypass the proxy even if
        # the shell has proxy-on active.
        with-direct = ''
          if test (count $argv) -eq 0
              echo "usage: with-direct COMMAND..." >&2
              return 1
          end
          env http_proxy= https_proxy= all_proxy= \
              HTTP_PROXY= HTTPS_PROXY= ALL_PROXY= \
              no_proxy="*" NO_PROXY="*" \
              $argv
        '';
        # Persistent: route every following command in this shell through
        # the proxy until `proxy-off`.
        proxy-on = ''
          set -gx http_proxy ${lib.escapeShellArg cfg.proxyUrl}
          set -gx https_proxy ${lib.escapeShellArg cfg.proxyUrl}
          set -gx all_proxy ${lib.escapeShellArg cfg.proxyUrl}
          set -gx HTTP_PROXY ${lib.escapeShellArg cfg.proxyUrl}
          set -gx HTTPS_PROXY ${lib.escapeShellArg cfg.proxyUrl}
          set -gx ALL_PROXY ${lib.escapeShellArg cfg.proxyUrl}
          set -gx no_proxy ${lib.escapeShellArg noProxyList}
          set -gx NO_PROXY ${lib.escapeShellArg noProxyList}
          echo "proxy on: ${cfg.proxyUrl}"
        '';
        proxy-off = ''
          set -e http_proxy; set -e https_proxy; set -e all_proxy
          set -e HTTP_PROXY; set -e HTTPS_PROXY; set -e ALL_PROXY
          set -e no_proxy; set -e NO_PROXY
          echo "proxy off"
        '';
        proxy-status = ''
          if set -q http_proxy
              echo "proxy on: $http_proxy"
          else
              echo "proxy off"
          end
        '';
      };
  };
in {
  options.dotnix.apps.fish =
    {
      enable = lib.mkEnableOption "Enable module dotnix.apps.fish";
    }
    // lib.optionalAttrs isLinux proxyHelpers.option;

  config = lib.mkIf cfg.enable {
    home-manager = dotnix-utils.hm.hmConfig {
      programs.fish = {
        enable = true;
        package = pkgs-unstable.fish;
        # pkgs-unstable.fish is 4.x (the Rust rewrite), which dropped
        # share/fish/tools/create_manpage_completions.py entirely. Home-manager's
        # default generateCompletions builds a `<pkg>-fish-completions` derivation
        # per home.packages entry that invokes that script, so it fails for every
        # package (e.g. bat). Disable it: fish 4.x has no manpage->completion
        # generator, and packages that want fish completions ship them natively
        # under share/fish/vendor_completions.d/, which fish auto-loads.
        generateCompletions = false;
        interactiveShellInit = ''
          set fish_greeting

          export GITHUB_TOKEN="$(cat ${config.age.secrets.github-cli-access-token.path})"
        '';
        plugins = [
          {
            name = "foreign-env";
            src = pkgs.fetchFromGitHub {
              owner = "oh-my-fish";
              repo = "plugin-foreign-env";
              rev = "3ee95536106c11073d6ff466c1681cde31001383";
              sha256 = "sha256-vyW/X2lLjsieMpP9Wi2bZPjReaZBkqUbkh15zOi8T4Y=";
            };
          }
        ];
        shellAliases = {
          ll = "eza -l --icons -a --group-directories-first --git";
          glr = "git pull --rebase";
          gco = "git checkout";
          gst = "git status";
          gd = "git diff";
          glg = "git log --graph";
          gaa = "git add --all";
          gcm = "git commit -m";
          gp = "git push";
          nvi = "nvim";
          v = "nvim";
          j = "just";
          lg = "lazygit";
          tdev = "tmux atta -t dev || tmux new -s dev";
          goto = "kitten ssh --kitten forward_remote_control=yes";
          ts = "tailscale";
        };
        functions =
          {}
          // lib.optionalAttrs isLinux proxyHelpers.functions;
      };
    };
  };
}
