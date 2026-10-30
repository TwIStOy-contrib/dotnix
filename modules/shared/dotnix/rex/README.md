# Display-based font fitting

Run on the Mac hosting the Rex app. Font size follows the display's full logical
width, independently of splits and app-window size. All terminal panes in the
active tab are adjusted, including floating layers; zoom limits this to one pane.

```sh
rex-font-fit dry_run=true
rex-font-fit
rex-font-fit -S taihou session=session:... client=LCNDWWYVTFMFX
```

`size=<pt>` overrides the display tiers. Remote client labels must match the Mac's
hostname. With multiple native windows, pass `native_window=<macOS-window-id>`
and bring that window to the front. Enable Remote Control for the target server
and set Rex's default font size in Settings.

Hammerspoon fits on native-window focus and binds **Cmd+Alt+Shift+F** while Rex is
focused. It must be installed, running, and have Accessibility access. Configure
`dotnix.apps.rex.fontFitOnFocus` and `dotnix.apps.rex.fontFitHotkey`; use `false`
and `null`, respectively, to disable them. Focus events are debounced and runs are
serialized. Successful fits are remembered per pane, so returning to a fitted
tab skips its panes and adding a split only fits the new pane. A focus event during
a running fit is retried afterward. The shortcut forces all visible panes to fit;
use it after manually changing font sizes, which Rex does not expose for reading.
The cache lasts until Hammerspoon reloads or the native window closes.

The trigger enters through the local server with `current=true`. It reads the
app-owned `Workspace.lastFocusedSession` preference and resolves remote server
IDs through the local host list. It stops when native-window or session focus
changes. To preview this path while Rex is frontmost:

```sh
rex-font-fit current=true dry_run=true
```

Font actions temporarily move pane focus, then restore it unless the user has
moved elsewhere. Explicit runs without `current=true` activate Rex and select
the requested session. A remote server action needs `display` metadata from a
local dry run, passed via `--args`, including the target `client_id`, `width_pt`,
`height_pt`, and `default_font_pt`.
