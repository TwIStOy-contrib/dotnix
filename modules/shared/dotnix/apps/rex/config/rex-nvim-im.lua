-- rex-nvim-im.lua: switch the macOS input method with the focused nvim
-- block's mode. Driven by rexNvim updates pushed by nvim-mode-listen.lua
-- (rex do ~/.config/rex/nvim-mode-listen.lua --all), which calls the
-- rexNvimOnMode / rexNvimOnFocus / rexNvimOnGone hooks. Loaded by the
-- dotnix hammerspoon init.lua and by the listener's bootstrap.
--
-- Semantics (decided 2026-11-06):
-- - insert -> non-insert: when an input method (Squirrel, qingjian, ...) is
--   active, capture it per block and switch to this machine's ASCII layout,
--   which is discovered from the enabled keyboard layouts, never hardcoded.
--   Only while Rex is frontmost.
-- - non-insert -> insert: restore the captured source, but only when the
--   current source is still the layout we set (a manual switch in between
--   is respected).
-- - First insert with no capture yet, or an ASCII layout already active
--   when leaving insert: leave the input method untouched.

local rexBundleID = "com.superlogical.rex"
local debug = true

-- Pin the ASCII layout by source id if discovery must not be used.
local asciiOverride = nil

local savedSource = {}  -- block -> source id captured at last insert exit
local forcedSource = {} -- block -> source id we set (nil = not ours)
local prevMode = {}     -- block -> mode seen at the previous hook call

local function log(fmt, ...)
  if debug then print(string.format("[rex-nvim-im] " .. fmt, ...)) end
end

local function rexFrontmost()
  local app = hs.application.frontmostApplication()
  return app ~= nil and app:bundleID() == rexBundleID
end

local function currentSource()
  local ok, s = pcall(hs.keycodes.currentSourceID)
  return ok and s or nil
end

local function setSource(id)
  local ok, err = pcall(hs.keycodes.currentSourceID, id)
  if not ok then log("setSource(%s) failed: %s", tostring(id), tostring(err)) end
  return ok
end

-- Keyboard layouts use the com.apple.keylayout.* source-id prefix;
-- input methods (Squirrel, qingjian, Kotoeri, ...) use anything else.
local function isLayout(id)
  return type(id) == "string" and id:find("^com%.apple%.keylayout%.") ~= nil
end

local function asciiSourceId()
  if asciiOverride ~= nil then return asciiOverride end
  for _, id in ipairs(hs.keycodes.layouts(true) or {}) do
    if isLayout(id) then return id end
  end
  return nil
end

local function leavingInsert(block)
  local cur = currentSource()
  if isLayout(cur) then
    -- English was already active; nothing to capture or force.
    savedSource[block] = nil
    forcedSource[block] = nil
    log("%s left insert with layout %s; untouched", block:sub(-12), tostring(cur))
    return
  end
  if cur then savedSource[block] = cur end
  local target = asciiSourceId()
  if target ~= nil and rexFrontmost() then
    if setSource(target) then forcedSource[block] = target end
    log("%s left insert (had %s) -> %s", block:sub(-12), tostring(cur), target)
  else
    forcedSource[block] = nil
    log("%s left insert (had %s); no switch (%s)", block:sub(-12), tostring(cur),
      target == nil and "no ascii layout enabled" or "Rex not frontmost")
  end
end

local function enteringInsert(block)
  if forcedSource[block] ~= nil and currentSource() == forcedSource[block] then
    local target = savedSource[block]
    if target ~= nil and rexFrontmost() then
      setSource(target)
      log("%s entered insert -> restore %s", block:sub(-12), target)
    else
      log("%s entered insert; keep %s", block:sub(-12), tostring(currentSource()))
    end
  else
    log("%s entered insert; first time or manually changed, untouched",
      block:sub(-12))
  end
  forcedSource[block] = nil
end

function rexNvimOnMode(block, mode)
  local prev = prevMode[block]
  prevMode[block] = mode
  if rexNvim.focused ~= nil and block ~= rexNvim.focused then return end
  if mode == "insert" then
    enteringInsert(block)
  elseif prev == "insert" then
    leavingInsert(block)
  end
end

function rexNvimOnFocus(block)
  local st = (rexNvim.blocks or {})[block]
  if st ~= nil and st.mode == "insert" then
    enteringInsert(block)
  end
end

function rexNvimOnGone(block)
  savedSource[block] = nil
  forcedSource[block] = nil
  prevMode[block] = nil
end

-- Supervisor: keep the rex do event listener alive as an hs.task, so no
-- launchd agent is needed; hs is this Mac's always-on process. Paths are
-- HOME-derived so the same file works for every user.
local home = os.getenv("HOME") or ""
local REX_BIN = home
  .. "/Library/Application Support/com.superlogical.rex/RexServer/Versions/"
  .. "Current/Rex Server.app/Contents/MacOS/rex"
local REX_SERVER = "unix://" .. home
  .. "/Library/Application%20Support/rex/server.sock"
local LISTENER = home .. "/.config/rex/nvim-mode-listen.lua"
-- The hs IPC CLI installed by hs.ipc.cliInstall; the task env must name it
-- explicitly because hs itself runs with launchd's minimal PATH.
local HS_IPC = "/opt/homebrew/bin/hs"

rexNvimSup = { task = nil, retry = nil, stopped = false }

local function sup_start()
  if rexNvimSup.stopped then return end
  if hs.application.get(rexBundleID) == nil then
    rexNvimSup.retry = hs.timer.doAfter(10, sup_start)
    log("rex app not running; retrying supervisor in 10s")
    return
  end
  rexNvimSup.task = hs.task.new(REX_BIN, function(code, _, stderr)
    rexNvimSup.task = nil
    if rexNvimSup.stopped then return end
    log("listener exited rc=%s stderr=%s; restarting in 2s",
      tostring(code), (stderr or ""):sub(1, 200))
    rexNvimSup.retry = hs.timer.doAfter(2, sup_start)
  end, { "--autostart=false", "--server", REX_SERVER, "do", LISTENER, "--all" })
  if rexNvimSup.task == nil then log("could not create listener task") return end
  local env = rexNvimSup.task:environment()
  env.REX_SESSION, env.REX_BLOCK, env.REX_CLIENT, env.REX_SERVER = nil, nil, nil, nil
  env.HS_BIN = HS_IPC
  rexNvimSup.task:setEnvironment(env)
  if not rexNvimSup.task:start() then
    rexNvimSup.task = nil
    log("could not start listener task")
  end
end

function rexNvimSup.start()
  rexNvimSup.stopped = false
  if rexNvimSup.task == nil then sup_start() end
end

function rexNvimSup.stop()
  rexNvimSup.stopped = true
  if rexNvimSup.retry then rexNvimSup.retry:stop(); rexNvimSup.retry = nil end
  if rexNvimSup.task then rexNvimSup.task:terminate(); rexNvimSup.task = nil end
end
