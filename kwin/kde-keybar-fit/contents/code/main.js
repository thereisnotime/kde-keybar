// kde-keybar fit: KWin already shrinks the active window so it ends at the top of the
// on-screen keyboard, but a strip floating on top of the keyboard (kde-keybar) is
// invisible to that logic and covers the bottom of the window. This script finds such
// a strip and trims the active window a bit further, so it ends at the strip's top.
//
// When the keyboard hides, KWin restores the window to the geometry it saved before
// the keyboard appeared, which also undoes this trim.
//
// Maximized windows: KWin re-applies a maximized window's height on every resize, so
// trimming one directly makes the two fight (the window resizes in a loop). While the
// keyboard is up, such a window is switched to horizontal-only maximize, and full
// maximize is restored when the keyboard goes away. As a last guard, a window that keeps
// growing back is left alone: MAX_ATTEMPTS trims inside LOOP_WINDOW_MS means KWin or the
// app is fighting us, so that window is skipped until the keyboard hides. Trims spread
// out over time (rotation, switching windows, resizing) are fine.

var EDGE_TOLERANCE = 12; // px: how close the strip must sit to the keyboard's top edge
var MIN_HEIGHT = 120; // never squash a window below this
var MAX_ATTEMPTS = 3; // trims inside LOOP_WINDOW_MS that count as a fight
var LOOP_WINDOW_MS = 2000;
var MAXIMIZE_FULL = 3; // KWin MaximizeMode: 1 vertical, 2 horizontal, 3 full

// internalId -> { window, times, gaveUp, wasMaximized } for the current keyboard session
var touched = {};

function log(msg) {
    if (readConfig("debug", false)) {
        console.warn("kde-keybar-fit: " + msg);
    }
}

function keyboard() {
    var list = workspace.windowList();
    for (var i = 0; i < list.length; i++) {
        var w = list[i];
        if (w.inputMethod && !w.hidden && w.frameGeometry.height > 0) {
            return w;
        }
    }
    return null;
}

// A strip "belongs" to the keyboard if it is a non-taskbar, non-maximizable surface
// whose bottom edge touches the keyboard's top edge and that overlaps it horizontally.
function stripTop(kb) {
    var k = kb.frameGeometry;
    var top = k.y;
    var list = workspace.windowList();
    for (var i = 0; i < list.length; i++) {
        var w = list[i];
        if (w === kb || w.inputMethod || w.dock || w.hidden || w.maximizable || !w.skipTaskbar) {
            continue;
        }
        var g = w.frameGeometry;
        var bottom = g.y + g.height;
        var overlapsX = g.x < k.x + k.width && g.x + g.width > k.x;
        if (overlapsX && Math.abs(bottom - k.y) <= EDGE_TOLERANCE && g.y < top) {
            top = g.y;
        }
    }
    return top < k.y ? top : null;
}

var busy = false;

var keyboardWasUp = true; // so the repair pass also runs once when the script starts

// Keyboard gone: give back full maximize to windows we demoted, forget the session.
// Runs once per keyboard-hide (not on every window event, so it can't loop).
function endSession() {
    if (!keyboardWasUp) {
        return;
    }
    keyboardWasUp = false;
    for (var id in touched) {
        var t = touched[id];
        if (t.wasMaximized && !t.window.deleted) {
            log("re-maximizing " + t.window.resourceClass);
            t.window.setMaximize(true, true);
        }
    }
    touched = {};
    repairMaximized();
}

// Safety net: with no keyboard up, a window KWin reports as fully maximized should fill
// its maximize area. If it does not (KWin lost its pre-keyboard geometry, e.g. after a
// rotation or an input-method restart), cycle the maximize state to re-lay it out.
function repairMaximized() {
    var list = workspace.windowList();
    for (var i = 0; i < list.length; i++) {
        var w = list[i];
        if (!w.normalWindow || w.minimized || w.maximizeMode !== MAXIMIZE_FULL) {
            continue;
        }
        var a = workspace.clientArea(KWin.MaximizeArea, w);
        var g = w.frameGeometry;
        if (Math.abs(g.height - a.height) > 2 || Math.abs(g.width - a.width) > 2) {
            log("repairing " + w.resourceClass + " " + Math.round(g.height) + " -> " + Math.round(a.height));
            w.setMaximize(false, false);
            w.setMaximize(true, true);
        }
    }
}

// Tell kde-keybar the real keyboard height so it sits flush on top of it (Maliit's
// height changes with its suggestion row and with rotation; the bar can only guess).
var BAR_SERVICE = "io.github.thereisnotime.KdeKeybar";
var lastReported = -1;

function reportHeight(kb) {
    var h = kb.frameGeometry.height;
    if (Math.abs(h - lastReported) < 1) {
        return;
    }
    lastReported = h;
    log("keyboard height " + h);
    // Nudge integral values off the integer so they marshal as a D-Bus double.
    callDBus(BAR_SERVICE, "/io/github/thereisnotime/KdeKeybar", BAR_SERVICE, "SetKeyboardHeight",
             h % 1 === 0 ? h + 0.001 : h);
}

function fit() {
    var kb = keyboard();
    if (!kb) {
        endSession();
        lastReported = -1;
        return;
    }
    keyboardWasUp = true;
    reportHeight(kb);
    var w = workspace.activeWindow;
    if (busy || !w || !w.normalWindow || w.fullScreen || !w.resizeable || w.inputMethod) {
        return;
    }
    var limit = stripTop(kb);
    if (limit === null) {
        return;
    }
    var g = w.frameGeometry;
    var bottom = g.y + g.height;
    if (bottom <= limit + 0.5 || g.y >= limit) {
        return;
    }
    var height = Math.floor(limit - g.y);
    if (height < MIN_HEIGHT) {
        return;
    }
    var id = String(w.internalId);
    var t = touched[id] || (touched[id] = { window: w, times: [], gaveUp: false, wasMaximized: false });
    if (t.gaveUp) {
        return;
    }
    var now = Date.now();
    t.times = t.times.filter(function (ts) { return now - ts < LOOP_WINDOW_MS; });
    if (t.times.length >= MAX_ATTEMPTS) {
        t.gaveUp = true; // it keeps growing back right away; stop instead of fighting
        log("giving up on " + w.resourceClass + " until the keyboard hides");
        return;
    }
    t.times.push(now);
    log(w.resourceClass + " " + g.height + " -> " + height + " (strip top " + limit + ", recent trims " + t.times.length + ")");
    busy = true;
    if (w.maximizeMode === MAXIMIZE_FULL) {
        t.wasMaximized = true;
        w.setMaximize(false, true); // keep full width, free the height
        g = w.frameGeometry;
    }
    w.frameGeometry = { x: g.x, y: g.y, width: g.width, height: Math.floor(limit - g.y) };
    busy = false;
}

// KWin moves windows for the keyboard in its own handlers; run after those settle.
var timer = new QTimer();
timer.singleShot = true;
timer.interval = 60;
timer.timeout.connect(fit);

function schedule() {
    timer.start();
}

function watch(w) {
    w.frameGeometryChanged.connect(schedule);
}

workspace.windowList().forEach(watch);
workspace.windowAdded.connect(function (w) {
    watch(w);
    schedule();
});
workspace.windowRemoved.connect(schedule);
workspace.windowActivated.connect(schedule);
schedule();
