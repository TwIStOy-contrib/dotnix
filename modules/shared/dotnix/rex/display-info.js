function selectWindow(windows, windowId) {
  if (windowId !== undefined) {
    windows = windows.filter(function (window) { return window.id === windowId; });
  }
  if (windows.length !== 1) {
    throw new Error("Select one visible Rex window with native_window=<id>; candidates: " +
      windows.map(function (window) { return window.id; }).join(", "));
  }
  return windows[0];
}

function selectDisplay(screens, window) {
  var best;
  var bestArea = 0;
  screens.forEach(function (screen) {
    var bounds = screen.bounds;
    var width = Math.max(0, Math.min(window.x + window.width, bounds.x + bounds.width) -
      Math.max(window.x, bounds.x));
    var height = Math.max(0, Math.min(window.y + window.height, bounds.y + bounds.height) -
      Math.max(window.y, bounds.y));
    if (width * height > bestArea) {
      best = screen;
      bestArea = width * height;
    }
  });
  if (!best) throw new Error("The Rex window does not overlap an active display");
  return best;
}

function run(argv) {
  ObjC.import("AppKit");
  ObjC.import("CoreGraphics");

  var apps = $.NSRunningApplication.runningApplicationsWithBundleIdentifier("com.superlogical.rex");
  if (Number(apps.count) !== 1) throw new Error("Expected one running Rex application");
  var pid = Number(apps.objectAtIndex(0).processIdentifier);
  var windowId = argv.length ? Number(argv[0]) : undefined;
  if (windowId !== undefined && (!Number.isInteger(windowId) || windowId <= 0)) {
    throw new Error("native_window must be a positive window ID");
  }
  if (argv[1] === "activate") {
    apps.objectAtIndex(0).activateWithOptions($.NSApplicationActivateIgnoringOtherApps);
    $.NSThread.sleepForTimeInterval(0.3);
  }

  var list = ObjC.deepUnwrap(ObjC.castRefToObject($.CGWindowListCopyWindowInfo(
    $.kCGWindowListOptionOnScreenOnly | $.kCGWindowListExcludeDesktopElements,
    $.kCGNullWindowID
  )));
  var windows = list.filter(function (window) {
    return window.kCGWindowOwnerPID === pid && window.kCGWindowLayer === 0 &&
      window.kCGWindowBounds.Width > 0 && window.kCGWindowBounds.Height > 0;
  }).map(function (window) {
    var bounds = window.kCGWindowBounds;
    return {id: window.kCGWindowNumber, x: bounds.X, y: bounds.Y, width: bounds.Width, height: bounds.Height};
  });
  var window = selectWindow(windows, windowId);
  if (argv[1] === "activate" && windows[0].id !== window.id) {
    throw new Error("Bring the selected native Rex window to the front before running font_fit");
  }

  var screens = $.NSScreen.screens;
  var primaryHeight = Number(screens.objectAtIndex(0).frame.size.height);
  var displays = [];
  for (var i = 0; i < Number(screens.count); i++) {
    var screen = screens.objectAtIndex(i);
    var frame = screen.frame;
    displays.push({
      display_id: Number(ObjC.unwrap(screen.deviceDescription.objectForKey("NSScreenNumber"))),
      name: ObjC.unwrap(screen.localizedName),
      width_pt: Number(frame.size.width),
      height_pt: Number(frame.size.height),
      scale: Number(screen.backingScaleFactor),
      // CoreGraphics window coordinates start at the primary screen's top left.
      bounds: {
        x: Number(frame.origin.x),
        y: primaryHeight - Number(frame.origin.y) - Number(frame.size.height),
        width: Number(frame.size.width),
        height: Number(frame.size.height),
      },
    });
  }
  var display = selectDisplay(displays, window);
  delete display.bounds;
  display.window_id = window.id;
  display.front_window_id = windows[0].id;
  display.pid = pid;
  display.frontmost = Number($.NSWorkspace.sharedWorkspace.frontmostApplication.processIdentifier) === pid;
  display.host_name = ObjC.unwrap($.NSProcessInfo.processInfo.hostName);
  var prefs = $.NSUserDefaults.alloc.initWithSuiteName("com.superlogical.rex");
  var focusedSession = prefs.dataForKey("Workspace.lastFocusedSession");
  if (focusedSession && !focusedSession.isNil()) {
    display.focused_session = JSON.parse(ObjC.unwrap(
      $.NSString.alloc.initWithDataEncoding(focusedSession, $.NSUTF8StringEncoding)
    ));
  }
  display.default_font_pt = Number(prefs.doubleForKey("Workspace.terminalFontPointSize"));
  if (display.default_font_pt <= 0) {
    throw new Error("Set Rex's default font size in Settings before running font_fit");
  }
  return JSON.stringify(display);
}
