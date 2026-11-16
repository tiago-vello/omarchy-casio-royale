pragma Singleton

import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Io
import qs.Commons
import "Model.js" as Model

// The one watch every monitor's widget looks at.
//
// A bar widget is instantiated once per monitor, so the state lives here.
// It is written to ~/.local/state as wall-clock timestamps, so a running
// stopwatch keeps running across a shell restart or a plugin reload, the
// way the watch keeps counting while nobody looks at it.
//
// The four pushers follow module 3299: A ADJUST, B LIGHT, C MODE,
// D SEARCH. In Stopwatch mode D starts and stops and A splits and clears;
// in Timekeeping A flashes the home city code. Every press beeps unless the
// tone has been muted by holding C, which also changes mode, as on the watch.
Singleton {
  id: root

  property var state: Model.initial()
  property real now: Date.now()

  property string mode: "stopwatch"   // "stopwatch" | "time"
  property bool muted: false
  property bool lit: false            // the LED, on for 1.5 s after B
  property bool cityFlash: false      // city code shown for a second after A in Timekeeping
  property string pressedKey: ""      // a pusher drawn pressed for a moment
  // Watch faces currently on screen. While one is open the clock ticks at
  // LCD speed; otherwise once a second is plenty for the bar label.
  property int viewers: 0

  readonly property bool running: state.running
  readonly property bool splitHeld: state.split >= 0
  readonly property bool zero: Model.isZero(state)
  readonly property real shownMs: Model.shown(state, now)
  readonly property var shownParts: Model.parts(shownMs)
  readonly property string barLabel: Model.barLabel(shownMs)

  readonly property string statePath: Quickshell.env("HOME") + "/.local/state/omarchy-ae1200-stopwatch.json"

  function tick() { root.now = Date.now() }

  function save() {
    stateFile.setText(JSON.stringify({ stopwatch: root.state, mode: root.mode, muted: root.muted }) + "\n")
  }

  function apply(next) {
    root.now = Date.now()
    root.state = next
    save()
  }

  function beep() {
    if (!root.muted) tone.play()
  }

  function flash(key) {
    root.pressedKey = key
    flashTimer.restart()
  }

  // ---- Stopwatch operations, for the bar and IPC: they act on the
  //      stopwatch whatever mode the face is showing.
  function startStop() {
    beep(); flash("D")
    apply(Model.startStop(root.state, Date.now()))
  }

  function splitReset() {
    beep(); flash("A")
    apply(Model.splitReset(root.state, Date.now()))
  }

  // ---- The pushers, read the way the watch reads them in its current mode.
  function press(key) {
    beep(); flash(key)
    if (key === "B") {
      root.lit = true
      lightTimer.restart()
    } else if (key === "C") {
      root.mode = root.mode === "stopwatch" ? "time" : "stopwatch"
      root.cityFlash = false
      save()
    } else if (root.mode === "stopwatch") {
      if (key === "A") apply(Model.splitReset(root.state, Date.now()))
      else if (key === "D") apply(Model.startStop(root.state, Date.now()))
    } else if (key === "A") {
      root.cityFlash = true
      cityTimer.restart()
    }
  }

  // Holding C for two seconds toggles the button operation tone.
  function hold(key) {
    if (key !== "C") return
    root.muted = !root.muted
    save()
    beep()
  }

  SoundEffect {
    id: tone
    source: Qt.resolvedUrl("beep.wav")
    volume: 0.7
  }

  Timer {
    // 1/100 s cannot be shown honestly at less than the display's frame
    // rate; ~30 fps reads as the blur of hundredths a real LCD shows.
    interval: root.viewers > 0 ? 33 : 1000
    repeat: true
    running: root.viewers > 0 || root.running
    triggeredOnStart: true
    onTriggered: root.tick()
  }

  Timer { id: lightTimer; interval: 1500; onTriggered: root.lit = false }
  Timer { id: cityTimer; interval: 1000; onTriggered: root.cityFlash = false }
  Timer { id: flashTimer; interval: 130; onTriggered: root.pressedKey = "" }

  FileView {
    id: stateFile
    path: root.statePath
    printErrors: false
    watchChanges: false
    onLoaded: {
      var parsed = null
      // Bounded and validated: this is a file on disk, not our memory.
      var raw = String(text() || "")
      if (raw.length < 4096) {
        try { parsed = JSON.parse(raw) } catch (e) { parsed = null }
      }
      if (parsed && typeof parsed === "object" && parsed.stopwatch !== undefined) {
        root.state = Model.sanitize(parsed.stopwatch)
        root.mode = parsed.mode === "time" ? "time" : "stopwatch"
        root.muted = parsed.muted === true
      } else {
        root.state = Model.sanitize(parsed) // the first version stored the stopwatch alone
      }
      root.tick()
    }
  }

  ShellIpc {
    target: "tiago.ae1200.stopwatch"

    function startStop(): void { root.startStop() }
    function splitReset(): void { root.splitReset() }
    function press(key: string): void {
      var k = String(key).toUpperCase()
      if (k === "A" || k === "B" || k === "C" || k === "D") root.press(k)
    }
    function light(): void { root.press("B") }
    function mode(): void { root.press("C") }
    function mute(): void { root.hold("C") }
    function status(): string {
      var p = root.shownParts
      return (root.running ? "running" : "stopped") + (root.splitHeld ? " split " : " ")
        + p.h + ":" + Model.pad(p.m, 2) + "'" + Model.pad(p.s, 2) + "\"" + Model.pad(p.cs, 2)
    }
  }
}
