import QtQuick
import "Lcd.js" as Lcd

// The AE-1200WH-1A, drawn from measurements of a straight-on photo
// (see Lcd.js for the coordinate system).
//
// The face is a pure view: what it shows comes in through properties, and
// presses on its four pushers go out through signals. It knows nothing
// about the shell, so it can also be rendered on its own for comparison
// against the photo.
Item {
  id: root

  // ---- Inputs
  property real k: 0.72                 // pixels per design unit
  property string mode: "stopwatch"     // "stopwatch" | "time"
  property var sw: ({ h: 0, m: 0, s: 0, cs: 0 })
  property bool splitHeld: false
  property real now: Date.now()
  property bool lit: false
  property bool muted: false
  property bool cityFlash: false        // A in timekeeping: city code + T-1
  property string pressedKey: ""        // pusher shown pressed (keyboard)
  property string fontFamily: "Nimbus Sans"

  signal pressed(string key)
  signal held(string key)

  // The head only, no strap: design y from yTop to yBottom (the case runs
  // 18..652; the rest is room for its shadow).
  readonly property real yTop: 6
  readonly property real yBottom: 666
  implicitWidth: (620 + 2 * marginX) * k
  implicitHeight: (yBottom - yTop) * k

  // ---- What the LCD shows
  readonly property date clock: new Date(now)
  readonly property bool timeMode: mode === "time"
  readonly property real utcOffset: -clock.getTimezoneOffset() / 60

  function digit(n, i) { return String(Math.floor(n / Math.pow(10, i)) % 10) }
  function blankTens(n) { return n >= 10 ? digit(n, 1) : " " }

  readonly property int mainH: timeMode ? clock.getHours() : sw.h
  readonly property int mainM: timeMode ? clock.getMinutes() : sw.m
  readonly property int mainS: timeMode ? clock.getSeconds() : sw.s
  readonly property var mainDigits: [blankTens(mainH), digit(mainH, 0), digit(mainM, 1), digit(mainM, 0)]
  readonly property var secDigits: [digit(mainS, 1), digit(mainS, 0)]

  readonly property string textLeft: timeMode
    ? (cityFlash ? Lcd.cityFor(utcOffset) : Lcd.DAYS[clock.getDay()])
    : (splitHeld ? "SPL" : "STW")
  // Date row: [m10, m1, dash, d10, d1]
  readonly property var textRight: {
    if (timeMode && cityFlash) return [" ", "t", true, " ", "1"]
    if (timeMode) {
      var mo = clock.getMonth() + 1, d = clock.getDate()
      return [blankTens(mo), digit(mo, 0), true, blankTens(d), digit(d, 0)]
    }
    return [" ", " ", false, digit(sw.cs, 1), digit(sw.cs, 0)]
  }

  readonly property real marginX: 16    // room for the pushers (they reach x = -7) and the shadow
  function u(v) { return v * k }                    // a length
  function px(v) { return (v + marginX) * k }       // an x position
  function py(v) { return (v - yTop) * k }          // a y position

  // ---- Pushers (drawn first: their inner ends disappear under the case)
  component Pusher: Item {
    id: pusher
    property string key: "A"
    readonly property var spec: Lcd.PUSHERS[key]
    readonly property bool down: area.pressed || root.pressedKey === key
    x: root.px(spec.x + (down ? (spec.left ? 4 : -4) : 0))
    y: root.py(spec.y)
    width: root.u(Lcd.PUSHER_W)
    height: root.u(Lcd.PUSHER_H)
    Behavior on x { NumberAnimation { duration: 50 } }

    // Two chrome blocks with a dark groove between them, as on the watch.
    Rectangle {
      width: parent.width; height: root.u(23); radius: root.u(3)
      gradient: Gradient {
        GradientStop { position: 0.00; color: "#8c9095" }
        GradientStop { position: 0.10; color: "#f6f7f8" }
        GradientStop { position: 0.45; color: "#d3d6d9" }
        GradientStop { position: 0.85; color: "#9a9ea3" }
        GradientStop { position: 1.00; color: "#5c6065" }
      }
    }
    Rectangle {
      y: root.u(23); width: parent.width; height: root.u(8)
      gradient: Gradient {
        GradientStop { position: 0.0; color: "#1f2124" }
        GradientStop { position: 0.6; color: "#3a3d41" }
        GradientStop { position: 1.0; color: "#8a8e93" }
      }
    }
    Rectangle {
      y: root.u(31); width: parent.width; height: root.u(30); radius: root.u(3)
      gradient: Gradient {
        GradientStop { position: 0.00; color: "#eceef0" }
        GradientStop { position: 0.30; color: "#fbfbfc" }
        GradientStop { position: 0.65; color: "#b4b8bd" }
        GradientStop { position: 0.92; color: "#6b6f74" }
        GradientStop { position: 1.00; color: "#45484c" }
      }
    }
    // The rounded outer end.
    Rectangle {
      x: pusher.spec.left ? 0 : parent.width - width
      width: root.u(3.2); height: parent.height; radius: root.u(1.6)
      color: "#55595e"; opacity: 0.55
    }
    MouseArea {
      id: area
      anchors.fill: parent
      anchors.margins: -root.u(4)
      cursorShape: Qt.PointingHandCursor
      pressAndHoldInterval: 2000
      onPressed: root.pressed(pusher.key)
      onPressAndHold: root.held(pusher.key)
    }
  }

  Pusher { key: "A" }
  Pusher { key: "B" }
  Pusher { key: "C" }
  Pusher { key: "D" }

  CaseArt {
    anchors.fill: parent
    k: root.k
    yTop: root.yTop
    marginX: root.marginX
    fontFamily: root.fontFamily
  }

  // ---- LCD windows
  DialLcd {
    k: root.k
    lit: root.lit
    x: root.px(Lcd.DIAL_CX - box); y: root.py(Lcd.DIAL_CY - box)
    width: root.u(box * 2); height: width
    hours: root.clock.getHours()
    minutes: root.clock.getMinutes()
    seconds: root.clock.getSeconds()
  }

  LcdWindow {
    k: root.k; lit: root.lit; shape: "bars"
    bx: 319; by: 184
    x: root.px(bx); y: root.py(by); width: root.u(161); height: root.u(44)
  }

  // MUTE: shown in the indicator strip while the button tone is off.
  Text {
    x: root.px(441); y: root.py(189.5)
    width: root.u(32); height: root.u(14)
    textFormat: Text.PlainText
    text: "MUTE"
    font.family: root.fontFamily
    font.bold: true
    font.pixelSize: Math.max(1, root.u(10.5))
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    color: Lcd.SEG
    visible: root.muted
    transform: Shear { xFactor: -0.12 }
  }

  MapLcd {
    k: root.k; lit: root.lit
    utcOffset: root.utcOffset
    x: root.px(322); y: root.py(242); width: root.u(155); height: root.u(85)
  }

  LcdWindow {
    k: root.k; lit: root.lit; shape: "main"
    bx: 130; by: 342
    x: root.px(bx); y: root.py(by); width: root.u(350); height: root.u(149)
  }

  // Day / mode text: three characters.
  Repeater {
    model: 3
    AlphaSegment {
      required property int index
      x: root.px(322.5 + index * 21); y: root.py(351)
      width: root.u(19.5); height: root.u(29)
      glyph: root.textLeft.charAt(index)
    }
  }

  // Date / 1/100 second row.
  Repeater {
    model: [{ i: 0, x: 387.5 }, { i: 1, x: 407.5 }, { i: 3, x: 435.5 }, { i: 4, x: 456.5 }]
    SevenSegment {
      required property var modelData
      x: root.px(modelData.x); y: root.py(351)
      width: root.u(16.5); height: root.u(29)
      stroke: 0.36
      strokeH: 0.25
      gapRatio: 0.022
      glyph: root.textRight[modelData.i]
    }
  }
  SegBlock {
    x: root.px(426); y: root.py(368.5)
    width: root.u(8.5); height: root.u(2.8)
    lit: root.textRight[2] === true
  }

  // Big digits: hours, minutes (H:MM), then the seconds.
  Repeater {
    model: [171, 219, 289, 341]
    SevenSegment {
      required property int index
      required property int modelData
      x: root.px(modelData); y: root.py(399.5)
      width: root.u(46); height: root.u(78.5)
      glyph: root.mainDigits[index]
    }
  }
  SegBlock { x: root.px(274); y: root.py(419); width: root.u(10.5); height: root.u(10) }
  SegBlock { x: root.px(269.6); y: root.py(449.5); width: root.u(10.5); height: root.u(9.6) }

  Repeater {
    model: [396, 433]
    SevenSegment {
      required property int index
      required property int modelData
      x: root.px(modelData); y: root.py(420.5)
      width: root.u(34); height: root.u(57.5)
      glyph: root.secDigits[index]
    }
  }

  // ---- Print on the case and plate
  component Print: Text {
    id: printItem
    property real cx: 0
    property real cy: 0
    property real capH: 12
    property real fitW: 0          // printed length, design units
    property real rot: 0
    textFormat: Text.PlainText
    font.family: root.fontFamily
    font.bold: true
    font.pixelSize: Math.max(1, root.u(capH / 0.72))
    color: Lcd.PRINT_WHITE
    readonly property real capMid: baselineOffset - root.u(capH) / 2
    x: root.px(cx) - implicitWidth / 2
    y: root.py(cy) - capMid
    transform: [
      Scale {
        origin.x: printItem.implicitWidth / 2; origin.y: printItem.capMid
        xScale: printItem.fitW > 0 && printItem.implicitWidth > 0 ? root.u(printItem.fitW) / printItem.implicitWidth : 1
      },
      Rotation { origin.x: printItem.implicitWidth / 2; origin.y: printItem.capMid; angle: printItem.rot }
    ]
  }

  Print { text: "WORLD TIME"; cx: 309; cy: 69; capH: 15; fitW: 195; color: Lcd.PRINT_MINT }
  Print { text: "ILLUMINATOR"; cx: 309; cy: 600; capH: 15; fitW: 198; color: Lcd.PRINT_MINT; font.italic: true }
  Print { text: "5ALARMS"; cx: 231; cy: 159; capH: 12.5; fitW: 117 }
  Print { text: "CASIO"; cx: 395; cy: 164; capH: 17.5; fitW: 95; style: Text.Outline; styleColor: color }
  Print { text: "WR100M"; cx: 217; cy: 369; capH: 13; fitW: 97 }
  Print { text: "ADJUST"; cx: 114; cy: 279; capH: 12.5; fitW: 88; rot: -90 }
  Print { text: "MODE"; cx: 116; cy: 426; capH: 12.5; fitW: 67; rot: -90 }
  Print { text: "LIGHT"; cx: 498; cy: 245; capH: 12.5; fitW: 70; rot: 90 }
  Print { text: "SEARCH"; cx: 498; cy: 415; capH: 12.5; fitW: 100; rot: 90 }
  Print { text: "10 YEAR BATTERY"; cx: 306; cy: 507.5; capH: 13; fitW: 187; color: Lcd.PRINT_RED }

  CaseArt {
    anchors.fill: parent
    k: root.k
    yTop: root.yTop
    marginX: root.marginX
    glass: true
  }
}
