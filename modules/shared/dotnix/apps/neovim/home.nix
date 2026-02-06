{
  config,
  lib,
  pkgs,
  pkgs-unstable,
  neovim-pkgs,
  ...
}: let
  user-dotpath = "${config.home.homeDirectory}/.dotvim";

  unstableVimPlugins = pkgs-unstable.vimPlugins;

  plugins = {
    inherit (unstableVimPlugins) codesnap-nvim;
    inherit (unstableVimPlugins) telescope-fzf-native-nvim;
    inherit (unstableVimPlugins) avante-nvim;
    inherit (unstableVimPlugins) markdown-preview-nvim;
    inherit (unstableVimPlugins) rest-nvim;
    inherit (unstableVimPlugins) codediff-nvim;
  };

  bins = {
    inherit (pkgs) rustfmt libgit2 statix rust-analyzer;
    inherit
      (pkgs-unstable)
      taplo
      beancount-language-server
      fzf
      stylua
      helm-ls
      lua-language-server
      yaml-language-server
      emmylua-check
      emmylua-ls
      black
      zls
      ;
    clangd = pkgs-unstable.clang-tools;
    clang-format = pkgs-unstable.llvmPackages_21.clang-unwrapped;
    vscode-html-language-server = pkgs-unstable.vscode-langservers-extracted;
    vscode-eslint-language-server = pkgs-unstable.vscode-langservers-extracted;
    vscode-markdown-language-server = pkgs-unstable.vscode-langservers-extracted;
    vscode-json-language-server = pkgs-unstable.vscode-langservers-extracted;
    vscode-css-language-server = pkgs-unstable.vscode-langservers-extracted;
    jdtls = pkgs-unstable.jdt-language-server;
    xmllint = pkgs-unstable.libxml2;
  };

  libs = with pkgs-unstable; {
    inherit (luajitPackages) tiktoken_core magick;
  };

  nixAwareNvimConfig = pkgs.stdenv.mkDerivation {
    name = "nix-aware-nvim-config";

    buildInputs =
      (lib.mapAttrsToList (_: pkg: pkg) plugins)
      ++ (lib.mapAttrsToList (_: pkg: pkg) bins)
      ++ (lib.mapAttrsToList (_: pkg: pkg) libs);

    phases = ["installPhase"];

    nixAwareNvimConfigJson =
      pkgs.writeText
      "nixAwareNvimConfig.json"
      (builtins.toJSON {
        pkgs = plugins;
        bin = lib.mapAttrs (name: pkg: "${pkg}/bin/${name}") bins;
        inherit libs;
        try_nix_only = true;
      });

    installPhase = ''
      mkdir -p $out
      cp $nixAwareNvimConfigJson $out/nix-aware.json
    '';
  };

  init-dora = ''
    vim.loader.enable()
    local dotpath = "${user-dotpath}"
    vim.opt.rtp:prepend(dotpath)
    require("dotvim.starts")
  '';
in {
  home.packages =
    (with pkgs-unstable; [
      neovim-node-client
      tree-sitter
      nixAwareNvimConfig
    ])
    ++ (
      with pkgs-unstable; [
        python313Packages.pynvim
      ]
    );

  programs.neovim = {
    enable = true;
    package = neovim-pkgs.default;
    plugins = builtins.attrValues plugins;
  };

  xdg.configFile = {
    "nvim/init.lua" = {
      text = init-dora;
      force = true;
    };

    "nvim/nix-aware.json" = {
      source = "${nixAwareNvimConfig}/nix-aware.json";
      force = true;
    };
  };
}
