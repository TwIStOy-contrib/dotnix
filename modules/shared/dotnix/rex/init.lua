-- Shared Rex server config, consumed by:
--   - taihou's system rex server (modules/nixos/dotnix/services/rex.nix)
--   - the macOS app's local bundled server (modules/darwin/dotnix/apps/rex.nix)
-- Substituted at eval time:
--   @hmProfileBin@  per-user HM profile bin dir (login fish for terminals)
--   @rexBin@        absolute rex CLI path for server-side exec (font_fit)
--   @hmConfigDir@   config dir holding the sibling font-fit.lua
--   @rexServer@     REX_SERVER socket URL for exec'd scripts
-- macOS also installs display-info.js next to font-fit.lua.
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

-- Remote servers need display metadata collected on the target Mac.
-- client.perform requires Remote Control in the app's server settings.
rex.action{
  name  = "font_fit",
  title = "Fit Font to Display",
  description = "Use the Mac display's size for every pane. For remote sessions, run rex-font-fit on the Mac.",
  args  = { size = "number?", display = "object?", native_window = "integer?", dry_run = "boolean?" },
  run   = function(ctx, args)
    if ctx.client_id == nil then
      error("font_fit runs inside the app, or from the CLI with -C <client>", 0)
    end
    if ctx.session_id == nil then error("font_fit requires a session", 0) end
    local script_args = {
      session = ctx.session_id, client = ctx.client_id,
      size = args.size, display = args.display,
      native_window = args.native_window, dry_run = args.dry_run,
    }
    local encoded, encode_err = rex.json.encode(script_args)
    if encode_err ~= nil then error(encode_err, 0) end
    local argv = {
      "@rexBin@", "do", "@hmConfigDir@/rex/font-fit.lua",
      "--args", encoded,
    }
    local r, err = rex.exec(argv, {
      env = { REX_SERVER = "@rexServer@" },
      timeout = 120,
    })
    if err ~= nil then error(err, 0) end
    if not r.ok then error("font-fit.lua: " .. r.stderr, 0) end
    local out, jerr = rex.json.decode((r.stdout:gsub("%s+$", "")))
    if jerr ~= nil then error("font-fit.lua returned invalid JSON: " .. jerr, 0) end
    return out
  end,
}
