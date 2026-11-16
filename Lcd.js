.pragma library

// Shared geometry and palette for the AE-1200 face.
//
// Every shape is in "design units": the coordinates of a 620 x 680 crop of
// a straight-on product photo of the AE-1200WH-1A, measured off the photo.
// The watch drawing scales them by `k`. Keeping the numbers in photo units
// is what makes them checkable: each one can be put back over the photo.

// ---- Palette (sampled from the photo, lifted to daylight brightness)
var CASE = "#2c2c2e"
var CASE_HI = "#3b3b3e"
var CASE_LO = "#202022"
var PLATE = "#1e1e20"
var RIM = "#0a0a0b"
var PRINT_WHITE = "#f2f2ef"
var PRINT_MINT = "#c3d4ce"
var PRINT_RED = "#d33a30"
var INK = "#121417"            // lines printed on the LCD glass
var SEG = "#141b25"            // a dark LCD segment: near-black with a navy cast
var GHOST = "#06141b25"         // an unlit segment, barely there (QML #AARRGGBB)
var GHOST_CSS = "rgba(20,27,37,0.022)" // the same, for canvas strings
var LAND = "rgba(28,33,30,0.66)"   // the map's printed continents

function lcdGradient(ctx, y0, y1, lit, dial) {
  var g = ctx.createLinearGradient(0, y0, 0, y1)
  if (lit) {
    // The LED sits low in the case: brighter toward the bottom.
    g.addColorStop(0, dial ? "#bfe4d2" : "#c1e3d5")
    g.addColorStop(1, dial ? "#dcf8e9" : "#ddf7ec")
  } else {
    g.addColorStop(0, dial ? "#a5b1a4" : "#b2b9ae")
    g.addColorStop(1, dial ? "#95a295" : "#a1a89d")
  }
  return g
}

// Polygon with rounded corners. `pts` is [[x,y],...]; `r` a radius or one per corner.
function roundPoly(ctx, pts, r) {
  var n = pts.length
  function rad(i) { return typeof r === "number" ? r : r[i] }
  var last = pts[n - 1], first = pts[0]
  ctx.moveTo((last[0] + first[0]) / 2, (last[1] + first[1]) / 2)
  for (var i = 0; i < n; i++) {
    var p = pts[i], q = pts[(i + 1) % n]
    if (rad(i) > 0) ctx.arcTo(p[0], p[1], q[0], q[1], rad(i))
    else ctx.lineTo(p[0], p[1])
  }
  ctx.closePath()
}

function roundRect(ctx, x, y, w, h, r) {
  roundPoly(ctx, [[x, y], [x + w, y], [x + w, y + h], [x, y + h]], r)
}

// ---- The windows, as paths
function traceBars(ctx) { roundRect(ctx, 322, 187, 155, 38, 9) }
function traceMap(ctx) { roundRect(ctx, 322, 242, 155, 85, 8) }
// The main LCD: the big digit row plus the day/date row that steps up on
// the right, with a slanted left edge between them.
var MAIN_PTS = [[133, 390], [270, 390], [306, 345], [477, 345], [477, 488], [133, 488]]
var MAIN_R = [7, 7, 6, 8, 10, 10]
function traceMain(ctx) { roundPoly(ctx, MAIN_PTS, MAIN_R) }
var DIAL_CX = 215, DIAL_CY = 265, DIAL_R = 65.5
function traceDial(ctx) {
  ctx.moveTo(DIAL_CX + DIAL_R, DIAL_CY)
  ctx.arc(DIAL_CX, DIAL_CY, DIAL_R, 0, Math.PI * 2, false)
  ctx.closePath()
}

// The black face plate: an octagon with steep chamfers, ringed by a thin
// polished edge.
var PLATE_PTS = [[150, 139], [464, 139], [515, 200], [515, 470], [467, 527], [148, 527], [99, 470], [99, 201]]
function tracePlate(ctx) { roundPoly(ctx, PLATE_PTS, 4) }

// The groove where the case's flat top meets the slope down to the plate.
var GROOVE_PTS = [[127, 95], [488, 95], [562, 170], [562, 500], [500, 569], [117, 569], [53, 500], [53, 172]]
function traceGroove(ctx) { roundPoly(ctx, GROOVE_PTS, 12) }

// The resin case silhouette, scanned off the photo row by row: lugs with
// the strap entering between them, the long top/bottom chamfers, and the
// hexagonal guards around the pushers.
var CASE_PTS = [
  [128, 18], [146, 18], [146, 33], [469, 33], [469, 18], [485, 18],
  [494, 40], [502, 60], [516, 90], [529, 110], [547, 130], [570, 160], [580, 180],
  [597, 191], [597, 280], [583, 292], [583, 380],
  [603, 395], [603, 474], [577, 489],
  [573, 500], [553, 530], [527, 560], [511, 590], [499, 620], [487, 652],
  [438, 652], [438, 634], [177, 634], [177, 652], [130, 652],
  [118, 620], [106, 590], [89, 560], [62, 530], [40, 500],
  [42, 490], [12, 474], [14, 395], [31, 380],
  [31, 292], [17, 280], [17, 191], [39, 180],
  [45, 160], [69, 130], [86, 110], [98, 90], [111, 60], [118, 40]
]
var CASE_R = 3
function traceCase(ctx) { roundPoly(ctx, CASE_PTS, CASE_R) }

// Pusher centres (design units): A upper left, B upper right, C lower left, D lower right.
// x is the outer end; pushers are 61 tall and stand 22 proud of the guards.
var PUSHERS = {
  A: { x: -7, y: 200, left: true },
  B: { x: 591, y: 200, left: false },
  C: { x: -7, y: 413, left: true },
  D: { x: 591, y: 413, left: false }
}
var PUSHER_W = 30, PUSHER_H = 61

// Deterministic noise, so the resin grain is the same on every repaint.
function rng(seed) {
  var s = seed >>> 0
  return function() {
    s = (s * 1664525 + 1013904223) >>> 0
    return s / 4294967296
  }
}

// ---- Casio city codes by UTC offset (from the module 3299 city table)
var CITY = [
  [-11, "PPG"], [-10, "HNL"], [-9, "ANC"], [-8, "LAX"], [-7, "DEN"], [-6, "CHI"],
  [-5, "NYC"], [-4, "SCL"], [-3.5, "YYT"], [-3, "RIO"], [-2, "FEN"], [-1, "RAI"],
  [0, "LON"], [1, "PAR"], [2, "ATH"], [3, "MOW"], [3.5, "THR"], [4, "DXB"],
  [4.5, "KBL"], [5, "KHI"], [5.5, "DEL"], [5.75, "KTM"], [6, "DAC"], [6.5, "RGN"],
  [7, "BKK"], [8, "HKG"], [9, "TYO"], [9.5, "ADL"], [10, "SYD"], [11, "NOU"], [12, "WLG"]
]
function cityFor(offsetHours) {
  for (var i = 0; i < CITY.length; i++) if (CITY[i][0] === offsetHours) return CITY[i][1]
  return "UTC"
}

var DAYS = ["SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT"]
