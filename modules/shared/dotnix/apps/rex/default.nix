# Shared Rex assets (https://superlogical.com/rex). The Rex server reads its
# config from $XDG_CONFIG_HOME/rex/init.lua, so every server that owns a
# socket needs these files: taihou's system service and the macOS app's local
# bundled server. The files are portable and contain no host-specific paths;
# rex-sync copies the same set to machines this repo does not manage.
#
# display-info.js is macOS-only: font fitting needs the Mac's display
# geometry and a Hammerspoon controller. Linux installs font-fit.lua
# only, and accepts display metadata handed over by the Mac.
# nvim-mode-listen.lua is also macOS-only (the client side of the
# nvim/mode input-method pipeline); Linux hosts never run it. The hs-side
# scripts this pipeline loads (rex-nvim-im.lua, focus-font-fit.lua) live in
# the darwin hammerspoon module and install under ~/.hammerspoon/.
{lib, ...}: {
  options.dotnix.rex.files = lib.mkOption {
    type = lib.types.attrsOf lib.types.lines;
    readOnly = true;
    internal = true;
    default =
      builtins.mapAttrs
      (_: path: builtins.readFile path)
      {
        # Sources under config/ are installed under ~/.config/rex/.
        "init.lua" = ./config/init.lua;
        "actions/init.lua" = ./config/actions/init.lua;
        "actions/pi_split.lua" = ./config/actions/pi_split.lua;
        "actions/swap_next_pane.lua" = ./config/actions/swap_next_pane.lua;
        "font-fit.lua" = ./config/font-fit.lua;
        "display-info.js" = ./config/display-info.js;
        "nvim-mode-listen.lua" = ./config/nvim-mode-listen.lua;
      };
    description = "Rex config files, keyed by path under ~/.config/rex/.";
  };
}
