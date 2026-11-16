.pragma library

// Segment outlines for the LCD, unslanted, in a w x h cell with stroke
// thickness t and gap g. Corners where two segments meet are split on the
// diagonal, the middle bar has pointed ends, and the verticals are notched
// to make room for it — the Casio module look, measured off the AE-1200's
// digits (stroke about 30% of the digit's width).

// tv: thickness of the verticals, th: of the horizontals. On the AE-1200
// the verticals are markedly heavier (about 37% of the digit's width
// against 25%), which is most of what makes its digits look like Casio's.
function seven(w, h, tv, th, g) {
  var m = h / 2
  return {
    a: [[g, 0], [w - g, 0], [w - tv - g, th], [tv + g, th]],
    b: [[w, g], [w, m - g / 2], [w - tv, m - th / 2 - g / 2], [w - tv, th + g]],
    c: [[w, m + g / 2], [w, h - g], [w - tv, h - th - g], [w - tv, m + th / 2 + g / 2]],
    d: [[g, h], [tv + g, h - th], [w - tv - g, h - th], [w - g, h]],
    e: [[0, m + g / 2], [tv, m + th / 2 + g / 2], [tv, h - th - g], [0, h - g]],
    f: [[0, g], [tv, th + g], [tv, m - th / 2 - g / 2], [0, m - g / 2]],
    g: [[g, m], [g + tv, m - th / 2], [w - g - tv, m - th / 2], [w - g, m], [w - g - tv, m + th / 2], [g + tv, m + th / 2]]
  }
}

var SEVEN_MAP = {
  "0": "abcdef", "1": "bc", "2": "abged", "3": "abgcd", "4": "fgbc",
  "5": "afgcd", "6": "afgedc", "7": "abc", "8": "abcdefg", "9": "abcdfg",
  "-": "g", " ": "", "t": "defg", "A": "abcefg", "E": "adefg", "P": "abefg",
  "S": "afgcd", "L": "def", "r": "eg", "n": "ceg", "o": "cdeg"
}

function diag(x0, y0, x1, y1, width) {
  var dx = x1 - x0, dy = y1 - y0
  var len = Math.sqrt(dx * dx + dy * dy) || 1
  var nx = -dy / len * width / 2, ny = dx / len * width / 2
  return [[x0 + nx, y0 + ny], [x1 + nx, y1 + ny], [x1 - nx, y1 - ny], [x0 - nx, y0 - ny]]
}

// The 3-character text windows (STW, SPL, TUE, RIO): the seven segments
// with the middle bar split in two, a centre stroke above and below it, and
// four thin diagonals for the few letters that need one.
function alpha(w, h, tv, th, g) {
  var s = seven(w, h, tv, th, g)
  var m = h / 2, c = w / 2, hc = tv / 2, ht = th / 2
  var dw = th * 1.15
  return {
    a: s.a, b: s.b, c: s.c, d: s.d, e: s.e, f: s.f,
    g1: [[g, m], [g + tv, m - ht], [c - hc - g, m - ht], [c - g, m], [c - hc - g, m + ht], [g + tv, m + ht]],
    g2: [[c + g, m], [c + hc + g, m - ht], [w - g - tv, m - ht], [w - g, m], [w - g - tv, m + ht], [c + hc + g, m + ht]],
    i: [[c - hc, th + g], [c + hc, th + g], [c + hc, m - ht - g], [c, m - g], [c - hc, m - ht - g]],
    l: [[c - hc, m + ht + g], [c, m + g], [c + hc, m + ht + g], [c + hc, h - th - g], [c - hc, h - th - g]],
    h: diag(tv + g + dw / 2, th + g + dw / 2, c - hc - g, m - ht - g, dw),
    j: diag(w - tv - g - dw / 2, th + g + dw / 2, c + hc + g, m - ht - g, dw),
    k: diag(c + hc + g, m + ht + g, w - tv - g - dw / 2, h - th - g - dw / 2, dw),
    m: diag(c - hc - g, m + ht + g, tv + g + dw / 2, h - th - g - dw / 2, dw)
  }
}

var ALPHA_MAP = {
  "A": ["a", "b", "c", "e", "f", "g1", "g2"],
  "B": ["a", "b", "c", "d", "g2", "i", "l"],
  "C": ["a", "d", "e", "f"],
  "D": ["a", "b", "c", "d", "i", "l"],
  "E": ["a", "d", "e", "f", "g1"],
  "F": ["a", "e", "f", "g1"],
  "G": ["a", "c", "d", "e", "f", "g2"],
  "H": ["b", "c", "e", "f", "g1", "g2"],
  "I": ["a", "d", "i", "l"],
  "K": ["e", "f", "g1", "j", "k"],
  "L": ["d", "e", "f"],
  "M": ["a", "b", "c", "e", "f", "i"],
  "N": ["b", "c", "e", "f", "h", "k"],
  "O": ["a", "b", "c", "d", "e", "f"],
  "P": ["a", "b", "e", "f", "g1", "g2"],
  "R": ["a", "b", "e", "f", "g1", "g2", "k"],
  "S": ["a", "c", "d", "f", "g1", "g2"],
  "T": ["a", "i", "l"],
  "U": ["b", "c", "d", "e", "f"],
  "W": ["b", "c", "d", "e", "f", "l"],
  "X": ["h", "j", "k", "m"],
  "Y": ["b", "f", "g1", "g2", "l"],
  "0": ["a", "b", "c", "d", "e", "f"],
  "1": ["b", "c"],
  "2": ["a", "b", "d", "e", "g1", "g2"],
  "3": ["a", "b", "c", "d", "g1", "g2"],
  "-": ["g1", "g2"],
  " ": []
}

// Paint `polys` (name -> points) sheared by `slant` (x shift per unit of
// height, leaning right), lit where `on(name)` says so.
function paint(ctx, polys, h, slant, offsetX, on, onColor, offColor) {
  for (var name in polys) {
    var pts = polys[name]
    ctx.beginPath()
    for (var i = 0; i < pts.length; i++) {
      var x = offsetX + pts[i][0] + slant * (h - pts[i][1])
      if (i === 0) ctx.moveTo(x, pts[i][1])
      else ctx.lineTo(x, pts[i][1])
    }
    ctx.closePath()
    ctx.fillStyle = on(name) ? onColor : offColor
    ctx.fill()
  }
}
