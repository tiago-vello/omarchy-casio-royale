import QtQuick
import "Seg.js" as Seg
import "Lcd.js" as Lcd

// One LCD digit. The item's box includes the italic lean, so neighbouring
// digits can be laid out by their boxes, as they were measured.
// Unlit segments stay faintly visible, like the ghost of an 8 on the glass.
Canvas {
  id: root

  property string glyph: "8"
  property color onColor: Lcd.SEG
  property color offColor: Lcd.GHOST
  property real slant: 0.145      // lean: x shift per unit of height
  property real stroke: 0.37      // vertical thickness / unslanted width
  property real strokeH: 0.25     // horizontal thickness / unslanted width
  property real gapRatio: 0.02   // gap between segments / height

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
    var lit = Seg.SEVEN_MAP[glyph] !== undefined ? Seg.SEVEN_MAP[glyph] : ""
    var polys = Seg.seven(w, h, stroke * w, strokeH * w, Math.max(0.5, gapRatio * h))
    Seg.paint(ctx, polys, h, slant, 0, function(n) { return lit.indexOf(n) >= 0 }, root.onColor, root.offColor)
  }
}
