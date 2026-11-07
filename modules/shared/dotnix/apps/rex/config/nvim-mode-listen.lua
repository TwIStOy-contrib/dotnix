-- nvim-mode-listen.lua: mirror each block's neovim mode and session focus
-- into hammerspoon memory. macOS client-side; run with `rex do` (os.getenv
-- and friends are required, so this cannot run as a client script, whose
-- sandbox has no os/io and no rex.exec).
--
-- Listens for the OSC 7501 records published by dotvim's config/rex.nix
-- (id = nvim/mode) and pushes them into the hs global:
--   rexNvim = {
--     blocks   = { [block_id] = {mode=, state=, updated_at=, pid=,
--                                session=, server=} },
--     last     = { block=, mode=, state=, updated_at= },
--     sessions = { [session_id] = {focused_block=, updated_at=} },
--     focused  = block_id of the most recently focused block,
--   }
-- Hooks (all optional, called via pcall from the pushed chunk):
--   rexNvimOnMode(block, mode)   after a block's entry is updated
--   rexNvimOnGone(block)         after a block's entry is removed
--   rexNvimOnFocus(block)        after rexNvim.focused changes
--
-- Usually started by the rexNvimSup supervisor in rex-nvim-im.lua (an
-- hs.task that restarts this script and passes HS_BIN). Manually:
--   rex do ~/.config/rex/nvim-mode-listen.lua --all
-- A second server's stream: rex -S <server> do <this> --all server=<label>
-- NOTE: with two instances, both write rexNvim.focused/sessions; namespace
-- per server before relying on them in a multi-server setup.
--
-- On startup the script reconciles: every session's view is read and every
-- block's program_status is pulled, so nvim instances already running are
-- seeded into hs. Fields interpolated into `hs -c` are validated against
-- [%w:._+-] as an injection guard; anything else is skipped and logged.

local home = os.getenv("HOME")
local hs_bin = os.getenv("HS_BIN") or "hs"
local server = (rex.args or {}).server or "local"
local RECORD_ID = "nvim/mode"

local known = {}   -- blocks we have pushed state for
local focused = nil -- block_id rexNvim.focused last showed

local INIT = "rexNvim=rexNvim or {blocks={},last={},sessions={}};"
  .. "local r=rexNvim;r.sessions=r.sessions or {};"
  -- Bootstrap the hs-side consumer once per hs lifetime; the hammerspoon
  -- init.lua also dofiles it, so this only heals a missed reload.
  .. "if rexNvimOnMode==nil then "
  .. "pcall(dofile,'" .. home .. "/.hammerspoon/rex-nvim-im.lua') end"

local function safe(v)
  return type(v) == "string" and v:match("^[%w:._+-]+$") ~= nil
end

local function hs_eval(expr)
  local r, err = rex.exec({ hs_bin, "-c", expr }, { timeout = 10 })
  if r == nil then
    rex.log("hs exec failed: " .. tostring(err))
    return false
  end
  if not r.ok then
    rex.log(string.format("hs rc=%d %s", r.code or -1,
      tostring(r.stderr):gsub("%s+$", "")))
    return false
  end
  return true
end

local function push(block, session, rec)
  local mode, state, ts = rec.msg, rec.state, rec.updated_at
  local pid = (rec.owner or {}).pid
  if not (safe(mode) and safe(state) and safe(ts) and safe(block)
          and safe(session)) or type(pid) ~= "number" then
    rex.log("skip record with unsafe fields: " .. block
      .. " mode=" .. tostring(mode))
    return
  end
  local entry = string.format(
    "{mode='%s',state='%s',updated_at='%s',pid=%d,session='%s',server='%s'}",
    mode, state, ts, pid, session, server)
  local ok = hs_eval(string.format(
    INIT .. ";" ..
    "r.blocks['%s']=%s;" ..
    "r.last={block='%s',mode='%s',state='%s',updated_at='%s'};" ..
    "if rexNvimOnMode then pcall(rexNvimOnMode,'%s','%s') end",
    block, entry, block, mode, state, ts, block, mode))
  if ok then
    known[block] = true
    rex.log(string.format("%s %s mode=%s", server, block, mode))
  end
end

local function drop(block)
  if not safe(block) then return end
  local ok = hs_eval(string.format(
    INIT .. ";" ..
    "rexNvim.blocks['%s']=nil;" ..
    "if rexNvim.last and rexNvim.last.block=='%s' then rexNvim.last={} end;" ..
    "if rexNvimOnGone then pcall(rexNvimOnGone,'%s') end",
    block, block, block))
  if ok then
    known[block] = nil
    rex.log(string.format("%s %s removed", server, block))
  end
end

local function now()
  return os.date("!%Y-%m-%dT%H:%M:%SZ")
end

local function push_focus(block, session)
  local ok = hs_eval(string.format(
    INIT .. ";" ..
    "r.focused='%s';" ..
    "r.sessions['%s']={focused_block='%s',updated_at='%s'};" ..
    "if rexNvimOnFocus then pcall(rexNvimOnFocus,'%s') end",
    block, session, block, now(), block))
  if ok then
    focused = block
    rex.log(string.format("%s focus=%s", server, block))
  end
end

-- Recompute the focused block of a session's active window and push it
-- when it changed. Accepts a view already fetched (reconcile reuses it).
local function recompute_focus(sid, view)
  view = view or rex.session.view{ session_id = sid }
  if view == nil then return end
  local block
  for _, w in ipairs(view.windows or {}) do
    if w.window_id == view.active_window_id then
      block = w.focused_block_id
      break
    end
  end
  if block ~= nil and block ~= focused and safe(block) and safe(sid) then
    push_focus(block, sid)
  end
end

-- Seed hs with what is already alive: focus of each session's active
-- window plus every block's live nvim/mode record.
local function reconcile()
  local l = rex.call("session.list")
  local count = 0
  local sessions = (l or {}).sessions or {}
  -- session.view from the script's top level needs the stream attached to a
  -- session. Attaching to any one unlocks views of every session and does
  -- not narrow the --all event hearing (both verified live).
  if sessions[1] ~= nil then
    local _, err = rex.session.attach{session_id = sessions[1].session_id}
    if err ~= nil then
      rex.log("attach for reconcile: " .. tostring(err))
    end
  end
  for _, s in ipairs(sessions) do
    local sid = s.session_id
    local v = rex.session.view{ session_id = sid }
    if v ~= nil then
      recompute_focus(sid, v)
      for _, w in ipairs(v.windows or {}) do
        for _, ly in ipairs(w.layers or {}) do
          for _, b in ipairs(ly.blocks or {}) do
            local ps = rex.block.call("com.superlogical.terminal",
              "program_status",
              { block_id = b.block_id, session_id = sid })
            for _, rec in ipairs((ps or {}).records or {}) do
              if rec.id == RECORD_ID then
                push(b.block_id, sid, rec)
                count = count + 1
              end
            end
          end
        end
      end
    end
  end
  rex.log(string.format("reconcile: %d live nvim record(s)", count))
end

rex.on("terminal.program_status_changed", function(ctx, ev)
  if ev.id ~= RECORD_ID then return end
  if ev.state == "clear" then
    drop(ctx.block_id)
  else
    push(ctx.block_id, ctx.session_id, ev.record or {})
  end
end)

rex.on("terminal.program_status_removed", function(ctx, ev)
  for _, id in ipairs(ev.ids or {}) do
    if id == RECORD_ID then drop(ctx.block_id) return end
  end
end)

-- A pane closed with nvim killed outright never sends its clear report.
rex.on("block_closed", function(ctx, ev)
  local block = ev.block_id or ctx.block_id
  if known[block] then drop(block) end
  if block == focused then recompute_focus(ctx.session_id) end
end)

rex.on("active_window_changed", function(ctx, _)
  recompute_focus(ctx.session_id)
end)

rex.on("session_view_changed", function(ctx, _)
  recompute_focus(ctx.session_id)
end)

-- Wait for the hs IPC channel before reconciling: the supervisor starts
-- this script from the hammerspoon init.lua, which races hs's own reload
-- (early `hs -c` calls hit an invalidated message port).
local tries = 0
while not hs_eval("rexNvim=rexNvim or {blocks={},last={},sessions={}}")
  and tries < 5 do
  tries = tries + 1
  rex.sleep(1)
end
if tries >= 5 then
  rex.log("hs channel unavailable after retries; proceeding anyway")
end

reconcile()
rex.log("hs channel: "
  .. (hs_eval("rexNvim=rexNvim or {blocks={},last={},sessions={}}")
    and "ok" or "FAILED"))
