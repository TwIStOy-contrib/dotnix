-- Actions for the shared Rex config: `require("actions")` from ../init.lua
-- (a directory resolves to its init.lua).
--
-- Paths are substituted at eval time, each only a first candidate: the same
-- files also run on machines this repo does not manage, so every value below
-- is checked for existence and falls back to what the local machine has.
--   @hmProfileBin@  per-user HM profile bin dir (login fish for terminals)
--   @rexBin@        absolute rex CLI path for server-side exec (font_fit)
--   @hmConfigDir@   config dir holding the sibling font-fit.lua
--   @rexServer@     REX_SERVER socket URL for exec'd scripts
-- macOS also installs display-info.js next to font-fit.lua.

local shell = "com.superlogical.terminal.shell"

local function readable(path)
  if path == nil or path == "" then return false end
  local file = io.open(path, "r")
  if file == nil then return false end
  file:close()
  return true
end

-- First path that exists; nil when none do.
local function pick(paths)
  for _, path in ipairs(paths) do
    if readable(path) then return path end
  end
  return nil
end

local function env(name)
  local value = os.getenv(name)
  if value == "" then return nil end
  return value
end

local home = env("HOME") or ""
local configHome = env("XDG_CONFIG_HOME") or (home .. "/.config")
-- REX_CONFIG points at the file itself; its directory holds the siblings.
local configDir = (env("REX_CONFIG") or ""):match("^(.*)/[^/]+$") or (configHome .. "/rex")

-- A terminal block's command execs directly in the server's environment, so
-- the login shell has to be given by path: the HM profile on this repo's
-- hosts, the usual install locations on a plain machine. SHELL comes last —
-- it is the account's shell, which is what Rex itself would start.
local shellPath =
  pick {
    "@hmProfileBin@/fish",
    home .. "/.nix-profile/bin/fish",
    "/run/current-system/sw/bin/fish",
    "/opt/homebrew/bin/fish",
    "/usr/local/bin/fish",
    "/usr/bin/fish",
    "/bin/fish",
  }
  or env("SHELL")
  or "/bin/sh"

-- font_fit execs a script through the CLI; both are paths this repo installs,
-- with the local equivalents as fallback.
local rexCandidates = {
  "@rexBin@",
  "/run/current-system/sw/bin/rex",
  "/opt/homebrew/bin/rex",
  "/usr/local/bin/rex",
}
local binDir = env("REX_BIN_DIR")
if binDir ~= nil then table.insert(rexCandidates, 2, binDir .. "/rex") end
local rexBin = pick(rexCandidates) or "rex"
local fontFit = pick {
  "@hmConfigDir@/rex/font-fit.lua",
  configDir .. "/font-fit.lua",
}
local rexServer = env("REX_SERVER") or "@rexServer@"

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
          -- Login shell so `exec pi` resolves through the account profile
          -- (nix profile, ~/.local/bin, PATH); the server's own PATH usually
          -- has no pi on it.
          command = { shellPath, "-l", "-c", "exec pi" },
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
    if fontFit == nil then
      error("font-fit.lua is not installed next to init.lua", 0)
    end
    local argv = {
      rexBin, "do", fontFit,
      "--args", encoded,
    }
    local r, err = rex.exec(argv, {
      env = { REX_SERVER = rexServer },
      timeout = 120,
    })
    if err ~= nil then error(err, 0) end
    if not r.ok then error("font-fit.lua: " .. r.stderr, 0) end
    local out, jerr = rex.json.decode((r.stdout:gsub("%s+$", "")))
    if jerr ~= nil then error("font-fit.lua returned invalid JSON: " .. jerr, 0) end
    return out
  end,
}
