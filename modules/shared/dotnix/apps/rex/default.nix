# Shared Rex assets (https://superlogical.com/rex). The Rex server reads its
# config from $XDG_CONFIG_HOME/rex/init.lua, so every server that owns a
# socket needs these files: taihou's system service and the macOS app's local
# bundled server. The Lua and its helpers are identical on both platforms;
# only the substituted paths differ, so the fill-in happens once here and the
# platform modules install the results. The values are also what the same
# files use when they run on a machine this repo does not manage (a copied
# config): there they are a first candidate and the Lua resolves the local
# equivalents itself.
#
# display-info.js and focus-font-fit.lua are macOS-only: font fitting needs
# the Mac's display geometry and a Hammerspoon controller. Linux installs
# font-fit.lua only, and accepts display metadata handed over by the Mac.
{
  config,
  lib,
  dotnix-constants,
  ...
}: let
  inherit (lib) mkOption types;
  inherit (dotnix-constants) user;

  cfg = config.dotnix.rex;
  homeDir = config.users.users.${user.name}.home;

  # Keep in sync with the header of init.lua.
  substitute =
    lib.replaceStrings
    ["@hmProfileBin@" "@rexBin@" "@hmConfigDir@" "@rexServer@"]
    [
      cfg.substitutions.hmProfileBin
      cfg.substitutions.rexBin
      cfg.substitutions.hmConfigDir
      cfg.substitutions.rexServer
    ];
in {
  options.dotnix.rex = {
    substitutions = {
      hmProfileBin = mkOption {
        type = types.str;
        default = "/etc/profiles/per-user/${user.name}/bin";
        internal = true;
        description = "Per-user home-manager profile bin dir, used to start a login shell.";
      };
      hmConfigDir = mkOption {
        type = types.str;
        default = "${homeDir}/.config";
        internal = true;
        description = "Config dir the Rex files are installed into.";
      };
      rexBin = mkOption {
        type = types.str;
        default = "${cfg.substitutions.hmProfileBin}/rex";
        internal = true;
        description = "Absolute rex CLI path for server-side exec.";
      };
      rexServer = mkOption {
        type = types.str;
        internal = true;
        description = "REX_SERVER socket URL for scripts the config execs.";
      };
    };

    files = mkOption {
      type = types.attrsOf types.lines;
      readOnly = true;
      internal = true;
      default =
        builtins.mapAttrs
        (_: path: substitute (builtins.readFile path))
        {
          # Everything installed under ~/.config/rex/; the two Lua files carry
          # the substitutions, the helpers are copied as they are.
          "init.lua" = ./init.lua;
          "actions/init.lua" = ./actions/init.lua;
          "font-fit.lua" = ./font-fit.lua;
          "display-info.js" = ./display-info.js;
          "focus-font-fit.lua" = ./focus-font-fit.lua;
        };
      description = "Rendered Rex config files, keyed by path under ~/.config/rex/.";
    };
  };
}
