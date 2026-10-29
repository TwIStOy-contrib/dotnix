-- Shared Rex server config, consumed by:
--   - taihou's system rex server   (modules/nixos/dotnix/services/rex.nix)
--   - the macOS app's local bundled server (modules/darwin/dotnix/apps/rex.nix)
-- @hmProfileBin@ is substituted with the per-user HM profile bin dir at
-- eval time. Apply with `rex config check && rex config reload` on the
-- machine that owns the server (reload is refused over remote connections).

local shell = "com.superlogical.terminal.shell"

rex.action{
  name  = "pi_split",
  title = "Open Pi Agent in Right Split",
  run   = function(ctx, args)
    local split, err = rex.session.new_split{
      direction = "horizontal", -- left-right axis
      side      = "after",      -- new pane to the right
      focus     = true,
      layout    = rex.layout.block{
        flavor  = shell,
        options = {
          -- The rex server's PATH does not include the HM profile, and a
          -- terminal block's command execs directly in that environment.
          -- Route through an absolute-path login fish so `exec pi` resolves
          -- to the HM-profile pi wrapper (LLM API keys + EDITOR).
          command = { "@hmProfileBin@/fish", "-l", "-c", "exec pi" },
        },
      },
    }
    if err ~= nil then error(err, 0) end
  end,
}
