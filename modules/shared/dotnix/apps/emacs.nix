{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}: let
  cfg = config.dotnix.apps.emacs;
  isDarwin = pkgs.stdenv.hostPlatform.isDarwin;
in {
  options.dotnix.apps.emacs = {
    enable = lib.mkEnableOption "Enable module dotnix.apps.emacs";
  };

  config = lib.mkIf cfg.enable {
    # Only the binary is managed here: ~/.emacs.d is the hand-rolled config and
    # keeps installing packages itself through package.el (MELPA), which needs a
    # writable elpa/ + eln-cache/.
    # Darwin hosts use the homebrew emacs-plus build (tap + brew declared in
    # modules/darwin/app.nix), so no nix package there. The Linux hosts (poi,
    # taihou) are headless and driven over ssh/tmux, so emacs-nox keeps GTK/X
    # libs out of the closure.
    dotnix.hm.packages = lib.optionals (!isDarwin) [pkgs-unstable.emacs-nox];
  };
}
