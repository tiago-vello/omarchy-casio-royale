import QtQuick
import Quickshell
import qs.Commons
import qs.Commons as Commons
import qs.Ui

// Casio Royale: the AE-1200's stopwatch in the bar.
//
// The bar shows a stopwatch glyph, plus the count once it is not zero
// (accent colour while running). Left click opens the watch; right click
// starts and stops the stopwatch and middle click splits and clears it, so
// it can be run without opening anything. On the watch the four pushers
// behave as on module 3299, and A/Enter, B, C/M, D/Space press them from
// the keyboard.
//
// State lives in StopwatchStore (a singleton) so every monitor's copy of
// this widget shows the same stopwatch.
Panel {
  id: root

  moduleName: "tiago.ae1200"
  ipcTarget: "tiago.ae1200"

  Commons.Translations { id: strings; directory: Qt.resolvedUrl("i18n") }

  readonly property var store: StopwatchStore
  readonly property string glyph: "\uf2f2"
  readonly property bool showCount: !store.zero && !(bar && bar.vertical)
  readonly property real faceScale: Number(root.setting("scale", 1)) || 1

  // Pixels per design unit (the watch head is 652 x 660 units).
  readonly property real faceUnit: 0.6 * Style.spaceReal(1) * faceScale
  readonly property real sidePadding: Style.space(26)
  // How much of the popup colour stays over the blurred desktop around the
  // watch (0 clear .. 1 solid). Hyprland does the blur; see the README.
  readonly property real backdropAlpha: Math.max(0, Math.min(1, Number(root.setting("backdrop", 0.4))))

  readonly property string barText: showCount ? glyph + " " + store.barLabel : glyph

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight
  readonly property real openPanelIndicatorWidth: button.labelWidth

  onOpenedChanged: {
    if (opened) pinAnchor()
    store.viewers = Math.max(0, store.viewers + (opened ? 1 : -1))
  }
  Component.onDestruction: if (opened) store.viewers = Math.max(0, store.viewers - 1)

  // The popup hangs from this stand-in, not from the button. The button
  // widens when the count appears in the bar and narrows when it clears, and
  // KeyboardPanel re-centres on its anchor whenever the anchor changes, so
  // pressing D or A slid the whole watch sideways. The stand-in takes the
  // button's place in the bar window when the popup opens and stays put.
  Item {
    id: anchorProxy
    parent: button.QsWindow.window ? button.QsWindow.window.contentItem : root
    visible: false
  }

  function pinAnchor() {
    var win = button.QsWindow.window
    if (!win) return
    var p = button.mapToItem(win.contentItem, 0, 0)
    anchorProxy.x = p.x
    anchorProxy.y = p.y
    anchorProxy.width = button.width
    anchorProxy.height = button.height
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.barText
    active: root.store.running
    activeColor: Commons.Color.accent
    tooltipText: strings.t("tooltip")
    horizontalMargin: 7.5

    onPressed: function(b) {
      if (b === Qt.RightButton) root.store.startStop()
      else if (b === Qt.MiddleButton) root.store.splitReset()
      else {
        if (!root.opened) root.pinAnchor()
        root.toggle()
      }
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: anchorProxy
    owner: root
    bar: root.bar
    open: root.opened
    centerOnBar: false
    focusTarget: panel.loadedContent
    contentWidth: panel.fittedContentWidth(Math.round(652 * root.faceUnit + 2 * root.sidePadding))
    contentHeight: panel.fittedContentHeight(panel.loadedContentHeight)

    content: PanelKeyCatcher {
      id: catcher
      anchors.fill: parent
      implicitHeight: column.implicitHeight

      // See-through card, so Hyprland's blur shows around the watch. The
      // card belongs to KeyboardPanel, which has no setting for its colour:
      // find it up the parent chain (it is the item with a borderSpec) and
      // bind its colour to the theme's with our alpha. Each KeyboardPanel
      // has its own card, so no other popup changes.
      Component.onCompleted: {
        for (var it = catcher.parent; it; it = it.parent) {
          if (it.borderSpec !== undefined && it.contentLeftInset !== undefined) {
            it.color = Qt.binding(function() {
              var c = Commons.Color.popups.background
              return Qt.rgba(c.r, c.g, c.b, Math.min(c.a, root.backdropAlpha))
            })
            break
          }
        }
      }

      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      // Enter emits returnRequested and then activateRequested; Space only
      // the latter. That is how Space becomes D and Enter becomes A.
      property bool enterPending: false
      onReturnRequested: enterPending = true
      onActivateRequested: {
        root.store.press(enterPending ? "A" : "D")
        enterPending = false
      }
      onTextKey: function(t) {
        var k = t.toLowerCase()
        if (k === "a") root.store.press("A")
        else if (k === "b") root.store.press("B") // l is taken: the key catcher reads hjkl as arrows
        else if (k === "c" || k === "m") root.store.press("C")
        else if (k === "d") root.store.press("D")
        else if (k === "u") root.store.hold("C")
      }
      Column {
        id: column
        width: parent.width
        leftPadding: root.sidePadding
        rightPadding: root.sidePadding
        topPadding: Style.space(6)
        spacing: Style.space(10)

        WatchFace {
          id: face
          k: root.faceUnit
          anchors.horizontalCenter: parent.horizontalCenter
          mode: root.store.mode
          sw: root.store.shownParts
          splitHeld: root.store.splitHeld
          now: root.store.now
          lit: root.store.lit
          muted: root.store.muted
          cityFlash: root.store.cityFlash
          pressedKey: root.store.pressedKey
          onPressed: function(key) { root.store.press(key) }
          onHeld: function(key) { root.store.hold(key) }
        }

        Text {
          width: parent.width - 2 * root.sidePadding
          horizontalAlignment: Text.AlignHCenter
          textFormat: Text.PlainText
          wrapMode: Text.WordWrap
          text: strings.t("hint")
          font.family: root.bar ? root.bar.fontFamily : Style.font.family
          font.pixelSize: Style.font.caption
          color: Commons.Color.popups.text
          opacity: 0.75
        }
      }
    }
  }
}
