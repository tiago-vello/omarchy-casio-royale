import QtQuick
import "Lcd.js" as Lcd
import "MapData.js" as MapData

// The world-map window: continents printed on the glass, the dotted grid,
// and the home time zone darkened as a band of LCD segments over the land.
Canvas {
  id: root

  property real k: 1
  property bool lit: false
  property real utcOffset: 0   // hours; the zone shown dark

  readonly property real x0: 322
  readonly property real y0: 242
  readonly property real ww: 155
  readonly property real wh: 85

  onLitChanged: requestPaint()
  onUtcOffsetChanged: requestPaint()
  onKChanged: requestPaint()
  onWidthChanged: requestPaint()

  function traceLand(ctx) {
    for (var p = 0; p < MapData.land.length; p++) {
      var ring = MapData.land[p]
      ctx.moveTo(x0 + ring[0] * ww, y0 + ring[1] * wh)
      for (var i = 2; i < ring.length; i += 2) ctx.lineTo(x0 + ring[i] * ww, y0 + ring[i + 1] * wh)
      ctx.closePath()
    }
  }

  function dots(ctx, xa, ya, xb, yb) {
    var len = Math.max(Math.abs(xb - xa), Math.abs(yb - ya))
    for (var d = 1.2; d < len; d += 2.7) {
      var t = d / len
      ctx.fillRect(xa + (xb - xa) * t - 0.55, ya + (yb - ya) * t - 0.55, 1.1, 1.1)
    }
  }

  onPaint: {
    var ctx = getContext("2d")
    ctx.reset()
    ctx.save()
    ctx.scale(k, k)
    ctx.translate(-x0, -y0)

    ctx.beginPath(); Lcd.traceMap(ctx)
    ctx.fillStyle = Lcd.lcdGradient(ctx, y0, y0 + wh, lit, false)
    ctx.fill()
    ctx.save()
    ctx.beginPath(); Lcd.traceMap(ctx); ctx.clip()

    // The LCD map is coarser than the coastline: fatten it a little.
    ctx.beginPath(); traceLand(ctx)
    ctx.fillStyle = Lcd.LAND; ctx.fill()
    ctx.lineJoin = "round"; ctx.lineWidth = 1.9; ctx.strokeStyle = Lcd.LAND; ctx.stroke()

    // Home zone: a 15-degree band centred on the UTC offset, wrapped onto the map.
    var west = utcOffset * 15 - 7.5
    var fx = ((west - MapData.L0) % 360 + 360) % 360 / 360
    var bandW = 15 / 360 * ww
    ctx.save()
    ctx.beginPath()
    ctx.rect(x0 + fx * ww, y0, bandW, wh)
    ctx.rect(x0 + (fx - 1) * ww, y0, bandW, wh) // the part that wraps past the right edge
    ctx.clip()
    ctx.beginPath(); traceLand(ctx)
    ctx.fillStyle = Lcd.SEG; ctx.fill(); ctx.lineWidth = 1.9; ctx.strokeStyle = Lcd.SEG; ctx.stroke()
    ctx.restore()

    // The land is cut into LCD segments along the grid lines: a thin clear
    // gap under each dotted line, the dots printed over it.
    var vx = [0.134, 0.409, 0.645, 0.887]
    var hy = [0.25, 0.449, 0.837]
    ctx.save()
    ctx.beginPath(); traceLand(ctx); ctx.lineWidth = 1.3; ctx.clip()
    ctx.strokeStyle = Lcd.lcdGradient(ctx, y0, y0 + wh, lit, false); ctx.lineWidth = 1.7
    for (var gv = 0; gv < vx.length; gv++) { ctx.beginPath(); ctx.moveTo(x0 + vx[gv] * ww, y0); ctx.lineTo(x0 + vx[gv] * ww, y0 + wh); ctx.stroke() }
    for (var gh = 0; gh < hy.length; gh++) { ctx.beginPath(); ctx.moveTo(x0, y0 + hy[gh] * wh); ctx.lineTo(x0 + ww, y0 + hy[gh] * wh); ctx.stroke() }
    ctx.restore()

    ctx.fillStyle = "rgba(18,20,23,0.85)"
    for (var v = 0; v < vx.length; v++) dots(ctx, x0 + vx[v] * ww, y0, x0 + vx[v] * ww, y0 + wh)
    for (var h = 0; h < hy.length; h++) dots(ctx, x0, y0 + hy[h] * wh, x0 + ww, y0 + hy[h] * wh)
    ctx.strokeStyle = Lcd.INK; ctx.lineWidth = 1.2
    ctx.beginPath(); ctx.moveTo(x0, y0 + 0.663 * wh); ctx.lineTo(x0 + ww, y0 + 0.663 * wh); ctx.stroke()

    ctx.strokeStyle = "rgba(0,0,0,0.16)"; ctx.lineWidth = 7
    ctx.beginPath(); Lcd.traceMap(ctx); ctx.stroke()
    ctx.strokeStyle = "rgba(0,0,0,0.22)"; ctx.lineWidth = 2.6
    ctx.beginPath(); Lcd.traceMap(ctx); ctx.stroke()
    ctx.restore()
    ctx.restore()
  }
}
