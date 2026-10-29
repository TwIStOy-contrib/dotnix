-- Shared Rex server config, consumed by:
--   - taihou's system rex server (modules/nixos/dotnix/services/rex.nix)
--   - the macOS app's local bundled server (modules/darwin/dotnix/apps/rex.nix)
-- Substituted at eval time:
--   @hmProfileBin@  per-user HM profile bin dir (login fish for terminals)
--   @rexBin@        absolute rex CLI path for server-side exec (font_fit)
--   @hmConfigDir@   config dir holding the sibling font-fit.lua
--   @rexServer@     REX_SERVER socket URL for exec'd scripts
-- Sibling scripts (font-fit.lua) are shared verbatim.
-- Apply with `rex config check && rex config reload` on the machine that
-- owns the server (reload is refused over remote connections).

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

-- Steps per-pane fonts through the font-fit.lua script: font zoom
-- is per-pane, only the client's focused pane can be stepped, and
-- the stepping needs sleeps that config-file actions cannot do.
-- client.perform from outside the app requires Remote Control on.
rex.action{
  name  = "font_fit",
  title = "Fit Font to Window",
  description = "One font size for every pane in the window, picked from its width.",
  args  = { size = "number?" },
  run   = function(ctx, args)
    if ctx.client_id == nil then
      error("font_fit runs inside the app, or from the CLI with -C <client>", 0)
    end
    local argv = {
      "@rexBin@", "do", "@hmConfigDir@/rex/font-fit.lua",
      "session=" .. ctx.session_id,
      "client=" .. ctx.client_id,
    }
    if args.size ~= nil then
      argv[#argv + 1] = "size=" .. tostring(args.size)
    end
    local r, err = rex.exec(argv, {
      env = { REX_SERVER = "@rexServer@" },
      timeout = 120,
    })
    if err ~= nil then error(err, 0) end
    if not r.ok then error("font-fit.lua: " .. r.stderr, 0) end
    local out, jerr = rex.json.decode((r.stdout:gsub("%s+$", "")))
    if jerr ~= nil then return {raw = r.stdout} end
    return out
  end,
}
