{
  config,
  pkgs,
  pkgs-unstable,
  lib,
  nur-hawtian,
  dotnix-utils,
  ...
}: let
  cfg = config.dotnix.development.languages.cpp;

  gcc = pkgs-unstable.gcc14;
  # inherit (pkgs-unstable) gcc;
  nixAwareClangdConfig = pkgs.stdenv.mkDerivation {
    name = "nix-aware-clangd-config";

    nativeBuildInputs = [gcc];

    dontUnpack = true;
    phases = ["installPhase"];

    installPhase = ''
      mkdir -p $out/dist
      ($CXX -xc++ -E -v /dev/null) 2>&1 | awk 'BEGIN { incsearch = 0} /^End of search list/ { incsearch = 0 } { if(incsearch) { print $0 }} /^#include </ { incsearch = 1 }' | sed 's/^[[:space:]]*\(.*\)/"-isystem","\1"/' | tr '\n' ' ' | tr ' ' ',' | sed 's/,$//' > $out/dist/extra_args
    '';
  };

  globalClangdConfigContent = ''
    CompileFlags:
      Compiler: ${gcc}/bin/g++
      Add: [${builtins.readFile "${nixAwareClangdConfig}/dist/extra_args"}]
    Diagnostics:
      Suppress: "builtin_definition"
  '';
in {
  options.dotnix.development.languages.cpp = {
    enable = lib.mkEnableOption "Enable C++ development";
  };

  config = lib.mkIf cfg.enable {
    dotnix.hm.packages =
      [
        gcc
        nixAwareClangdConfig
      ]
      ++ (with pkgs-unstable; [
        cmake-language-server
        llvmPackages_19.clang-tools
      ])
      ++ [
        # format cmake files
        nur-hawtian.packages.${pkgs.stdenv.hostPlatform.system}.gersemi
      ];
    # generate clangd user configuration file

    home-manager = dotnix-utils.hm.hmConfig (
      if pkgs.stdenv.hostPlatform.isDarwin
      then {
        home.file."Library/Preferences/clangd/config.yaml" = {
          text = globalClangdConfigContent;
          force = true;
        };
      }
      else {
        xdg.configFile."clangd/config.yaml" = {
          text = globalClangdConfigContent;
          force = true;
        };
      }
    );
  };
}
