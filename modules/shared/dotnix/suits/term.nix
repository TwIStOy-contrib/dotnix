{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  nur-hawtian,
  dotnix-utils,
  ...
}: let
  inherit (dotnix-utils) enableModules;
  cfg = config.dotnix.suits.term;
in {
  options.dotnix.suits.term = {
    enable = lib.mkEnableOption "Enable module dotnix.suits.term";
  };

  config = lib.mkIf cfg.enable {
    dotnix = {
      apps = enableModules [
        "eza"
        "fish"
        "neovim"
        "starship"
        "tealdeer"
        "tmux"
        "yazi"
        "zoxide"
      ];

      utils = enableModules [
        "rime-scheme"
      ];

      hm.packages = let
        stablePkgs = with pkgs; [
          neofetch
          xdg-utils

          # decompress
          zip
          xz
          unzip
          p7zip

          # common tools
          delta
          (ripgrep.override {withPCRE2 = true;})
          hyperfine
          fd
          skim
          btop
          tokei
          ydict
          wget
          dig
          expect
          gnugrep
          gnused
          gawk
          jq
          yq-go

          xclip
          fswatch

          ffmpeg-full
        ];
        unstablePkgs = with pkgs-unstable; [
          curl
          grpcurl
          jc
          smug
        ];
        nurPackages = [nur-hawtian.packages.${pkgs.system}.rime-ls];
      in
        stablePkgs ++ unstablePkgs ++ nurPackages;
    };

    home-manager = dotnix-utils.hm.hmConfig {
      programs.nix-index.enable = true;
    };
  };
}
