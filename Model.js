.pragma library

// Pure stopwatch logic, kept out of QML so it can be tested with node.
//
// The AE-1200 (module 3299) stopwatch, the classic Casio scheme:
//   D (START/STOP): start, stop, resume.
//   A (SPLIT/RESET): while running, freeze a split (the watch keeps
//   counting); press again to release it. While stopped, reset.
// The 1st/2nd place sequence falls out of that: D start, A split (1st),
// D stop (2nd), A release (shows 2nd), A reset.

var CAPACITY_MS = 24 * 60 * 60 * 1000 // counts up to 23:59'59.99", then wraps

function initial() {
  return { running: false, startedAt: 0, accumulated: 0, split: -1 }
}

function sanitize(s) {
  var out = initial()
  if (!s || typeof s !== "object") return out
  out.running = s.running === true
  out.startedAt = isFinite(s.startedAt) ? Number(s.startedAt) : 0
  out.accumulated = isFinite(s.accumulated) && s.accumulated >= 0 ? Number(s.accumulated) : 0
  out.split = isFinite(s.split) && s.split >= 0 ? Number(s.split) : -1
  if (out.running && out.startedAt <= 0) out.running = false
  return out
}

function elapsed(s, now) {
  var ms = s.accumulated + (s.running ? Math.max(0, now - s.startedAt) : 0)
  return ms % CAPACITY_MS
}

// What the LCD shows: the frozen split while one is held, else the count.
function shown(s, now) {
  return s.split >= 0 ? s.split : elapsed(s, now)
}

function startStop(s, now) {
  var n = sanitize(s)
  if (n.running) {
    n.accumulated = elapsed(n, now)
    n.running = false
    n.startedAt = 0
  } else {
    n.running = true
    n.startedAt = now
  }
  return n
}

function splitReset(s, now) {
  var n = sanitize(s)
  if (n.split >= 0) n.split = -1
  else if (n.running) n.split = elapsed(n, now)
  else n = initial()
  return n
}

function isZero(s) {
  return !s.running && s.accumulated === 0 && s.split < 0
}

function pad(n, width) {
  var t = String(Math.floor(n))
  while (t.length < width) t = "0" + t
  return t
}

// { h, m, s, cs } of a duration in milliseconds.
function parts(ms) {
  ms = Math.max(0, Math.floor(ms))
  return {
    h: Math.floor(ms / 3600000),
    m: Math.floor(ms / 60000) % 60,
    s: Math.floor(ms / 1000) % 60,
    cs: Math.floor(ms / 10) % 100
  }
}

// Compact bar label: 1'23" under an hour, 1:02'03" past it.
function barLabel(ms) {
  var p = parts(ms)
  if (p.h > 0) return p.h + ":" + pad(p.m, 2) + "'" + pad(p.s, 2) + "\""
  return p.m + "'" + pad(p.s, 2) + "\""
}
