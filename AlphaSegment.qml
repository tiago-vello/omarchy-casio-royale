import QtQuick
import "Seg.js" as Seg
import "Lcd.js" as Lcd

// One character of a text window (STW, SPL, TUE, RIO).
Canvas {
  id: root

  property string glyph: " "
  property color onColor: Lcd.SEG
  property color offColor: Lcd.GHOST
  property real slant: 0.145
  property real stroke: 0.30      // vertical thickness / unslanted width
  property real strokeH: 0.22     // horizontal thickness / unslanted width
  property real gapRatio: 0.024   // gap between segments / height

  onGlyphChanged: requestPaint()
  onOnColorChanged: requestPaint()
  onWidthChanged: requestPaint()
  onHeightChanged: requestPaint()

  onPaint: {
    var ctx = getContext("2d")
    ctx.reset()
    var h = height
    var w = width - slant * h
    if (w <= 0 || h <= 0) return
    var lit = Seg.ALPHA_MAP[glyph] || []
    var polys = Seg.alpha(w, h, stroke * w, strokeH * w, Math.max(0.4, gapRatio * h))
    Seg.paint(ctx, polys, h, slant, 0, function(n) { return lit.indexOf(n) >= 0 }, root.onColor, root.offColor)
  }
}
