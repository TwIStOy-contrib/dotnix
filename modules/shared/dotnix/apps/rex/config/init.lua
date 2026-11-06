-- Shared Rex server config, consumed by:
--   - taihou's system rex server (modules/nixos/dotnix/services/rex.nix)
--   - the macOS app's local bundled server (modules/darwin/dotnix/apps/rex.nix)
-- The actions live in actions/init.lua. Apply with
-- `rex config check && rex config reload` on the machine that owns the server
-- (reload is refused over remote connections).

require("actions")

-- Use cmd+r as a prefix for rex commands

rex.bind("cmd+r>cmd+p", "pi_split")
