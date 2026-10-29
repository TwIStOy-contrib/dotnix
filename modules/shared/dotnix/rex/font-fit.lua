-- Usage: rex do font-fit.lua session=<id> client=<id> [size=<pt>]
local session_id = rex.args.session
local client_id = rex.args.client
if session_id == nil or client_id == nil then
  error("font-fit.lua needs session= and client= arguments", 0)
end

-- Window width in logical points -> font size in points. Tunable:
-- first row whose w fits the window wins.
local tiers = {
  {w = 2400, pt = 28},
  {w = 1800, pt = 25},
  {w = 1300, pt = 21},
  {w = 900,  pt = 17},
  {w = 0,    pt = 14},
}

local terminal = "com.superlogical.terminal"

local _, err = rex.session.attach{session_id = session_id}
if err ~= nil then error(err, 0) end

local v, verr = rex.session.view{session_id = session_id}
if verr ~= nil then error(verr, 0) end

local win = nil
for _, w in ipairs(v.windows) do
  if w.window_id == v.active_window_id then win = w end
end
if win == nil then error("the session has no active window", 0) end

local panes = {}
local function walk(node)
  if node.block_id ~= nil then
    panes[#panes + 1] = {block_id = node.block_id, rect = node.rect}
  end
  if node.split ~= nil then
    walk(node.split.before)
    walk(node.split.after)
  end
end
for _, layer in ipairs(win.layers) do
  if layer.kind ~= "floating" and layer.layout ~= nil then walk(layer.layout) end
end
if #panes == 0 then error("the window has no panes", 0) end

local function size_of(block_id)
  local s, serr = rex.block.call(terminal, "size", {session_id = session_id, block_id = block_id})
  if serr ~= nil then return nil end
  return s
end

-- Cells are 2x the point size on the Mac clients, so any pane's
-- width over its normalized share gives the window width.
local win_pt = nil
for _, p in ipairs(panes) do
  local s = size_of(p.block_id)
  if s ~= nil then
    p.ch = s.cell_height_px
    if p.rect ~= nil and p.rect[3] ~= nil and p.rect[3] > 0 then
      local w = s.columns * s.cell_width_px / p.rect[3] / 2
      if win_pt == nil or w > win_pt then win_pt = w end
    end
  end
end
if win_pt == nil then error("cannot measure the window width", 0) end

local target = tonumber(rex.args.size)
if target == nil then
  for _, tier in ipairs(tiers) do
    if win_pt >= tier.w then
      target = tier.pt
      break
    end
  end
end
if target == nil then error("no tier matches the window", 0) end

local function perform(action)
  local _, perr = rex.call("client.perform", {
    client_id = client_id, action = action, timeout_ms = 3000,
  })
  if perr ~= nil then error(perr, 0) end
end

local want = target * 2
local report = {window_pt = math.floor(win_pt + 0.5), target_pt = target, panes = {}}

for _, p in ipairs(panes) do
  local r = {steps = 0}
  if p.ch ~= nil then
    r.from_pt = p.ch / 2
    local _, ferr = rex.session.focus_block{session_id = session_id, block_id = p.block_id}
    if ferr ~= nil then error(ferr, 0) end
    rex.sleep(0.3)
    local misses = 0
    while r.steps < 40 do
      local before = size_of(p.block_id)
      if before == nil then error("lost the pane", 0) end
      local delta = want - before.cell_height_px
      if math.abs(delta) < 2 then break end
      perform(delta > 0 and "client.font.increase" or "client.font.decrease")
      rex.sleep(0.15)
      local after = size_of(p.block_id)
      if after == nil or after.cell_height_px == before.cell_height_px then
        misses = misses + 1
        if misses >= 2 then
          error("a font step did not change the pane (focus moved?); re-run font_fit", 0)
        end
      else
        misses = 0
        r.steps = r.steps + 1
      end
    end
    local done = size_of(p.block_id)
    if done ~= nil then r.to_pt = done.cell_height_px / 2 end
  end
  report.panes[#report.panes + 1] = r
end

if win.focused_block_id ~= nil then
  rex.session.focus_block{session_id = session_id, block_id = win.focused_block_id}
end

return report
