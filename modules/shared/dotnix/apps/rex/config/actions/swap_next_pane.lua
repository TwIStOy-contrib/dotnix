local function unwrap(value, err)
  if err ~= nil then error(err, 0) end
  return value
end

rex.action{
  name  = "swap_next_pane",
  title = "Swap with Next Pane",
  run   = function(ctx, args)
    local current = ctx.block_id
    if current == nil then error("No current pane", 0) end

    unwrap(rex.session.focus_block{block_id = current})
    unwrap(rex.session.focus_next_pane{wrap = false})

    local view = unwrap(rex.session.view{})
    local next_block
    for _, window in ipairs(view.windows) do
      if window.window_id == view.active_window_id then
        next_block = window.focused_block_id
        break
      end
    end
    if next_block == nil then error("No active window", 0) end
    if next_block == current then return end

    unwrap(rex.session.swap_blocks{
      block_id       = current,
      other_block_id = next_block,
    })
    unwrap(rex.session.focus_block{block_id = current})
  end,
}
