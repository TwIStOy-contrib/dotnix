{
  lib,
  stdenv,
  stdenvNoCC,
  fetchurl,
  buildFHSEnv,
}:
# terminal-browser ships as a closed-source bundle: an Ubuntu-built Electron
# runtime (`electron/pixel`), the CLI (`cli/dist/main.js`), the agent-browser
# helper and the React UI (`browser/dist`). Its launcher resolves everything
# from its own location, so the tarball layout has to stay intact and the
# Electron binary cannot be swapped for nixpkgs'.
#
# The bundle runs unpatched inside an FHS environment: Chromium's sandbox and
# the dlopen'd GL/vulkan/libsecret loaders expect an FHS root, and autoPatchelf
# plus LD_LIBRARY_PATH would not give them one. The library list below comes
# from the `NEEDED` entries of `electron/pixel` plus the libraries Chromium
# dlopens (libGL/libEGL, libnotify, libpulse, libsecret, wayland).
#
# Upstream publishes no release feed: version, asset names and sha256s are all
# taken from the `PLATFORMS` table at the top of
# https://terminal-browser.sh/install
let
  version = "0.15.2";
  channel = "stable";

  asset =
    if stdenv.hostPlatform.isAarch64
    then "arm64"
    else "x64";

  hashes = {
    x64 = "sha256-loGpTbes4QbM6GvxTcs/y6ekBOXmYOcL+c63Ks42sUY=";
    arm64 = "sha256-XbCZwMMDeTbysiz6n5qSk2fMJ1TZamMcLpG4hvZ9Dyo=";
  };

  bundle = stdenvNoCC.mkDerivation {
    pname = "terminal-browser-bundle";
    inherit version;

    src = fetchurl {
      url = "https://terminal-browser.sh/install/dl/${channel}/v${version}/terminal-browser-linux-${asset}.tar.gz";
      hash =
        hashes.${asset}
          or (throw "terminal-browser: no hash registered for ${asset}");
    };

    unpackPhase = ''
      mkdir -p $out
      tar -xzf $src -C $out --strip-components 1
    '';

    dontBuild = true;
    # strip/patchShebangs would rewrite a closed-source bundle whose scripts
    # are executed verbatim; nothing needs patching inside the FHS root.
    dontFixup = true;

    installPhase = ":";
  };
in
  buildFHSEnv {
    pname = "terminal-browser";
    inherit version;

    # The bundle's own launcher sets TERMINAL_BROWSER_DIST_ROOT and
    # ELECTRON_RUN_AS_NODE, then re-execs `electron/pixel` as node.
    runScript = "${bundle}/bin/terminal-browser";

    # A single browser daemon serves every pane in a terminal tab and outlives
    # the command that spawned it; bwrap's default --die-with-parent would tear
    # the sandbox (and the daemon) down with that first shell.
    dieWithParent = false;

    targetPkgs = pkgs:
      with pkgs; [
        alsa-lib
        at-spi2-atk
        at-spi2-core
        cairo
        cups
        dbus
        expat
        fontconfig
        freetype
        gdk-pixbuf
        glib
        gtk3
        harfbuzz
        icu
        libdrm
        libgbm
        libGL
        libnotify
        libpulseaudio
        libsecret
        libx11
        libxcb
        libxcomposite
        libxdamage
        libxext
        libxfixes
        libxkbcommon
        libxrandr
        libxshmfence
        nspr
        nss
        pango
        systemd
        vulkan-loader
        wayland
        xdg-utils
      ];

    meta = {
      description = "Chromium inside the terminal, with an agent-drivable CLI";
      homepage = "https://github.com/zenbu-labs/terminal-browser";
      # Closed source, redistributed as a prebuilt bundle only.
      license = lib.licenses.unfree;
      sourceProvenance = with lib.sourceTypes; [binaryNativeCode];
      mainProgram = "terminal-browser";
      platforms = lib.platforms.linux;
    };
  }
