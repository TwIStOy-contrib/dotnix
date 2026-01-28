{
  config,
  dotnix-utils,
  lib,
  ...
}: let
  cfg = config.dotnix.development.languages.all;
  inherit (dotnix-utils) enabled;
in {
  options.dotnix.development.languages.all = {
    enable = lib.mkEnableOption "Enable all languages";
  };

  config = lib.mkIf cfg.enable {
    dotnix.development.languages = {
      cpp = enabled;
      golang = enabled;
      # dart = enabled;
      nix = enabled;
      node = enabled;
      typescript = enabled;
      python = enabled;
      rust = enabled;
      lua = enabled;
      java = enabled;
      markdown = enabled;
      beancount = enabled;
      zig = enabled;
    };
  };
}
