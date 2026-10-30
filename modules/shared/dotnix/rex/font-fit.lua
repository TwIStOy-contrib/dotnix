-- Run on the Mac: rex do ~/.config/rex/font-fit.lua [client=<id|label>] [session=<id>] [dry_run=true]
-- A remote invocation must supply display={client_id,width_pt,height_pt,default_font_pt,...} via --args.
local args = rex.args
local api = rex
local session_id = args.session or rex.session_id
local foreground_only = args.foreground_only == true or args.current == true
local active_only = args.active_only == true
local terminal = "com.superlogical.terminal"
local tiers = {
  {w = 2400, pt = 18},
  {w = 1500, pt = 12},
  {w = 0, pt = 10},
}

local function number(value, name, minimum, maximum)
  if type(value) ~= "number" or value ~= value or value < minimum or value > maximum then
    error(name .. " must be a number between " .. minimum .. " and " .. maximum, 0)
  end
  return value
end

local display = args.display
local measured_locally = display == nil
local function read_display(activate, focus_only)
  local source = debug.getinfo(1, "S").source:gsub("^@", "")
  local directory = source:match("^(.*[/\\])") or "./"
  local helper = directory .. "display-info.js"
  local file = io.open(helper, "r")
  if file == nil then
    error("Run rex-font-fit on the target Mac, or pass display metadata from that Mac via --args", 0)
  end
  file:close()
  local argv = {"/usr/bin/osascript", "-l", "JavaScript", helper}
  local native_window = args.native_window or (display and display.window_id)
  if native_window ~= nil then argv[#argv + 1] = tostring(native_window)
  elseif activate or focus_only then argv[#argv + 1] = "" end
  if activate then argv[#argv + 1] = "activate"
  elseif focus_only then argv[#argv + 1] = "focus" end
  local result, err = rex.exec(argv, {timeout = 10})
  if err ~= nil then error("Read the display on the target Mac: " .. err, 0) end
  if not result.ok then error("Cannot read the Rex display: " .. result.stderr, 0) end
  local measured
  measured, err = rex.json.decode(result.stdout)
  if err ~= nil then error(err, 0) end
  return measured
end
if measured_locally then display = read_display(false, args.size ~= nil) end
if type(display) ~= "table" then error("display must be an object", 0) end
if args.size == nil then
  number(display.width_pt, "display.width_pt", 1, 100000)
  number(display.height_pt, "display.height_pt", 1, 100000)
end

local function current_session(measured)
  return measured.focused_session and measured.focused_session.sessionID
end

local function current_server(measured)
  return ((measured.focused_session or {}).externalServerID or ""):lower()
end

if args.current == true then
  if not measured_locally then error("current=true must run on the target Mac", 0) end
  session_id = current_session(display)
  if session_id == nil then error("Rex has not reported a focused session", 0) end
  local external_id = current_server(display)
  if external_id ~= "" then
    local hosts, err = rex.call("hosts.list")
    if err ~= nil then error(err, 0) end
    local label
    for _, host in ipairs(hosts.hosts or {}) do
      if host.id:lower():gsub("^host:", "") == external_id then label = host.label end
    end
    if label == nil then error("The focused Rex server is missing from the local host list", 0) end
    api = rex.server(label)
  end
end

local function check_foreground()
  local current = read_display(false, true)
  if not current.frontmost or current.front_window_id ~= display.window_id or
      current_session(current) ~= current_session(display) or current_server(current) ~= current_server(display) then
    error("Rex focus changed; stopped font_fit", 0)
  end
end
if foreground_only then
  if not measured_locally then error("foreground_only requires local display detection", 0) end
  check_foreground()
end

local function hostname(name)
  return (name or ""):lower():gsub("%.local$", "")
end

local function is_local_app(client)
  local info = client.info or {}
  if info.kind ~= "app" or info.platform ~= "macos" then return false end
  local principal = client.principal or {}
  if principal.kind == "peer" then return principal.pid == display.pid end
  return info.label ~= nil and hostname(info.label) == hostname(display.host_name)
end

local clients, client_err = api.call("client.list")
if client_err ~= nil then error(client_err, 0) end
local selected = args.client or (args.current ~= true and os.getenv("REX_CLIENT")) or display.client_id
local matches = {}
for _, client in ipairs(clients.clients) do
  local info = client.info or {}
  local matches_target = selected ~= nil and (client.client_id == selected or info.label == selected)
  if matches_target or (selected == nil and measured_locally and is_local_app(client)) then
    matches[#matches + 1] = client
  end
end
if #matches ~= 1 then error("Select one connected Mac app with client=<id|label>", 0) end
local client = matches[1]
local client_id = client.client_id
if measured_locally and not is_local_app(client) then
  error("The target client is not this Mac; run rex-font-fit there (remote app labels must match its hostname)", 0)
end
if not measured_locally and display.client_id ~= client_id then
  error("display.client_id must identify the target Mac client", 0)
end
if (client.info or {}).kind ~= "app" or (client.info or {}).platform ~= "macos" then
  error("font_fit requires a macOS Rex app", 0)
end
display.client_id = client_id

if measured_locally and args.dry_run ~= true and not foreground_only then
  display = read_display(true)
  if not display.frontmost or not is_local_app(client) then
    error("Bring the target Rex app to the front before running font_fit", 0)
  end
  display.client_id = client_id
end
local baseline = number(display.default_font_pt, "display.default_font_pt", 1, 72)

local target = args.size
if target == nil then
  for _, tier in ipairs(tiers) do
    if display.width_pt >= tier.w then target = tier.pt; break end
  end
end
number(target, "size", 1, 72)
local delta = target - baseline
if delta % 1 ~= 0 then error("size must differ from the client's default font by whole points", 0) end

if session_id == nil and #(client.session_ids or {}) == 1 then session_id = client.session_ids[1] end
if session_id == nil then error("Select a session with session=<id> or -s <session>", 0) end
if foreground_only and session_id ~= current_session(display) then
  error("The requested session is not visible in the focused Rex window", 0)
end
local attached = false
for _, id in ipairs(client.session_ids or {}) do
  if id == session_id then attached = true end
end
if not attached then error("The target client is not attached to this session", 0) end
local _, attach_err = api.session.attach{session_id = session_id}
if attach_err ~= nil then error(attach_err, 0) end
local view, view_err = api.session.view{session_id = session_id}
if view_err ~= nil then error(view_err, 0) end
local window
for _, candidate in ipairs(view.windows) do
  if candidate.window_id == view.active_window_id then window = candidate end
end
if window == nil then error("The session has no active window", 0) end

local panes = {}
for _, layer in ipairs(window.layers) do
  for _, block in ipairs(layer.blocks or {}) do
    if block.creator_name == terminal and
        (not active_only or window.focused_block_id == block.block_id) and
        (window.zoomed_block_id == nil or window.zoomed_block_id == block.block_id) then
      panes[#panes + 1] = {block_id = block.block_id, steps = math.abs(delta)}
    end
  end
end
if #panes == 0 and not active_only then error("The active window has no visible terminal panes", 0) end
local report = {
  client_id = client_id, session_id = session_id, window_id = window.window_id,
  display = display, target_pt = target, panes = panes, dry_run = args.dry_run == true,
}
if report.dry_run or #panes == 0 then return report end

if args.plan ~= nil then
  local plan = args.plan
  if type(plan) ~= "table" or type(plan.display) ~= "table" or type(plan.panes) ~= "table" or
      plan.client_id ~= client_id or plan.session_id ~= session_id or plan.window_id ~= window.window_id or
      plan.target_pt ~= target or plan.display.default_font_pt ~= baseline then
    error("The font-fit plan changed; stopped font_fit", 0)
  end
  local visible = {}
  for _, pane in ipairs(panes) do visible[pane.block_id] = pane end
  panes = {}
  for _, pane in ipairs(plan.panes) do
    local current = visible[pane.block_id]
    if current == nil then error("The visible panes changed; stopped font_fit", 0) end
    panes[#panes + 1] = current
    visible[pane.block_id] = nil
  end
  report.panes = panes
  if #panes == 0 then return report end
end

if not foreground_only then
  local _, select_err = api.call("client.perform", {
    client_id = client_id, action = "session.select",
    args = {session_id = session_id, window_id = window.window_id}, timeout_ms = 3000,
  })
  if select_err ~= nil then error(select_err, 0) end
  rex.sleep(0.3)
end

local function check_pane(block_id)
  local current, err = api.session.view{session_id = session_id}
  if err ~= nil then error(err, 0) end
  if current.active_window_id ~= window.window_id then error("The active tab changed; stopped font_fit", 0) end
  for _, candidate in ipairs(current.windows) do
    if candidate.window_id == window.window_id and candidate.focused_block_id ~= block_id then
      error("The focused pane changed; stopped font_fit", 0)
    end
  end
end

local last_focused = window.focused_block_id
local function focus(block_id)
  if block_id == last_focused then return false end
  check_pane(last_focused)
  local _, err = api.session.focus_block{session_id = session_id, block_id = block_id}
  if err ~= nil then error(err, 0) end
  last_focused = block_id
  return true
end

local function perform(action, block_id, allow_disabled_reset)
  if foreground_only then check_foreground() end
  check_pane(block_id)
  local _, action_err = api.call("client.perform", {
    client_id = client_id, session_id = session_id, block_id = block_id,
    action = action, timeout_ms = 3000,
  })
  if action_err ~= nil then
    if allow_disabled_reset and tostring(action_err):find("code=not_supported", 1, true) then return false end
    error(action_err, 0)
  end
  return true
end

-- Reset uses this client's preference, independent of the shared terminal grid's owner.
local ok, failure = pcall(function()
  for _, pane in ipairs(panes) do
    if foreground_only then check_foreground() end
    if not active_only and focus(pane.block_id) then rex.sleep(0.3) end
    -- Reset is disabled when already at the default; no font change is needed.
    perform("client.font.reset", pane.block_id, true)
    for _ = 1, pane.steps do
      rex.sleep(0.15)
      perform(delta > 0 and "client.font.increase" or "client.font.decrease", pane.block_id)
    end
  end
end)
local restored, restore_err = pcall(function()
  if active_only then return end
  if foreground_only and not pcall(check_foreground) then return end
  local current, err = api.session.view{session_id = session_id}
  if err ~= nil then error(err, 0) end
  if current.active_window_id ~= window.window_id then return end
  for _, candidate in ipairs(current.windows) do
    if candidate.window_id == window.window_id and candidate.focused_block_id ~= last_focused then return end
  end
  if window.focused_block_id ~= nil then focus(window.focused_block_id) end
end)
if not ok then error(failure, 0) end
if not restored then error(restore_err, 0) end
return report
