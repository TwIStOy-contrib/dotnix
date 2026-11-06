-- Shared Rex server config, consumed by:
--   - taihou's system rex server (modules/nixos/dotnix/services/rex.nix)
--   - the macOS app's local bundled server (modules/darwin/dotnix/apps/rex.nix)
-- The actions live in separate files under actions/. Apply with
-- `rex config check && rex config reload` on the machine that owns the server
-- (reload is refused over remote connections).

require("actions")

-- Use cmd+r as a prefix for rex commands

rex.bind("cmd+r>cmd+p", "pi_split")

-- Font fitting is a standalone script, not a config action: run it where the
-- Mac client is with `rex-font-fit`, or on a synced host with
-- `rex do ~/.config/rex/font-fit.lua`.
