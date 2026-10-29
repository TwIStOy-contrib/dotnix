{
  config,
  lib,
  pkgs-unstable,
  dotnix-constants,
  ...
}: let
  cfg = config.dotnix.apps.fish;
  # The single fish derivation shared by every consumer (home-manager
  # package, tmux default-shell, this login shell) — see the twin binding in
  # modules/shared/dotnix/apps/fish.nix. Must stay pkgs-unstable.fish so all
  # paths resolve to one store path.
  fishPkg = pkgs-unstable.fish;
in {
  # NixOS-only by placement. This block must not live in the shared module:
  # nix-darwin vendors its own programs.fish without `generateCompletions`,
  # and the module system's unknown-option check ignores mkIf conditions, so
  # merely mentioning the option breaks darwin evaluation.
  config = lib.mkIf (cfg.enable && cfg.loginShell) {
    programs.fish = {
      enable = true;
      package = fishPkg;
      # Mandatory: fish 4.x (Rust rewrite) dropped
      # share/fish/tools/create_manpage_completions.py, which the module's
      # completion generator still invokes — same breakage that forced
      # generateCompletions = false in home-manager.
      generateCompletions = false;
    };
    users.users."${dotnix-constants.user.name}".shell = fishPkg;
  };
}
