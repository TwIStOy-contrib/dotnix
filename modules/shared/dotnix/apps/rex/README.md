# Display-based font fitting

These Lua/JS assets are shared by both Rex deployments: taihou's system server
(`modules/nixos/dotnix/services/rex.nix`) and the macOS app's local bundled
server (`modules/darwin/dotnix/apps/rex`). Runtime files live together in
`config/`. `default.nix` exposes every file keyed by its path under
`~/.config/rex/`; the files contain no host-specific paths. `init.lua` holds
just the keybindings and pulls the actions in with `require("actions")`, which
resolves to `actions/init.lua`. That file imports each action from its own Lua
file. `display-info.js` is macOS-only, since font fitting needs that Mac's
display geometry and Hammerspoon.

Scripts that run inside Hammerspoon rather than the rex server
(`focus-font-fit.lua`, `rex-nvim-im.lua`) live with hammerspoon instead: the
darwin hammerspoon module installs them under `~/.hammerspoon/`, and the rex
module's options dofile them from there.

On a machine not managed by dotnix, install the same files from a configured
Mac and reload the server there:

```sh
rex-sync dev.work.local
```

The command uploads the config and helper scripts, runs `rex config check`,
and reloads the system server when `/run/rex/server.sock` exists.

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

Hammerspoon must be installed, running, and have Accessibility access. Set
`dotnix.apps.rex.fontFitOnFocus` to `false` to disable automatic fitting. Events
are debounced and runs are serialized; a selection change during a fit is handled
afterward. Successful fits are remembered per pane, so returning to one at the
same target skips font actions. Cached targets and successful fits last until
Hammerspoon reloads or the native window closes.

The trigger enters through the local server with `current=true`. It reads the
app-owned `Workspace.lastFocusedSession` preference and resolves remote server
IDs through the local host list. It stops when native-window or session focus
changes. To preview this path while Rex is frontmost:

```sh
rex-font-fit current=true dry_run=true
```

Automatic fitting never moves pane focus. Explicit runs without `current=true`
activate Rex and select the requested session. A remote server action needs `display` metadata from a
local dry run, passed via `--args`, including the target `client_id`, `width_pt`,
`height_pt`, and `default_font_pt`.

# nvim mode → input-method switching

`nvim-mode-listen.lua` and `rex-nvim-im.lua` are the macOS client side of a
pipeline that switches the macOS input method with the focused Rex nvim
pane's mode. Neovim (dotvim's `config/rex.nix`) publishes its mode as an
OSC 7501 `nvim/mode` program-status record; the listener (`rex do
nvim-mode-listen.lua --all`) mirrors per-block modes and focus into the
`rexNvim` global in Hammerspoon and calls the `rexNvimOn*` hooks;
`rex-nvim-im.lua` (an hs-side script, installed under `~/.hammerspoon/` by
the hammerspoon module) implements the switch: leaving insert captures the
active input method and forces the machine's ASCII layout (discovered from
the enabled keyboard layouts), entering insert restores it unless the source
was changed manually in between.

The listener runs as an `hs.task` supervised by `rexNvimSup` (restarted on
exit while the Rex app is up), so no launchd agent is involved; the
dotnix-generated hammerspoon init.lua dofiles `rex-nvim-im.lua` and starts
the supervisor. Disable with `dotnix.apps.rex.nvimImSwitch = false`. Both
files are macOS-only and are not part of `rex-sync`.
