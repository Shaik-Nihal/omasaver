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
  property string fontStyle: "large"
  property string subtitleText: ""
  property string currentEffect: "matrix"
  property string previewText: Model.generateAscii(inputText, fontStyle, subtitleText)
  property bool isCustomActive: false
  property string dynamicMode: "off"

  function updatePreview() {
    root.previewText = Model.generateAscii(root.inputText, root.fontStyle, root.subtitleText)
  }

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

  // Resolve the plugin's bundled CLI script cleanly regardless of install location
  readonly property string pluginBin: {
    var resolved = decodeURIComponent(String(Qt.resolvedUrl("bin/omasaver") || "")).replace(/^file:\/\//, "")
    if (resolved && resolved.indexOf("bin/omasaver") !== -1) return resolved
    return Quickshell.env("HOME") + "/.config/omarchy/plugins/nihal.omasaver/bin/omasaver"
  }

  property bool _symlinkChecked: false

  function ensureCliSymlink() {
    if (root._symlinkChecked || !root.bar) return
    root._symlinkChecked = true
    // Auto-symlink omasaver to ~/.local/bin so the CLI is immediately available in terminal without manual setup
    var home = Quickshell.env("HOME")
    var localBin = home + "/.local/bin/omasaver"
    var qPlugin = Commons.Util.shellQuote(root.pluginBin)
    var qLocal = Commons.Util.shellQuote(localBin)
    root.bar.run(
      "mkdir -p ~/.local/bin && " +
      "{ [ -f " + qPlugin + " ] && chmod +x " + qPlugin + " 2>/dev/null || true; } && " +
      "{ [ -x " + qPlugin + " ] && [ ! -e " + qLocal + " ] && ln -sf " + qPlugin + " " + qLocal + " 2>/dev/null || true; }"
    )
  }

  onBarChanged: ensureCliSymlink()
  Component.onCompleted: ensureCliSymlink()

  function formatArgs(args) {
    var out = []
    for (var i = 0; i < args.length; i++) {
      out.push(Commons.Util.shellQuote(String(args[i])))
    }
    return out.join(" ")
  }

  function runOmasaverSequence(commandArgLists) {
    if (!root.bar || !commandArgLists || commandArgLists.length === 0) return
    var home = Quickshell.env("HOME")
    var localBin = home + "/.local/bin/omasaver"
    var qPlugin = Commons.Util.shellQuote(root.pluginBin)
    var qLocal = Commons.Util.shellQuote(localBin)
    var resolver =
      "if [ -f " + qPlugin + " ]; then run_oma() { bash " + qPlugin + " \"$@\"; }; " +
      "elif [ -x " + qLocal + " ]; then run_oma() { " + qLocal + " \"$@\"; }; " +
      "else run_oma() { omasaver \"$@\"; }; fi"
    var calls = []
    for (var i = 0; i < commandArgLists.length; i++) {
      calls.push("run_oma " + formatArgs(commandArgLists[i]))
    }
    root.bar.run(resolver + "; " + calls.join(" && "))
  }

  function runOmasaver(args) {
    runOmasaverSequence([args])
  }

  function applyCustomText() {
    var maxL = root.fontStyle === "compact" ? 14 : 7
    var txt = inputText.trim().slice(0, maxL)
    if (!txt) return
    root.dynamicMode = "off"
    root.updatePreview()
    var setArgs = ["set", txt, "--font", root.fontStyle]
    if (root.subtitleText.trim().length > 0) {
      setArgs.push("--subtitle", root.subtitleText.trim())
    }
    root.runOmasaver(setArgs)
  }

  function resetToDefault() {
    root.dynamicMode = "off"
    root.fontStyle = "large"
    root.subtitleText = ""
    root.inputText = "OMARCHY"
    root.updatePreview()
    root.runOmasaver(["reset"])
  }

  function testDrive() {
    if (root.opened) root.close()
    var maxL = root.fontStyle === "compact" ? 14 : 7
    var txt = inputText.trim().slice(0, maxL)
    if (root.dynamicMode === "off" && txt) {
      var setArgs = ["set", txt, "--font", root.fontStyle]
      if (root.subtitleText.trim().length > 0) {
        setArgs.push("--subtitle", root.subtitleText.trim())
      }
      root.runOmasaverSequence([setArgs, ["test", currentEffect]])
    } else {
      root.runOmasaver(["test", currentEffect])
    }
  }

  function launchScreensaver() {
    if (root.opened) root.close()
    root.runOmasaver(["run"])
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
      if (root.inputText !== timeStr) {
        root.inputText = timeStr
        root.updatePreview()
      }
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

        // Section: Font Style & Text Input
        Column {
          width: parent.width
          spacing: Style.space(8)

          // Font Style Selector Toggle
          Column {
            width: parent.width
            spacing: Style.space(4)

            Text {
              text: "Font Style & Size:"
              color: root.barForeground
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: true
            }

            Row {
              width: parent.width
              spacing: Style.space(8)

              Button {
                text: "󰬚 Large (8-row, 1-7 chars)"
                width: (parent.width - Style.space(8)) / 2
                bordered: true
                selected: root.fontStyle === "large"
                accent: Commons.Color.accent
                tooltipText: "Authentic Omarchy 8-row curved font (up to 7 characters)"
                onClicked: {
                  root.fontStyle = "large"
                  if (root.inputText.length > 7) {
                    root.inputText = root.inputText.slice(0, 7)
                  }
                  root.updatePreview()
                }
              }

              Button {
                text: "󰬛 Compact (5-row, 1-14 chars)"
                width: (parent.width - Style.space(8)) / 2
                bordered: true
                selected: root.fontStyle === "compact"
                accent: Commons.Color.accent
                tooltipText: "Compact 5-row font for longer names & words (up to 14 characters)"
                onClicked: {
                  root.fontStyle = "compact"
                  root.updatePreview()
                }
              }
            }
          }

          // Main text input
          Column {
            width: parent.width
            spacing: Style.space(4)

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
                readonly property int maxChars: root.fontStyle === "compact" ? 14 : 7
                text: root.inputText.length + " / " + maxChars + " max"
                color: root.inputText.length >= maxChars ? Commons.Color.accent : Qt.rgba(1, 1, 1, 0.45)
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
                maximumLength: root.fontStyle === "compact" ? 14 : 7
                placeholderText: root.fontStyle === "compact" ? "1-14 chars (e.g. SHAIK NIHAL, DEVELOPER)" : "1-7 chars (e.g. NIHAL, OMARCHY)"
                onTextEdited: {
                  root.dynamicMode = "off"
                  var maxL = root.fontStyle === "compact" ? 14 : 7
                  var clean = text.toUpperCase().slice(0, maxL)
                  root.inputText = clean
                  root.updatePreview()
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

          // Subtitle / Tagline input
          Column {
            width: parent.width
            spacing: Style.space(4)

            Row {
              width: parent.width

              Text {
                text: "Subtitle / Tagline (Optional):"
                color: root.barForeground
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
                font.bold: true
                width: parent.width - subCounter.implicitWidth
              }

              Text {
                id: subCounter
                text: root.subtitleText.length + " / 20 max"
                color: root.subtitleText.length >= 20 ? Commons.Color.accent : Qt.rgba(1, 1, 1, 0.45)
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
              }
            }

            TextField {
              id: subtitleField
              width: parent.width
              text: root.subtitleText
              maximumLength: 20
              placeholderText: "e.g. DO NOT TOUCH, ARCH LINUX, DEV"
              onTextEdited: {
                root.subtitleText = text.toUpperCase().slice(0, 20)
                root.updatePreview()
              }
              onAccepted: root.applyCustomText()
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
                root.updatePreview()
                root.runOmasaver(["dynamic", "clock"])
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
                root.updatePreview()
                root.runOmasaver(["dynamic", "user"])
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
                root.updatePreview()
                root.runOmasaver(["dynamic", "host"])
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
                root.runOmasaver(["dynamic", "stop"])
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
            tooltipText: "Preview screensaver in full screen (font size 18, 120 FPS)"
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
