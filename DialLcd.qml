import QtQuick
import "Lcd.js" as Lcd

// The round "digital dial": a crosshair and a circle printed on the glass,
// a black hub, and 120 radial segments that act as hands. Inner segments
// (hub to circle) are the hour hand; the minute hand lights both an inner
// and an outer one; the second hand is a single outer segment. In every
// mode it shows the current home time, as on the watch.
Canvas {
  id: root

  property real k: 1
  property bool lit: false
  property int hours: 10
  property int minutes: 10
  property int seconds: 35

  readonly property real box: Lcd.DIAL_R + 1.5

  onLitChanged: requestPaint()
  onHoursChanged: requestPaint()
  onMinutesChanged: requestPaint()
  onSecondsChanged: requestPaint()
  onKChanged: requestPaint()
  onWidthChanged: requestPaint()

  function wedge(ctx, angle, r0, r1, w0, w1) {
    var a = (angle - 90) * Math.PI / 180
    var ca = Math.cos(a), sa = Math.sin(a)
    var nx = -sa, ny = ca
    ctx.beginPath()
    ctx.moveTo(ca * r0 + nx * w0 / 2, sa * r0 + ny * w0 / 2)
    ctx.lineTo(ca * r1 + nx * w1 / 2, sa * r1 + ny * w1 / 2)
    ctx.lineTo(ca * r1 - nx * w1 / 2, sa * r1 - ny * w1 / 2)
    ctx.lineTo(ca * r0 - nx * w0 / 2, sa * r0 - ny * w0 / 2)
    ctx.closePath()
    ctx.fill()
  }

  onPaint: {
    var ctx = getContext("2d")
    ctx.reset()
    ctx.save()
    ctx.scale(k, k)
    ctx.translate(box, box) // origin at the dial centre
    var R = Lcd.DIAL_R

    ctx.beginPath(); ctx.arc(0, 0, R, 0, Math.PI * 2, false)
    ctx.fillStyle = Lcd.lcdGradient(ctx, -R, R, lit, true)
    ctx.fill()
    ctx.save()
    ctx.beginPath(); ctx.arc(0, 0, R, 0, Math.PI * 2, false); ctx.clip()

    var hourPos = (hours % 12) * 5 + Math.floor(minutes / 12)
    for (var i = 0; i < 60; i++) {
      ctx.fillStyle = (i === hourPos || i === minutes) ? Lcd.SEG : Lcd.GHOST_CSS
      wedge(ctx, i * 6, 27, 51, 3.0, 3.8)
      ctx.fillStyle = (i === minutes || i === seconds) ? Lcd.SEG : Lcd.GHOST_CSS
      wedge(ctx, i * 6, 56, 64, 3.6, 4.0)
    }

    // Printed crosshair and circle.
    ctx.strokeStyle = Lcd.INK; ctx.lineWidth = 1.7
    ctx.beginPath(); ctx.moveTo(-R, 0); ctx.lineTo(R, 0); ctx.stroke()
    ctx.beginPath(); ctx.moveTo(0, -R); ctx.lineTo(0, R); ctx.stroke()
    ctx.beginPath(); ctx.arc(0, 0, 53.2, 0, Math.PI * 2, false); ctx.stroke()

    // The glass is set deep: darker toward the rim.
    var v = ctx.createRadialGradient(0, 0, 30, 0, 0, R)
    v.addColorStop(0, "rgba(0,0,0,0)"); v.addColorStop(0.75, "rgba(0,0,0,0.04)"); v.addColorStop(1, "rgba(0,0,0,0.20)")
    ctx.fillStyle = v
    ctx.fillRect(-R, -R, 2 * R, 2 * R)
    ctx.strokeStyle = "rgba(0,0,0,0.18)"; ctx.lineWidth = 7
    ctx.beginPath(); ctx.arc(0, 0, R, 0, Math.PI * 2, false); ctx.stroke()
    ctx.restore()

    // Hub.
    ctx.beginPath(); ctx.arc(0, 0, 20.6, 0, Math.PI * 2, false)
    ctx.fillStyle = "#0e1012"; ctx.fill()
    ctx.restore()
  }
}
