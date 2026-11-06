# Display-based font fitting

These Lua/JS assets are shared by both Rex deployments: taihou's system server
(`modules/nixos/dotnix/services/rex.nix`) and the macOS app's local bundled
server (`modules/darwin/dotnix/apps/rex.nix`). `default.nix` in this directory
renders the Lua and exposes every file keyed by its path under `~/.config/rex/`,
so only the platform paths differ; installing the results stays in the platform
modules. `init.lua` holds just the keybindings and pulls the actions in with
`require("actions")`, which resolves to `actions/init.lua`. `display-info.js`
and `focus-font-fit.lua` are macOS-only, since font fitting needs that Mac's
display geometry and Hammerspoon.

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

Hammerspoon measures the display on native-window focus, remembers the target
font size for that window, and fits only its active pane. Session, tab, and pane
selection changes reuse that size and fit the newly active pane. These changes
are observed through macOS Accessibility focus notifications, including remote
sessions; no background polling is used.

**Cmd+Alt+Shift+F** refreshes the target and fits all visible panes in the current
tab. Hammerspoon must be installed, running, and have Accessibility access. Configure
`dotnix.apps.rex.fontFitOnFocus` and `dotnix.apps.rex.fontFitHotkey`; use `false`
and `null`, respectively, to disable automatic fitting and the shortcut. Events
are debounced and runs are serialized; a selection change during a fit is handled
afterward. Successful fits are remembered per pane, so returning to one at the
same target skips font actions. Use the shortcut after manually changing font
sizes, which Rex does not expose for reading. Cached targets and successful fits
last until Hammerspoon reloads or the native window closes.

The trigger enters through the local server with `current=true`. It reads the
app-owned `Workspace.lastFocusedSession` preference and resolves remote server
IDs through the local host list. It stops when native-window or session focus
changes. To preview this path while Rex is frontmost:

```sh
rex-font-fit current=true dry_run=true
```

Automatic fitting never moves pane focus. The tab shortcut temporarily moves
focus, then restores it unless the user has moved elsewhere. Explicit runs without
`current=true` activate Rex and select the requested session. A remote server action needs `display` metadata from a
local dry run, passed via `--args`, including the target `client_id`, `width_pt`,
`height_pt`, and `default_font_pt`.
