import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "Model.js" as Model

Panel {
  id: root
  moduleName: "nihal.omasaver"
  ipcTarget: "nihal.omasaver"
  manageIpc: true

  property var anchorItem: null
  property var hostWidget: null

  property string inputText: "NIHAL"
  property string currentEffect: "matrix"
  property string previewText: Model.generateAscii(inputText)
  property bool isCustomActive: false

  function open() {
    root.controller.show()
    brandingFile.reload()
  }

  function close() {
    root.controller.hide()
  }

  function toggle() {
    if (root.opened) root.close()
    else root.open()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.hostWidget || root, direction)
    return false
  }

  function applyCustomText() {
    var txt = inputText.trim()
    if (!txt) return
    if (root.bar) {
      root.bar.run("omasaver set " + Commons.Util.shellQuote(txt))
      Qt.callLater(function() { brandingFile.reload() })
    }
  }

  function resetToDefault() {
    if (root.bar) {
      root.bar.run("omasaver reset")
      Qt.callLater(function() { brandingFile.reload() })
    }
  }

  function testDrive() {
    if (root.bar) {
      root.bar.run("omasaver test " + Commons.Util.shellQuote(currentEffect))
    }
  }

  function launchScreensaver() {
    if (root.bar) {
      root.bar.run("omasaver run")
    }
  }

  FileView {
    id: brandingFile
    path: Quickshell.env("HOME") + "/.config/omarchy/branding/screensaver.txt"
    watchChanges: true
    printErrors: false
    onLoaded: {
      root.isCustomActive = true
    }
    onLoadFailed: {
      root.isCustomActive = false
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(520))
    contentHeight: panel.fittedContentHeight(mainColumn.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: mainColumn
        width: parent.width
        spacing: Style.space(12)
        topPadding: Style.space(4)
        bottomPadding: Style.space(4)

        // Hero Header
        PanelHero {
          title: "Omasaver"
          meta: root.isCustomActive ? "Active: Custom Screensaver" : "Active: Default Omarchy Logo"
          detail: root.isCustomActive ? "Custom" : "Default"
          iconComponent: Component {
            Text {
              text: "󱄄"
              font.family: Style.font.family
              font.pixelSize: Style.font.display
              color: root.barForeground
            }
          }
        }

        PanelSeparator { width: parent.width }

        // Section: Text input
        Column {
          width: parent.width
          spacing: Style.space(6)

          Text {
            text: "Screensaver Text / Name:"
            color: root.barForeground
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
          }

          Row {
            width: parent.width
            spacing: Style.space(8)

            TextField {
              id: inputField
              width: parent.width - applyBtn.width - Style.space(8)
              text: root.inputText
              placeholderText: "Enter custom text (e.g. NIHAL)"
              onTextChanged: {
                root.inputText = text
                root.previewText = Model.generateAscii(text)
              }
              onAccepted: root.applyCustomText()
            }

            Button {
              id: applyBtn
              text: "Apply"
              bordered: true
              accent: Commons.Color.accent
              onClicked: root.applyCustomText()
            }
          }
        }

        // Section: Live Signature ASCII Preview
        Column {
          width: parent.width
          spacing: Style.space(4)

          Text {
            text: "Live Signature Preview (Official Omarchy Font):"
            color: root.barForeground
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
          }

          Rectangle {
            id: previewBox
            width: parent.width
            implicitHeight: previewFlick.implicitHeight + Style.space(16)
            color: Qt.rgba(0, 0, 0, 0.45)
            border.color: Qt.rgba(1, 1, 1, 0.15)
            border.width: 1
            radius: Style.cornerRadius

            readonly property int previewCols: root.previewText ? (root.previewText.split("\n")[0] || "").length : 0
            readonly property real autoFontSize: {
              if (previewCols <= 0) return Style.space(9)
              var avail = previewBox.width - Style.space(24)
              var needed = avail / (previewCols * 0.61)
              return Math.max(5.0, Math.min(Style.space(9), Math.floor(needed * 10) / 10))
            }

            Flickable {
              id: previewFlick
              anchors.fill: parent
              anchors.margins: Style.space(8)
              implicitHeight: previewTextItem.implicitHeight + (scrollBarH.visible ? scrollBarH.height : 0)
              contentWidth: Math.max(width, previewTextItem.implicitWidth)
              contentHeight: previewTextItem.implicitHeight
              clip: true
              boundsBehavior: Flickable.StopAtBounds
              flickableDirection: Flickable.HorizontalAndVerticalFlick

              ScrollBar.horizontal: ScrollBar {
                id: scrollBarH
                policy: previewTextItem.implicitWidth > previewFlick.width ? ScrollBar.AlwaysOn : ScrollBar.AsNeeded
              }

              Text {
                id: previewTextItem
                text: root.previewText || "TYPE TEXT ABOVE TO PREVIEW"
                color: Commons.Color.accent
                font.family: "JetBrainsMono Nerd Font, monospace"
                font.pixelSize: previewBox.autoFontSize
                lineHeight: 0.95
              }
            }
          }
        }

        // Section: Effect Selector
        Column {
          width: parent.width
          spacing: Style.space(6)

          Text {
            text: "Animation Effect for Live Test:"
            color: root.barForeground
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
          }

          Dropdown {
            id: effectDropdown
            width: parent.width
            options: [
              { value: "matrix", label: "Matrix Rain (Digital Rain)" },
              { value: "decrypt", label: "Decryption (Scramble Crack)" },
              { value: "fireworks", label: "Fireworks (Exploding Sparks)" },
              { value: "rain", label: "Rain (Falling Drops)" },
              { value: "beams", label: "Beams (Searchlight Lasers)" },
              { value: "burn", label: "Burn (Wall of Fire)" },
              { value: "laseretch", label: "Laser Etch (Engraving)" },
              { value: "blackhole", label: "Black Hole (Singularity Burst)" },
              { value: "colorshift", label: "Color Shift (Chromatic RGB)" },
              { value: "bubbles", label: "Bubbles (Soap Bubbles)" },
              { value: "print", label: "Typewriter (Mechanical Print)" },
              { value: "random", label: "Random (Cycles all 24 effects)" }
            ]
            value: root.currentEffect
            onValueChanged: {
              if (value) root.currentEffect = value
            }
          }
        }

        PanelSeparator { width: parent.width }

        // Actions: Test Drive, Reset, Launch
        Row {
          width: parent.width
          spacing: Style.space(8)

          Button {
            text: "󰐥 Test Drive"
            width: (parent.width - Style.space(16)) / 3
            bordered: true
            tooltipText: "Preview in floating terminal"
            onClicked: root.testDrive()
          }

          Button {
            text: "󰁯 Reset"
            width: (parent.width - Style.space(16)) / 3
            bordered: true
            tooltipText: "Revert to default Omarchy logo"
            onClicked: root.resetToDefault()
          }

          Button {
            text: "󱄄 Full Screen"
            width: (parent.width - Style.space(16)) / 3
            bordered: true
            accent: Commons.Color.accent
            tooltipText: "Launch full screensaver now"
            onClicked: root.launchScreensaver()
          }
        }
      }
    }
  }
}
