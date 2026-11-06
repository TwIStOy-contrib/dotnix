-- Shared Rex server config, consumed by:
--   - taihou's system rex server (modules/nixos/dotnix/services/rex.nix)
--   - the macOS app's local bundled server (modules/darwin/dotnix/apps/rex.nix)
-- The actions live in actions/init.lua, which documents the values substituted
-- at eval time. Apply with `rex config check && rex config reload` on the
-- machine that owns the server (reload is refused over remote connections).

require("actions")

rex.bind("ctrl+x>ctrl+x", "pane.send_key", { key = "ctrl+x" })
rex.bind("ctrl+x>ctrl+p", "pi_split")
