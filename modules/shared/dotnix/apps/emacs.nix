{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  ...
}: let
  cfg = config.dotnix.apps.emacs;

  # macOS gets the Cocoa build. The Linux hosts (poi, taihou) are headless and
  # are driven over ssh/tmux, so emacs-nox keeps GTK/X libs out of the closure.
  emacsPackage =
    if pkgs.stdenv.hostPlatform.isDarwin
    then pkgs-unstable.emacs
    else pkgs-unstable.emacs-nox;
in {
  options.dotnix.apps.emacs = {
    enable = lib.mkEnableOption "Enable module dotnix.apps.emacs";
  };

  config = lib.mkIf cfg.enable {
    # Only the binary is managed here: ~/.emacs.d is the hand-rolled config and
    # keeps installing packages itself through package.el (MELPA), which needs a
    # writable elpa/ + eln-cache/.
    dotnix.hm.packages = [emacsPackage];
  };
}
