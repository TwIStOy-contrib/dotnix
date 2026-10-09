# Zen Browser

Enable Zen with `dotnix.desktop.zen.enable`. The shared module at
`modules/shared/dotnix/desktop/zen/default.nix` imports the Zen flake's
`homeModules.beta` and enables `programs.zen-browser`.

The pinned `nixpkgs-unstable` has no Zen package, so Linux uses
`0xc000022070/zen-browser-flake`. Its `nixpkgs` input follows
`nixpkgs-unstable`, and its `home-manager` input follows `home-manager`.
Home Manager `release-25.11` has no native Zen module; the upstream module
uses its `mkFirefoxModule` factory. The reference configuration linked below
uses `homeModules.twilight`; this repository selects beta.

- **Linux:** the upstream module's default package installs Zen through Nix.
- **macOS:** `package = null` leaves installation to Homebrew, while Home
  Manager manages profiles and policies. The module declares
  `homebrew.casks = ["zen"]` only on macOS.

The desktop suit enables Zen. macOS hosts have the desktop suit enabled;
NixOS hosts `poi`, `taihou`, and `cloud-iso` have it disabled. To opt in on
one host, add this inside its `hosts/<host>/modules.nix` configuration:

```nix
dotnix.desktop.zen.enable = true;
```

Homebrew is globally disabled by `homebrew.enable = false` in
`modules/darwin/app.nix`. The cask declaration installs nothing until that
existing setting is deliberately changed to `true`. Enabling Homebrew also
activates management of the other globally declared brews and casks, so
review those declarations before changing it. To install Zen now while
keeping that policy:

```sh
brew install --cask zen
```

The default profile requests Chinese with an English fallback. Customize it in
`hosts/<host>/home.nix`, which is Home Manager scope:

```nix
programs.zen-browser.profiles.default = {
  id = 0;
  isDefault = true;
  settings."intl.locale.requested" = "zh-CN,en-US";
  userChrome = "";
  userContent = "";
};
```

`settings` generates `user.js`; `userChrome` and `userContent` write profile
CSS. For custom CSS, set
`settings."toolkit.legacyUserProfileCustomizations.stylesheets" = true;`
inside the profile configuration.

The profile's `path` defaults to its name, `default`:

| Platform | Configuration root | Profile directory |
| --- | --- | --- |
| Linux | `${config.xdg.configHome}/zen`, usually `~/.config/zen` | `<root>/<path>` |
| macOS | `~/Library/Application Support/Zen` | `<root>/Profiles/<path>` |

To adopt an existing profile, open `about:profiles` and find its **Root
Directory**. Set the following in `hosts/<host>/home.nix`, replacing the
placeholder with that directory's basename; omit the `Profiles/` prefix:

```nix
programs.zen-browser.profiles.default.path = "<existing-profile-basename>";
```

Close Zen and move the existing `<root>/profiles.ini` to a backup filename
before Home Manager activation so it can create the managed file. Preserve
the profile directories and all browser data; do not delete them. Rebuild
and activate the host configuration to apply the changes.

## Spaces in separate files

The shared configuration is organized as follows:

```text
modules/shared/dotnix/desktop/zen/
├── containers.nix      # Managed public containers and their stable IDs
├── default.nix         # Browser installation and the default profile
└── spaces/
    ├── default.nix     # Discovers and merges the space definitions
    └── personal.nix    # Personal workspace
```

`personal.nix` declares the `Personal` space with a home icon, position
`1000`, and a stable UUID. Its `container = 1` selects the Personal container.
It starts without pins. Add personal pins under `personal.pins` in that file
when needed, with `container = 1` for the same login context.

To add another space, create `zen/spaces/work.nix` with a plain attribute set:

```nix
{
  work = {
    id = "7a1e60b2-3c4d-4e5f-8a90-b1c2d3e4f567";
    name = "Work";
    icon = "💼";
    position = 2000;
    pins.docs = {
      id = "027df9a7-c5f4-4a32-98d1-24b7e4c0b011";
      url = "https://nixos.org/manual/nix/stable/";
    };
  };
}
```

Every `.nix` definition discovered in `spaces/`, except its `default.nix`
loader, is merged into `programs.zen-browser.profiles.default.spaces` when
Zen is enabled. No import-list edit is needed. Files contain named spaces
such as `work`; their filenames do not determine space names. One file can
define several spaces. Keep names distinct across files; conflicting values
for the same option fail evaluation instead of silently replacing each other.

Use `uuidgen` once for each new space's version 4 UUID and keep it stable,
without surrounding braces. UUIDs must be unique across spaces and pins.
Choose positions explicitly to control ordering. Add `pins` inside a space
to associate those pins with that workspace automatically; do not set
`workspace` on a space-scoped pin.
These files apply to the default profile on every host with Zen enabled.
For a host-specific space, set
`programs.zen-browser.profiles.default.spaces.<name>` in that host's `home.nix`.

New files must be visible to Git flakes before checking:

```sh
git add -N modules/shared/dotnix/desktop/zen/spaces/work.nix
just check
```

Spaces and pins update `zen-sessions.jsonlz4` after the profile's first launch.
Open the profile once, close Zen, then activate the configuration. The upstream
module skips session updates while Zen is running. `spacesForce` and
`pinsForce` default to `false`, preserving undeclared spaces and pins. Leave
those defaults in place unless you intend Nix to control the entire collection.
Removing a definition file does not delete its existing space with
`spacesForce = false`.

### Spaces, containers, and pins

These are separate concepts within a browser profile:

| Object | Purpose | Relationship |
| --- | --- | --- |
| Space | Organizes a workspace's tabs and pins | Can select a default container with `container = <id>` |
| Container | Isolates cookies and site storage for separate logins | Can be used by tabs and pins across spaces |
| Pin | Keeps a site as a persistent tab | Selects a workspace and, independently, a container |

Declare containers in `programs.zen-browser.profiles.default.containers`;
their IDs are integers. Space and pin IDs are stable UUIDs. A container is
not a folder of websites, and assigning one does not pin a site.

`zen/containers.nix` manages the four public containers from the browser's
default configuration:

| Key | Display name | ID | Icon | Color |
| --- | --- | --- | --- | --- |
| `personal` | Personal | 1 | `fingerprint` | `blue` |
| `work` | Work | 2 | `briefcase` | `orange` |
| `banking` | Banking | 3 | `dollar` | `green` |
| `shopping` | Shopping | 4 | `cart` | `pink` |

Keep these IDs stable to retain the existing login contexts. Home Manager
uses explicit display names in place of the browser's localized `l10nId`
fields and supplies its own internal identities; only public containers
belong in this option.

The pinned Home Manager emits JSON version 5. Zen's Firefox 156 base migrates
it to version 6 without changing container IDs and treats a missing
`siteAssociations` field as empty. The generated metadata and internal IDs
therefore differ from a fresh browser-generated file.

`containersForce = true` makes Home Manager replace `containers.json` with
the declared container configuration on activation, including after Zen
rewrites the managed file. Additional containers created in the browser
must also be declared here to survive the next activation. This controls
the entire file, unlike the space and pin merge options.

Space-scoped pins inherit only `workspace`. In the pinned module,
`personal.pins.<name>.container` defaults to `null`, which generates
`userContextId = 0` (the ordinary browsing context), even if
`personal.container` is set. Set a pin's `container` explicitly when it
needs a particular login context. `isEssential = true` marks a pin as an
Essential; it does not select or create a container.

## Finding configuration options

Zen has several configuration interfaces:

| What you want to configure | Where to look | Where to declare it |
| --- | --- | --- |
| Profiles, spaces, pins, containers, extensions, CSS | [Zen Home Manager option search](https://zen-browser-flake.nshard.com/) | `programs.zen-browser` and `profiles.<name>` |
| Zen/Firefox browser preferences | `about:config` in the installed Zen version | `profiles.<name>.settings."preference.name"` |
| Browser-wide managed policies | [Mozilla enterprise policy reference](https://mozilla.github.io/policy-templates/) | `programs.zen-browser.policies` |

Start with the Zen option search and search for `spaces`, `pins`,
`containers`, or `keyboardShortcuts`. Each entry lists its type, default,
and description. The website follows upstream releases; use the local query
below if an option differs from this repository's pinned version. The
[pinned upstream examples](https://github.com/0xc000022070/zen-browser-flake/tree/90424e159acc21e53ea76780a3ad9cb5acef7cba/examples)
show complete configurations, including the difference between settings
and policies.

### Query the version pinned in this repository

Run this from the repository root to open a Nix REPL with the pinned module's
option definitions. The temporary identity is only used for evaluation; this
does not install anything or create a profile.

```sh
nix repl --impure --expr '
let
  flake = builtins.getFlake (toString ./.);
  hm = flake.inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = import flake.inputs.nixpkgs { system = builtins.currentSystem; };
    modules = [
      flake.inputs.zen-browser.homeModules.beta
      { home = {
          username = "zen-options";
          homeDirectory = "/tmp/zen-options";
          stateVersion = "25.11";
        };
      }
    ];
  };
in { zen = hm.options.programs.zen-browser; }'
```

Then enter these expressions, one at a time:

```nix
builtins.attrNames zen
profile = zen.profiles.type.getSubOptions []
builtins.attrNames profile
space = profile.spaces.type.getSubOptions []
builtins.attrNames space
space.id.description
space.id.type.description
profile.spacesForce.default
pin = space.pins.type.getSubOptions []
builtins.attrNames pin
```

An option's `.description`, `.type.description`, `.default` (when present),
and `.declarations` give its documentation, type, default, and source files.
For nested collections such as profiles, spaces, and pins, use
`.type.getSubOptions []` to inspect their fields. Ignore `_module`, which is
Nix's internal module machinery. Exit with `:q`.

### Browser preferences and policies

In Zen, open `about:config` and search for `zen.` to discover Zen-specific
preferences, or search for a particular Firefox preference. Check its type
and current value, then declare the desired value in a profile:

```nix
programs.zen-browser.profiles.default.settings = {
  "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
};
```

`settings` accepts preference names rather than a fixed list of Nix options;
the Nix option reference therefore cannot enumerate or validate those names.
Search preference names in the [Zen source](https://github.com/zen-browser/desktop)
for implementation details; `about:config` reflects the installed version.
For policies, consult Mozilla's policy reference and
check `about:policies` in Zen after activation to see active policies and errors.

## Policies and updates

Policies are written through `targets.darwin.defaults` under
`app.zen-browser.zen` on macOS, including when `package = null`. On Linux,
policies are delivered through the upstream wrapped package. Upstream
defaults include `DisableAppUpdate = true` and `DisableTelemetry = true`.
Update macOS installations with `brew upgrade --cask zen`; on Linux, run
`nix flake update zen-browser`, then rebuild and activate the host.

Sources:

- [Reference configuration](https://github.com/nicklayb/nixos-config/blob/26.05/modules/applications/zen/default.nix)
- [Upstream Home Manager module](https://github.com/0xc000022070/zen-browser-flake/blob/90424e159acc21e53ea76780a3ad9cb5acef7cba/hm-module/default.nix)
- [Upstream package and policy integration](https://github.com/0xc000022070/zen-browser-flake/blob/90424e159acc21e53ea76780a3ad9cb5acef7cba/hm-module/package.nix)
- [Homebrew Zen cask](https://github.com/Homebrew/homebrew-cask/blob/master/Casks/z/zen.rb)
- [Home Manager 25.11 Firefox module factory](https://github.com/nix-community/home-manager/blob/release-25.11/modules/programs/firefox/mkFirefoxModule.nix)
- [Firefox container JSON migration](https://github.com/mozilla-firefox/firefox/blob/FIREFOX_156_0_1_RELEASE/toolkit/components/contextualidentity/ContextualIdentityService.sys.mjs)
- [Zen Home Manager option search](https://zen-browser-flake.nshard.com/)
- [Space definitions and scoped pins](https://github.com/0xc000022070/zen-browser-flake/blob/90424e159acc21e53ea76780a3ad9cb5acef7cba/hm-module/session/spaces.nix)
- [Pin serialization and container assignment](https://github.com/0xc000022070/zen-browser-flake/blob/90424e159acc21e53ea76780a3ad9cb5acef7cba/hm-module/session/pins.nix)
- [Mozilla enterprise policy reference](https://mozilla.github.io/policy-templates/)
