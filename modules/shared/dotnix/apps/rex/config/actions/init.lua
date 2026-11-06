-- Actions for the shared Rex config: `require("actions")` from ../init.lua
-- (a directory resolves to its init.lua).

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
          -- Let the login shell resolve fish and pi on the machine running
          -- the terminal, instead of embedding another machine's paths.
          command = { "fish", "-l", "-c", "exec pi" },
        },
      },
    }
    if err ~= nil then error(err, 0) end
  end,
}

-- Font fitting is a standalone script, not a config action: run it where the
-- Mac client is with `rex-font-fit`, or on a synced host with
-- `rex do ~/.config/rex/font-fit.lua`.
