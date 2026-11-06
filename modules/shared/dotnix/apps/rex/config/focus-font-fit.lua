local M = {}

function M.start(options)
  local log = hs.logger.new("rex-font-fit")
  local completed = {}
  local targets = {}
  local task
  local pending
  local hotkey
  local filter
  local queued
  local stopped = false
  local observer
  local observed_pid
  local active_window
  local generation = 0
  local drain

  local function focused_window()
    local window = hs.window.focusedWindow()
    local app = window and window:application()
    if app and app:bundleID() == "com.superlogical.rex" then return window end
  end

  local function still_focused(id)
    local window = focused_window()
    return window ~= nil and window:id() == id
  end

  local function launch(request, dry_run, callback, plan)
    local size = targets[request.id]
    if dry_run and request.measure then size = nil end
    if plan then size = plan.target_pt end
    task = hs.task.new(options.rex, function(code, stdout, stderr)
      if stopped then return end
      task = nil
      if code ~= 0 then
        log.w(stderr)
      elseif not dry_run or (request.generation == generation and still_focused(request.id)) then
        local result = hs.json.decode(stdout)
        if type(result) == "table" and type(result.panes) == "table" then
          callback(result)
        else
          log.e("Invalid font-fit result")
        end
      end
      if task == nil and pending == nil then drain() end
    end, {
      "--autostart=false", "--server", options.server, "do", options.script,
      "--args", hs.json.encode({
        current = true, native_window = request.id, dry_run = dry_run,
        active_only = not request.all, size = size, plan = plan,
      }),
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

  drain = function()
    if stopped or task ~= nil or queued == nil then return end
    local request = queued
    queued = nil
    local id = request.id
    if request.generation ~= generation or not still_focused(id) then return end
    request.measure = request.measure or targets[id] == nil
    completed[id] = completed[id] or {}
    local cache = completed[id]
    launch(request, true, function(plan)
      if completed[id] ~= cache then return end
      targets[id] = plan.target_pt
      local remaining = {}
      for _, pane in ipairs(plan.panes) do
        local previous = cache[pane_key(plan, pane)]
        if request.all or previous == nil or previous.target_pt ~= plan.target_pt or
            previous.default_pt ~= plan.display.default_font_pt then
          remaining[#remaining + 1] = pane
        end
      end
      if #remaining == 0 then return end
      plan.panes = remaining
      for _, pane in ipairs(remaining) do cache[pane_key(plan, pane)] = nil end
      launch(request, false, function(result)
        if completed[id] ~= cache then return end
        for _, pane in ipairs(result.panes) do
          cache[pane_key(result, pane)] = {
            target_pt = result.target_pt, default_pt = result.display.default_font_pt,
          }
        end
      end, plan)
    end)
  end

  local function schedule(all, measure, window)
    if stopped then return end
    window = window or focused_window()
    if window == nil then return end
    local id = window:id()
    if queued == nil or queued.id ~= id or queued.generation ~= generation then
      queued = {id = id, generation = generation}
    end
    queued.all = queued.all or all
    queued.measure = queued.measure or measure
    if pending then pending:stop() end
    pending = hs.timer.doAfter(queued.measure and 0.4 or 0.15, function()
      pending = nil
      drain()
    end)
  end

  local function watch_selection(window)
    local app = window:application()
    if observed_pid ~= app:pid() then
      if observer then observer:stop(); observer = nil end
      observed_pid = nil
      local ok, err = pcall(function()
        observer = hs.axuielement.observer.new(app:pid()):callback(function()
          schedule(false, false)
        end)
        observer:addWatcher(hs.axuielement.applicationElement(app), "AXFocusedUIElementChanged")
        observed_pid = app:pid()
      end)
      if not ok then
        if observer then observer:stop(); observer = nil end
        log.e("Could not observe Rex pane selection: " .. tostring(err))
        return
      end
    end
    observer:start()
  end

  local function on_focus(window)
    if hotkey then hotkey:enable() end
    if not options.onFocus then return end
    window = window or focused_window()
    if window == nil or active_window == window:id() then return end
    active_window = window:id()
    generation = generation + 1
    targets[active_window] = nil
    watch_selection(window)
    schedule(false, true, window)
  end

  if options.hotkey then
    hotkey = hs.hotkey.new(options.hotkey.modifiers, options.hotkey.key, function() schedule(true, true) end)
  end
  filter = hs.window.filter.new(function(window)
    local app = window and window:application()
    return app ~= nil and app:bundleID() == "com.superlogical.rex"
  end)
  filter:subscribe(hs.window.filter.windowFocused, on_focus)
  filter:subscribe(hs.window.filter.windowUnfocused, function(window)
    if active_window ~= nil and window:id() ~= active_window then return end
    if hotkey then hotkey:disable() end
    if pending then pending:stop(); pending = nil end
    if observer then observer:stop() end
    active_window = nil
    generation = generation + 1
    queued = nil
  end)
  filter:subscribe(hs.window.filter.windowDestroyed, function(window)
    local id = window:id()
    if id ~= nil then completed[id] = nil; targets[id] = nil end
  end)
  if focused_window() then on_focus() end

  return {
    fit = function() schedule(true, true) end,
    stop = function()
      if stopped then return end
      stopped = true
      queued = nil
      filter:unsubscribeAll()
      if observer then observer:stop() end
      if hotkey then hotkey:delete() end
      if pending then pending:stop() end
      if task then task:terminate() end
    end,
  }
end

return M
