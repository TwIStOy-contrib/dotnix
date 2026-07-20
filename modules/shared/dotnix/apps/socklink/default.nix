{
  config,
  lib,
  pkgs,
  dotnix-utils,
  ...
}: let
  cfg = config.dotnix.apps.socklink;

  # socklink.sh is a single, self-contained POSIX sh script (MIT, zero
  # runtime dependencies). Upstream is not a Nix flake, so we vendor it as a
  # fixed-output derivation pinned to a known commit. Bump `rev` and `hash`
  # together to upgrade.
  #   https://github.com/mshroyer/socklink
  socklinkPkg = pkgs.stdenvNoCC.mkDerivation {
    pname = "socklink";
    version = "0.3.2-unstable-2026-01-27";
    src = pkgs.fetchFromGitHub {
      owner = "mshroyer";
      repo = "socklink";
      rev = "37169a8c9be9fb04395edbf21b1503ce9dba2094";
      hash = "sha256-/TK7WBH+8Cu8LY/gY7r0R5xnDIPhSenc0S58IaTUcd0=";
    };

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      runHook preInstall
      install -Dm0755 socklink.sh $out/bin/socklink.sh
      # NixOS has no /bin/sh; rewrite the shebang to a store shell so the
      # script is directly executable (the tmux hooks invoke it by path).
      patchShebangs $out/bin/socklink.sh
      runHook postInstall
    '';

    meta = {
      description = "Zero-dependency SSH_AUTH_SOCK manager for tmux";
      homepage = "https://github.com/mshroyer/socklink";
      license = lib.licenses.mit;
      mainProgram = "socklink.sh";
      platforms = lib.platforms.unix;
    };
  };

  # Absolute bin path embedded into the tmux hooks and the shell init.
  socklinkBin = "${socklinkPkg}/bin/socklink.sh";

  # Verbatim equivalent of what `socklink.sh setup` writes to .tmux.conf
  # (see setup_tmux_conf()), with the script path resolved to the Nix store.
  # `programs.tmux.extraConfig` is types.lines, so this merges cleanly with
  # dotnix.apps.tmux's own extraConfig without touching that module.
  tmuxHooks = ''
    # --- socklink: point SSH_AUTH_SOCK at the active tmux client ---
    if-shell -b '"${socklinkBin}" test-tmux-feature client-active-hook' {
      set-hook -ga client-active 'run-shell "\"${socklinkBin}\" -c client-active set-server-link-by-name \"#{hook_client}\""'
    }
    set-hook -ga client-attached 'run-shell "\"${socklinkBin}\" -c client-attached set-server-link \"#{client_tty}\""'
    set-hook -ga session-created 'run-shell "\"${socklinkBin}\" -c session-created set-server-link \"#{client_tty}\""'
    set-hook -ga session-created 'run-shell "\"${socklinkBin}\" -c session-created set-tmux-env"'
  '';

  # Fish translation of the hook setup_bashrc()/setup_zshrc() emit. socklink's
  # own setup only targets bash and zsh; the README instructs handling other
  # shells manually. `status is-interactive` is the fish equivalent of bash's
  # `[[ $- == *i* ]]` / zsh's `[[ -o interactive ]]`.
  fishHook = ''
    # --- socklink: bind SSH_AUTH_SOCK to the active tmux client ---
    if status is-interactive
        if test -z "$TMUX"
            ${socklinkBin} set-tty-link -c shell-init
        else
            set -gx SSH_AUTH_SOCK (${socklinkBin} show-server-link)
        end
    end
  '';
in {
  options.dotnix.apps.socklink = {
    enable = lib.mkEnableOption ''
      socklink, a zero-dependency SSH_AUTH_SOCK manager for tmux.

      Installs the socklink.sh script and wires up the tmux server hooks
      (client-active / client-attached / session-created) plus the
      interactive shell hook that keeps SSH_AUTH_SOCK pointed at the
      currently active tmux client — even with multiple simultaneous
      clients using different hardware authenticators (e.g. YubiKeys).

      This is the declarative equivalent of running `socklink.sh setup`,
      so there is no need to edit .tmux.conf / .bashrc / .zshrc on the
      host. The tmux hooks are injected only when dotnix.apps.tmux is
      enabled, and the shell hook (fish) only when dotnix.apps.fish is
      enabled.
    '';

    package = lib.mkOption {
      type = lib.types.package;
      default = socklinkPkg;
      readOnly = true;
      description = "The socklink.sh package (read-only, for reference).";
    };
  };

  config = lib.mkIf cfg.enable {
    # Keep socklink.sh on PATH for manual use (e.g. `socklink.sh set-server-link`
    # when debugging, per upstream's troubleshooting section).
    dotnix.hm.packages = [socklinkPkg];

    home-manager = lib.mkMerge [
      (lib.mkIf config.dotnix.apps.tmux.enable
        (dotnix-utils.hm.hmConfig {
          programs.tmux.extraConfig = tmuxHooks;
        }))
      (lib.mkIf config.dotnix.apps.fish.enable
        (dotnix-utils.hm.hmConfig {
          programs.fish.interactiveShellInit = fishHook;
        }))
    ];
  };
}
