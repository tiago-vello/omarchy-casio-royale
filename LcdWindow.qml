import QtQuick
import "Lcd.js" as Lcd

// The background of one LCD window — "bars" (the two indicator strips
// above the map) or "main" (day/date row and the big digits) — with the
// lines printed on its glass and the shadow of the recess it sits in.
// Placed over the window's bounding box (bx, by, bw, bh in design units).
Canvas {
  id: root

  property real k: 1
  property string shape: "main"
  property bool lit: false
  property real bx: 0
  property real by: 0

  onLitChanged: requestPaint()
  onKChanged: requestPaint()
  onWidthChanged: requestPaint()
  onHeightChanged: requestPaint()

  function trace(ctx) {
    if (shape === "bars") Lcd.traceBars(ctx)
    else Lcd.traceMain(ctx)
  }

  onPaint: {
    var ctx = getContext("2d")
    ctx.reset()
    ctx.save()
    ctx.scale(k, k)
    ctx.translate(-bx, -by)

    if (shape === "bars") {
      // Two separate strips, each curved like a lens: light along the top,
      // shading off toward the bottom edge.
      var strips = [187, 207.5]
      for (var b = 0; b < strips.length; b++) {
        var y = strips[b]
        var sg = ctx.createLinearGradient(0, y, 0, y + 17.5)
        sg.addColorStop(0, lit ? "#cdebdd" : "#aab1a6")
        sg.addColorStop(0.55, lit ? "#c0e2d2" : "#9ea59a")
        sg.addColorStop(1, lit ? "#9ab8aa" : "#7b8278")
        ctx.beginPath(); Lcd.roundRect(ctx, 322, y, 155, 17.5, 8.5)
        ctx.fillStyle = sg; ctx.fill()
      }
      ctx.restore()
      return
    }
    ctx.beginPath(); trace(ctx)
    ctx.fillStyle = Lcd.lcdGradient(ctx, by, by + height / k, lit, false)
    ctx.fill()

    ctx.save()
    ctx.beginPath(); trace(ctx); ctx.clip()
    ctx.strokeStyle = Lcd.INK
    {
      ctx.lineWidth = 1.6
      ctx.beginPath(); ctx.moveTo(302, 391); ctx.lineTo(480, 391); ctx.stroke()
      ctx.lineWidth = 1.9
      ctx.beginPath(); ctx.moveTo(391, 343); ctx.lineTo(391, 391); ctx.stroke()
    }
    // Recess: a soft shadow just inside the rim.
    ctx.strokeStyle = "rgba(0,0,0,0.16)"; ctx.lineWidth = 7
    ctx.beginPath(); trace(ctx); ctx.stroke()
    ctx.strokeStyle = "rgba(0,0,0,0.22)"; ctx.lineWidth = 2.6
    ctx.beginPath(); trace(ctx); ctx.stroke()
    ctx.restore()
    ctx.restore()
  }
}
