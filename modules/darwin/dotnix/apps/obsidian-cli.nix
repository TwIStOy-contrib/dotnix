{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.dotnix.apps.obsidian-cli;

  # The official Obsidian CLI is a redirector bundled inside the Obsidian
  # application; it forwards commands to the running Obsidian GUI process via
  # local IPC, so the GUI app must be running. Obsidian itself is installed via
  # the homebrew cask in modules/darwin/app.nix; this wrapper only surfaces the
  # bundled binary on PATH. This module is darwin-only because a headless NixOS
  # host has no running Obsidian GUI for the redirector to talk to.
  obsidian-cli = pkgs.writeShellScriptBin "obsidian-cli" ''
    exec "/Applications/Obsidian.app/Contents/MacOS/obsidian-cli" "$@"
  '';
in {
  options.dotnix.apps.obsidian-cli = {
    enable = lib.mkEnableOption "Enable module dotnix.apps.obsidian-cli";
  };

  config = lib.mkIf cfg.enable {
    dotnix.hm.packages = [
      obsidian-cli
    ];
  };
}
