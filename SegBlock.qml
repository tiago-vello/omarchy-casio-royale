import QtQuick
import "Lcd.js" as Lcd

// A single slanted LCD block: a colon dot or the date dash.
Canvas {
  id: root

  property bool lit: true
  property color onColor: Lcd.SEG
  property color offColor: Lcd.GHOST
  property real slant: 0.145

  onLitChanged: requestPaint()
  onOnColorChanged: requestPaint()
  onWidthChanged: requestPaint()
  onHeightChanged: requestPaint()

  onPaint: {
    var ctx = getContext("2d")
    ctx.reset()
    var h = height, s = slant * h, w = width - s
    ctx.beginPath()
    ctx.moveTo(s, 0); ctx.lineTo(s + w, 0); ctx.lineTo(w, h); ctx.lineTo(0, h)
    ctx.closePath()
    ctx.fillStyle = lit ? onColor : offColor
    ctx.fill()
  }
}
