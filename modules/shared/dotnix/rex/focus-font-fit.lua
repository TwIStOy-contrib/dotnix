local M = {}

function M.start(options)
  local log = hs.logger.new("rex-font-fit")
  local completed = {}
  local task
  local pending
  local hotkey
  local filter

  local function focused_window()
    local window = hs.window.focusedWindow()
    local app = window and window:application()
    if app and app:bundleID() == "com.superlogical.rex" then return window end
  end

  local function still_focused(id)
    local window = focused_window()
    return window ~= nil and window:id() == id
  end

  local function launch(id, dry_run, callback)
    task = hs.task.new(options.rex, function(code, stdout, stderr)
      task = nil
      if code ~= 0 then
        log.w(stderr)
        if not dry_run then completed[id] = nil end
        return
      end
      if not still_focused(id) then return end
      callback(hs.json.decode(stdout))
    end, {
      "--autostart=false", "--server", options.server, "do", options.script,
      "current=true", "native_window=" .. id, "dry_run=" .. tostring(dry_run),
    })
    if task == nil then log.e("Could not create the font-fit task"); return end
    local env = task:environment()
    env.REX_SESSION, env.REX_BLOCK, env.REX_CLIENT, env.REX_SERVER = nil, nil, nil, nil
    task:setEnvironment(env)
    if not task:start() then task = nil; log.e("Could not start font-fit") end
  end

  local function signature(plan)
    local panes = {}
    for _, pane in ipairs(plan.panes) do panes[#panes + 1] = pane.block_id end
    table.sort(panes)
    return hs.json.encode({
      plan.client_id, plan.session_id, plan.window_id, plan.display.display_id,
      plan.display.width_pt, plan.display.height_pt, plan.display.default_font_pt,
      plan.target_pt, panes,
    })
  end

  local function fit(force)
    if task ~= nil then return end
    local window = focused_window()
    if window == nil then return end
    local id = window:id()
    launch(id, true, function(plan)
      if type(plan) ~= "table" or type(plan.panes) ~= "table" then log.e("Invalid font-fit plan"); return end
      local key = signature(plan)
      if not force and completed[id] == key then return end
      launch(id, false, function(result)
        completed[id] = signature(result)
      end)
    end)
  end

  local function on_focus()
    if hotkey then hotkey:enable() end
    if not options.onFocus or task ~= nil then return end
    if pending then pending:stop() end
    pending = hs.timer.doAfter(0.4, function() pending = nil; fit(false) end)
  end

  if options.hotkey then
    hotkey = hs.hotkey.new(options.hotkey.modifiers, options.hotkey.key, function() fit(true) end)
  end
  filter = hs.window.filter.new(function(window)
    local app = window and window:application()
    return app ~= nil and app:bundleID() == "com.superlogical.rex"
  end)
  filter:subscribe(hs.window.filter.windowFocused, on_focus)
  filter:subscribe(hs.window.filter.windowUnfocused, function()
    if hotkey then hotkey:disable() end
    if pending then pending:stop(); pending = nil end
  end)
  filter:subscribe(hs.window.filter.windowDestroyed, function(window)
    local id = window:id()
    if id ~= nil then completed[id] = nil end
  end)
  if focused_window() then on_focus() end

  return {
    fit = function() fit(true) end,
    stop = function()
      filter:unsubscribeAll()
      if hotkey then hotkey:delete() end
      if pending then pending:stop() end
      if task then task:terminate() end
    end,
  }
end

return M
