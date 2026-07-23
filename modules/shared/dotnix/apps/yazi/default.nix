{
  config,
  lib,
  dotnix-utils,
  pkgs-unstable,
  dotvim-ne,
  ...
}: let
  cfg = config.dotnix.apps.yazi;

  # The dotvim editor entry point. `dotvim-ne` ships /bin/ne, a wrapper that
  # sets NVIM_APPNAME and execs the underlying nixvim nvim binary.
  editorBin = "${dotvim-ne}/bin/ne";

  # File name globs that yazi opens with the `text` (dotvim-ne) opener.
  # yazi v25.12.29 (#3034) renamed the `name` matcher to `url` to support the
  # virtual file system, so each rule must use `url`, not `name`.
  textOpenerFiles = [
    # C / C++
    "*.c"
    "*.h"
    "*.cpp"
    "*.hpp"
    "*.cc"
    "*.cxx"
    # other languages
    "*.cs"
    "*.go"
    "*.java"
    "*.kt"
    "*.py"
    "*.rb"
    "*.rs"
    "*.scala"
    "*.swift"
    "*.php"
    "*.sql"
    "*.vim"
    "*.lua"
    "*.nim"
    "*.zig"
    # web
    "*.js"
    "*.jsx"
    "*.ts"
    "*.tsx"
    "*.html"
    "*.htm"
    "*.css"
    "*.scss"
    "*.sass"
    "*.less"
    # markup / docs
    "*.md"
    "*.markdown"
    "*.rst"
    "*.tex"
    "*.txt"
    "*.org"
    # shell / scripting
    "*.sh"
    "*.bash"
    "*.zsh"
    "*.fish"
    ".envrc"
    # config / data
    "*.conf"
    "*.ini"
    "*.cfg"
    "*.properties"
    "*.toml"
    "*.yaml"
    "*.yml"
    "*.json"
    "*.jsonc"
    "*.json5"
    "*.xml"
    # build / project
    "Makefile"
    "makefile"
    "GNUmakefile"
    "CMakeLists.txt"
    "*.cmake"
    "Dockerfile"
    "*.dockerfile"
    "justfile"
    "Justfile"
    "*.service"
    "*.timer"
    "*.socket"
    # nix
    "*.nix"
    "flake.nix"
    "flake.lock"
    # misc
    "LICENSE"
  ];
  textRules =
    map (file: {
      url = file;
      use = "text";
    })
    textOpenerFiles;
in {
  options.dotnix.apps.yazi = {
    enable = lib.mkEnableOption "Enable module dotnix.apps.yazi";
  };

  config = lib.mkIf cfg.enable {
    home-manager = dotnix-utils.hm.hmConfig {
      programs.yazi = {
        enable = true;
        package = pkgs-unstable.yazi;
        enableBashIntegration = true;
        enableFishIntegration = true;

        # ~/.config/yazi/yazi.toml
        settings = {
          log.enabled = true;
          opener.text = [
            {
              run = "${editorBin} \"$@\"";
              block = true;
            }
          ];
          open.rules = textRules;
        };

        # ~/.config/yazi/keymap.toml — yazi reads keymaps from a dedicated file
        # (not yazi.toml), and the manager section was renamed `[manager]` ->
        # `[mgr]` (#2803). `prepend_keymap` layers on top of the defaults.
        keymap.mgr.prepend_keymap = [
          {
            on = "l";
            run = "plugin smart-enter";
            desc = "Enter the child directory, or open the file";
          }
        ];

        # Vendored plugin + init.lua wired through home-manager's native
        # options. The plugin entry file MUST be `main.lua` — the loader
        # defaults to entry "main", not "init".
        plugins.smart-enter = ./plugins/smart-enter.yazi;
        initLua = ./init.lua;
      };
    };
  };
}
