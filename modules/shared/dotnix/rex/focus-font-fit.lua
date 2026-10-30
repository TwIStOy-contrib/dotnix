local M = {}

function M.start(options)
  local log = hs.logger.new("rex-font-fit")
  local completed = {}
  local task
  local pending
  local hotkey
  local filter
  local queued
  local stopped = false
  local fit

  local function focused_window()
    local window = hs.window.focusedWindow()
    local app = window and window:application()
    if app and app:bundleID() == "com.superlogical.rex" then return window end
  end

  local function still_focused(id)
    local window = focused_window()
    return window ~= nil and window:id() == id
  end

  local function launch(id, dry_run, callback, plan)
    task = hs.task.new(options.rex, function(code, stdout, stderr)
      if stopped then return end
      task = nil
      if code ~= 0 then
        log.w(stderr)
      elseif not dry_run or still_focused(id) then
        local result = hs.json.decode(stdout)
        if type(result) == "table" and type(result.panes) == "table" then
          callback(result)
        else
          log.e("Invalid font-fit result")
        end
      end
      if task == nil and queued ~= nil then
        local request = queued
        queued = nil
        if still_focused(request.id) then fit(request.force) end
      end
    end, {
      "--autostart=false", "--server", options.server, "do", options.script,
      "--args", hs.json.encode({current = true, native_window = id, dry_run = dry_run, plan = plan}),
    })
    if task == nil then log.e("Could not create the font-fit task"); return end
    local env = task:environment()
    env.REX_SESSION, env.REX_BLOCK, env.REX_CLIENT, env.REX_SERVER = nil, nil, nil, nil
    task:setEnvironment(env)
    if not task:start() then task = nil; log.e("Could not start font-fit") end
  end

  local function pane_key(plan, pane)
    return hs.json.encode({plan.client_id, plan.session_id, pane.block_id})
  end

  fit = function(force)
    if stopped then return end
    local window = focused_window()
    if window == nil then return end
    local id = window:id()
    if task ~= nil then
      queued = {id = id, force = force or (queued ~= nil and queued.id == id and queued.force)}
      return
    end
    completed[id] = completed[id] or {}
    local cache = completed[id]
    launch(id, true, function(plan)
      if completed[id] ~= cache then return end
      local remaining = {}
      for _, pane in ipairs(plan.panes) do
        local previous = cache[pane_key(plan, pane)]
        if force or previous == nil or previous.target_pt ~= plan.target_pt or
            previous.default_pt ~= plan.display.default_font_pt then
          remaining[#remaining + 1] = pane
        end
      end
      if #remaining == 0 then return end
      plan.panes = remaining
      for _, pane in ipairs(remaining) do cache[pane_key(plan, pane)] = nil end
      launch(id, false, function(result)
        if completed[id] ~= cache then return end
        for _, pane in ipairs(result.panes) do
          cache[pane_key(result, pane)] = {
            target_pt = result.target_pt, default_pt = result.display.default_font_pt,
          }
        end
      end, plan)
    end)
  end

  local function on_focus()
    if hotkey then hotkey:enable() end
    if not options.onFocus then return end
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
    queued = nil
  end)
  filter:subscribe(hs.window.filter.windowDestroyed, function(window)
    local id = window:id()
    if id ~= nil then completed[id] = nil end
  end)
  if focused_window() then on_focus() end

  return {
    fit = function() fit(true) end,
    stop = function()
      stopped = true
      queued = nil
      filter:unsubscribeAll()
      if hotkey then hotkey:delete() end
      if pending then pending:stop() end
      if task then task:terminate() end
    end,
  }
end

return M
