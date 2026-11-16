import QtQuick
import "Lcd.js" as Lcd

// Everything on the watch that never changes: the resin case
// with its pusher guards and decorative screws, the black face plate with
// its polished edge, the dial plate with the 60-second ring, and the dark
// rims the LCD windows sit in. Painted once per size.
//
// With `glass: true` it paints the faint sheen of the crystal instead, to
// sit above the LCDs.
Canvas {
  id: root

  property real k: 1
  property real yTop: 0       // design y at the top edge of the canvas
  property real marginX: 10   // room for the pushers left of x = 0
  property bool glass: false
  property string fontFamily: "Nimbus Sans"

  onKChanged: requestPaint()
  onWidthChanged: requestPaint()
  onHeightChanged: requestPaint()

  function paintGlass(ctx) {
    ctx.save()
    ctx.beginPath(); Lcd.tracePlate(ctx); ctx.clip()
    var g = ctx.createLinearGradient(99, 139, 515, 527)
    g.addColorStop(0.00, "rgba(255,255,255,0.00)")
    g.addColorStop(0.16, "rgba(255,255,255,0.045)")
    g.addColorStop(0.32, "rgba(255,255,255,0.00)")
    g.addColorStop(0.82, "rgba(255,255,255,0.00)")
    g.addColorStop(1.00, "rgba(255,255,255,0.03)")
    ctx.fillStyle = g
    ctx.fillRect(90, 130, 440, 410)
    ctx.restore()
  }

  // With no strap fitted, the spring bars show between the lugs.
  function paintSpringBar(ctx, x0, x1, y) {
    var g = ctx.createLinearGradient(0, y - 2, 0, y + 2)
    g.addColorStop(0, "#6c7075"); g.addColorStop(0.35, "#e6e8ea"); g.addColorStop(1, "#5b5f64")
    ctx.fillStyle = g
    ctx.beginPath(); Lcd.roundRect(ctx, x0 - 2, y - 2, x1 - x0 + 4, 4, 2); ctx.fill()
    ctx.fillStyle = "#121213" // the lug holes it sits in
    ctx.fillRect(x0 - 3, y - 3, 3, 6); ctx.fillRect(x1, y - 3, 3, 6)
  }

  function paintScrew(ctx, x, y) {
    ctx.beginPath(); ctx.arc(x, y, 11.5, 0, Math.PI * 2, false)
    ctx.fillStyle = "#242426"; ctx.fill()
    ctx.strokeStyle = "#101011"; ctx.lineWidth = 2.2; ctx.stroke()
    ctx.beginPath(); ctx.arc(x, y, 12.6, Math.PI * 0.05, Math.PI * 0.95, false)
    ctx.strokeStyle = "rgba(255,255,255,0.10)"; ctx.lineWidth = 1; ctx.stroke()
    ctx.beginPath(); ctx.arc(x, y, 6.5, 0, Math.PI * 2, false)
    ctx.strokeStyle = "rgba(0,0,0,0.45)"; ctx.lineWidth = 1.2; ctx.stroke()
    ctx.beginPath(); ctx.arc(x, y, 9.2, Math.PI * 0.55, Math.PI * 0.95, false)
    ctx.strokeStyle = "rgba(255,255,255,0.22)"; ctx.lineWidth = 1.4; ctx.stroke()
  }

  function grain(ctx, seed, count) {
    var rand = Lcd.rng(seed)
    for (var i = 0; i < count; i++) {
      var x = -10 + rand() * 640, y = 15 + rand() * 640
      ctx.fillStyle = rand() < 0.5 ? "rgba(255,255,255,0.055)" : "rgba(0,0,0,0.12)"
      ctx.fillRect(x, y, 0.9, 0.9)
    }
  }

  function paintCase(ctx) {
    // A soft shadow, so the black case still reads against a dark popup.
    ctx.save()
    ctx.shadowColor = "rgba(0,0,0,0.5)"; ctx.shadowBlur = 10 * k; ctx.shadowOffsetY = 3 * k
    ctx.beginPath(); Lcd.traceCase(ctx); ctx.fillStyle = Lcd.CASE; ctx.fill()
    ctx.restore()
    ctx.beginPath(); Lcd.traceCase(ctx)
    var g = ctx.createLinearGradient(0, 18, 0, 652)
    g.addColorStop(0, "#3b3b3e"); g.addColorStop(0.5, "#323234"); g.addColorStop(1, "#2a2a2c")
    ctx.fillStyle = g
    ctx.fill()

    ctx.save()
    ctx.beginPath(); Lcd.traceCase(ctx); ctx.clip()
    // The guards' outer faces and the side walls, a shade darker.
    ctx.fillStyle = "rgba(0,0,0,0.18)"
    ctx.fillRect(-10, 150, 63, 370); ctx.fillRect(562, 150, 60, 370)
    // The slope from the groove down to the plate, lit from the top left.
    ctx.beginPath(); Lcd.traceGroove(ctx)
    var s = ctx.createLinearGradient(53, 95, 562, 569)
    s.addColorStop(0, "#48484c"); s.addColorStop(0.45, "#353538"); s.addColorStop(1, "#2a2a2d")
    ctx.fillStyle = s; ctx.fill()
    grain(ctx, 1200, 4200)
    // The groove itself, with the ridge outside it catching light.
    ctx.beginPath(); Lcd.traceGroove(ctx)
    ctx.strokeStyle = "#0c0c0d"; ctx.lineWidth = 2.4; ctx.stroke()
    ctx.save(); ctx.translate(-1.4, -1.4)
    ctx.beginPath(); Lcd.traceGroove(ctx)
    ctx.strokeStyle = "rgba(255,255,255,0.10)"; ctx.lineWidth = 1; ctx.stroke()
    ctx.restore()
    ctx.restore()

    // Moulded outer edge.
    ctx.beginPath(); Lcd.traceCase(ctx)
    ctx.strokeStyle = "rgba(255,255,255,0.10)"; ctx.lineWidth = 1.2; ctx.stroke()

    paintScrew(ctx, 172, 64); paintScrew(ctx, 442, 64)
    paintScrew(ctx, 170, 602); paintScrew(ctx, 445, 602)
  }

  function paintPlate(ctx) {
    ctx.beginPath(); Lcd.tracePlate(ctx)
    var g = ctx.createLinearGradient(0, 139, 0, 527)
    g.addColorStop(0, "#262628"); g.addColorStop(1, "#1d1d1f")
    ctx.fillStyle = g; ctx.fill()
    // Polished edge: bright on the top-left and bottom-right chamfers.
    var edge = ctx.createLinearGradient(99, 139, 515, 527)
    edge.addColorStop(0.00, "#9ea3a8"); edge.addColorStop(0.10, "#eef1f4")
    edge.addColorStop(0.20, "#80868c"); edge.addColorStop(0.45, "#3d4043")
    edge.addColorStop(0.75, "#5d6166"); edge.addColorStop(0.90, "#e3e7ea")
    edge.addColorStop(1.00, "#7c8187")
    ctx.beginPath(); Lcd.tracePlate(ctx)
    ctx.strokeStyle = edge; ctx.lineWidth = 1.6; ctx.stroke()
  }

  function paintDialPlate(ctx) {
    var cx = Lcd.DIAL_CX, cy = Lcd.DIAL_CY
    ctx.beginPath(); Lcd.roundRect(ctx, 129, 177, 172, 175, 15)
    ctx.fillStyle = "#19191b"; ctx.fill()
    ctx.strokeStyle = "rgba(255,255,255,0.07)"; ctx.lineWidth = 1.2; ctx.stroke()

    var holes = [[139, 195], [291, 195], [139, 335], [291, 335]]
    for (var h = 0; h < holes.length; h++) {
      ctx.beginPath(); ctx.arc(holes[h][0], holes[h][1], 6, 0, Math.PI * 2, false)
      ctx.fillStyle = "#101011"; ctx.fill()
      ctx.strokeStyle = "rgba(255,255,255,0.07)"; ctx.lineWidth = 1; ctx.stroke()
      ctx.beginPath(); ctx.arc(holes[h][0], holes[h][1], 5, Math.PI * 0.1, Math.PI * 0.9, false)
      ctx.strokeStyle = "rgba(255,255,255,0.10)"; ctx.lineWidth = 0.9; ctx.stroke()
    }

    ctx.beginPath(); ctx.arc(cx, cy, 87.5, 0, Math.PI * 2, false)
    ctx.fillStyle = "#141415"; ctx.fill()
    ctx.strokeStyle = "rgba(255,255,255,0.05)"; ctx.lineWidth = 1; ctx.stroke()

    // 60 second marks: squares at the quarters, bars at the fives, dashes between.
    ctx.fillStyle = "#efefec"
    for (var i = 0; i < 60; i++) {
      ctx.save()
      ctx.translate(cx, cy)
      ctx.rotate(i * Math.PI / 30)
      if (i % 15 === 0) ctx.fillRect(-3.7, -75.2, 7.4, 7.4)
      else if (i % 5 === 0) ctx.fillRect(-2.1, -75.6, 4.2, 8.4)
      else ctx.fillRect(-1.15, -73.6, 2.3, 4.6)
      ctx.restore()
    }

    // Numerals 60, 05 ... 55 around the ring, turned to stay readable.
    ctx.font = "bold 14px \"" + root.fontFamily + "\""
    ctx.textAlign = "center"
    ctx.textBaseline = "middle"
    for (var n = 0; n < 12; n++) {
      var deg = n * 30
      var label = n === 0 ? "60" : (n * 5 < 10 ? "0" + n * 5 : String(n * 5))
      var a = (deg - 90) * Math.PI / 180
      var rot = deg <= 90 || deg >= 270 ? deg : deg - 180
      ctx.save()
      ctx.translate(cx + Math.cos(a) * 82.5, cy + Math.sin(a) * 82.5)
      ctx.rotate(rot * Math.PI / 180)
      ctx.scale(1.06, 1)
      ctx.lineWidth = 0.7; ctx.strokeStyle = "#efefec"
      ctx.strokeText(label, 0, 0.7)
      ctx.fillText(label, 0, 0.7)
      ctx.restore()
    }

    // The dial LCD's rim.
    ctx.beginPath(); ctx.arc(cx, cy, Lcd.DIAL_R + 2.2, 0, Math.PI * 2, false)
    ctx.fillStyle = Lcd.RIM; ctx.fill()
  }

  function paintRims(ctx) {
    ctx.fillStyle = Lcd.RIM; ctx.strokeStyle = Lcd.RIM; ctx.lineWidth = 5
    ctx.beginPath(); Lcd.traceBars(ctx); ctx.fill(); ctx.stroke()
    ctx.beginPath(); Lcd.traceMap(ctx); ctx.fill(); ctx.stroke()
    ctx.beginPath(); Lcd.traceMain(ctx); ctx.fill(); ctx.stroke()
  }

  onPaint: {
    var ctx = getContext("2d")
    ctx.reset()
    ctx.save()
    ctx.scale(k, k)
    ctx.translate(marginX, -yTop)
    if (glass) {
      paintGlass(ctx)
    } else {
      paintSpringBar(ctx, 146, 469, 26)
      paintSpringBar(ctx, 177, 438, 643)
      paintCase(ctx)
      paintPlate(ctx)
      paintDialPlate(ctx)
      paintRims(ctx)
    }
    ctx.restore()
  }
}
