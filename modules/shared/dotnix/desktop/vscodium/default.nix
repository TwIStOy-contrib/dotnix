{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  dotnix-utils,
  inputs,
  ...
}: let
  cfg = config.dotnix.desktop.vscodium;
  extensions = inputs.nix-vscode-extensions.extensions.${pkgs.stdenv.hostPlatform.system};
in {
  options.dotnix.desktop.vscodium = {
    enable = lib.mkEnableOption "VSCodium";
  };

  config = lib.mkIf cfg.enable {
    home-manager = dotnix-utils.hm.hmConfig {
      programs.vscode = {
        enable = true;
        package = pkgs-unstable.vscodium;
        extensions =
          (with extensions.vscode-marketplace; [
            github.copilot
            github.copilot-chat
            ms-vscode-remote.remote-ssh
            ms-vscode-remote.remote-ssh-edit
            ms-vscode-remote.remote-containers
            ms-vscode.remote-explorer
            llvm-vs-code-extensions.vscode-clangd
            xaver.clang-format
            thang-nm.catppuccin-perfect-icons
            catppuccin.catppuccin-vsc
            catppuccin.catppuccin-vsc-icons
            vscodevim.vim
          ])
          ++ (with extensions.open-vsx; [
            mkhl.direnv
            draivin.hsnips
            draivin.hscopes
            skellock.just
            jnoortheen.nix-ide
            wakatime.vscode-wakatime
            rust-lang.rust-analyzer
          ]);
        enableUpdateCheck = false;
        enableExtensionUpdateCheck = false;
        userSettings = import ./settings.nix {inherit pkgs pkgs-unstable;};
        userTasks = {};
        keybindings = import ./keymaps.nix;
      };
    };
  };
}
