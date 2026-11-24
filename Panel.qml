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
  property string dynamicMode: "off"

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
    var txt = inputText.trim().slice(0, 7)
    if (!txt) return
    root.dynamicMode = "off"
    root.previewText = Model.generateAscii(txt)
    if (root.bar) {
      root.bar.run("omasaver set " + Commons.Util.shellQuote(txt))
    }
  }

  function resetToDefault() {
    root.dynamicMode = "off"
    root.inputText = "OMARCHY"
    root.previewText = Model.generateAscii("OMARCHY")
    if (root.bar) {
      root.bar.run("omasaver reset")
    }
  }

  function testDrive() {
    var txt = inputText.trim().slice(0, 7)
    if (txt && root.bar) {
      root.bar.run("omasaver set " + Commons.Util.shellQuote(txt) + " && omasaver test " + Commons.Util.shellQuote(currentEffect))
      Qt.callLater(function() { brandingFile.reload() })
    } else if (root.bar) {
      root.bar.run("omasaver test " + Commons.Util.shellQuote(currentEffect))
    }
  }

  function launchScreensaver() {
    root.close()
    if (root.bar) {
      root.bar.run("omasaver run")
    }
  }

  FileView {
    id: hostnameFile
    path: "/etc/hostname"
    printErrors: false
  }

  function getHostname() {
    var raw = (hostnameFile.text() || "").trim().split(".")[0].toUpperCase()
    return raw.slice(0, 7) || "HOST"
  }

  Timer {
    id: clockTimer
    interval: 5000
    repeat: true
    running: root.dynamicMode === "clock" && root.opened
    onTriggered: {
      var t = new Date()
      var h = String(t.getHours()).padStart(2, "0")
      var m = String(t.getMinutes()).padStart(2, "0")
      var timeStr = h + ":" + m
      root.inputText = timeStr
      root.previewText = Model.generateAscii(timeStr)
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

        // Section: Text input (Max 7 characters to fit screen boundary)
        Column {
          width: parent.width
          spacing: Style.space(6)

          Row {
            width: parent.width

            Text {
              text: "Screensaver Text / Name:"
              color: root.barForeground
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
              width: parent.width - counterLabel.implicitWidth
            }

            Text {
              id: counterLabel
              text: root.inputText.length + " / 7 max"
              color: root.inputText.length >= 7 ? Commons.Color.accent : Qt.rgba(1, 1, 1, 0.45)
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
            }
          }

          Row {
            width: parent.width
            spacing: Style.space(8)

            TextField {
              id: inputField
              width: parent.width - applyBtn.width - Style.space(8)
              text: root.inputText
              maximumLength: 7
              placeholderText: "1-7 chars (e.g. NIHAL, OMARCHY)"
              onTextEdited: {
                root.dynamicMode = "off"
                var clean = text.toUpperCase().slice(0, 7)
                root.inputText = clean
                root.previewText = Model.generateAscii(clean)
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

        PanelSeparator { width: parent.width }

        // Section: Dynamic Mode
        Column {
          width: parent.width
          spacing: Style.space(6)

          Text {
            text: "⏱ Dynamic Mode:"
            color: root.barForeground
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: true
          }

          Text {
            text: "Live Clock, Username, or Hostname — updates automatically"
            color: Qt.rgba(1, 1, 1, 0.5)
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
            width: parent.width
          }

          Row {
            width: parent.width
            spacing: Style.space(8)

            Button {
              text: "🕐 Clock"
              width: (parent.width - Style.space(24)) / 4
              bordered: true
              selected: root.dynamicMode === "clock"
              accent: Commons.Color.accent
              tooltipText: "Live clock (updates every minute)"
              onClicked: {
                root.dynamicMode = "clock"
                var t = new Date()
                var h = String(t.getHours()).padStart(2, "0")
                var m = String(t.getMinutes()).padStart(2, "0")
                var timeStr = h + ":" + m
                root.inputText = timeStr
                root.previewText = Model.generateAscii(timeStr)
                if (root.bar) {
                  root.bar.run("omasaver dynamic clock")
                }
              }
            }

            Button {
              text: "👤 User"
              width: (parent.width - Style.space(24)) / 4
              bordered: true
              selected: root.dynamicMode === "user"
              accent: Commons.Color.accent
              tooltipText: "Display system username"
              onClicked: {
                root.dynamicMode = "user"
                var uname = (Quickshell.env("USER") || "").trim().toUpperCase().slice(0, 7) || "USER"
                root.inputText = uname
                root.previewText = Model.generateAscii(uname)
                if (root.bar) {
                  root.bar.run("omasaver dynamic user")
                }
              }
            }

            Button {
              text: "🖥 Host"
              width: (parent.width - Style.space(24)) / 4
              bordered: true
              selected: root.dynamicMode === "host"
              accent: Commons.Color.accent
              tooltipText: "Display system hostname"
              onClicked: {
                root.dynamicMode = "host"
                var h = root.getHostname()
                root.inputText = h
                root.previewText = Model.generateAscii(h)
                if (root.bar) {
                  root.bar.run("omasaver dynamic host")
                }
              }
            }

            Button {
              text: "✕ Stop"
              width: (parent.width - Style.space(24)) / 4
              bordered: true
              selected: root.dynamicMode === "off"
              tooltipText: "Stop live dynamic mode"
              onClicked: {
                root.dynamicMode = "off"
                if (root.bar) {
                  root.bar.run("omasaver dynamic stop")
                }
              }
            }
          }

          // Dynamic status indicator
          Text {
            visible: root.dynamicMode !== "off"
            text: {
              if (root.dynamicMode === "clock") return "● Live Clock active — screensaver updates every minute (" + root.inputText + ")"
              if (root.dynamicMode === "user")  return "● Username mode active (" + root.inputText + ")"
              if (root.dynamicMode === "host")  return "● Hostname mode active (" + root.inputText + ")"
              return ""
            }
            color: Commons.Color.accent
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            wrapMode: Text.WordWrap
            width: parent.width
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
              var w = previewBox.width > 0 ? previewBox.width : Style.space(520)
              var avail = w - Style.space(24)
              var needed = avail / (previewCols * 0.61)
              return Math.max(7.0, Math.min(Style.space(11), Math.floor(needed * 10) / 10))
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
