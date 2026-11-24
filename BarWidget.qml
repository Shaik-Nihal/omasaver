import QtQuick
import Quickshell
import qs.Ui

BarWidget {
  id: root
  moduleName: "nihal.omasaver"

  readonly property bool opened: panelLoader.item
    ? panelLoader.item.opened === true
    : false
  readonly property bool popoutSwitchClosing: panelLoader.item
    ? panelLoader.item.popoutSwitchClosing === true
    : false

  function open() {
    if (panelLoader.item) panelLoader.item.open()
  }

  function close() {
    if (panelLoader.item) panelLoader.item.close()
  }

  function toggle() {
    if (panelLoader.item) panelLoader.item.toggle()
  }

  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
  }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󱄄"
    tooltipText: "Omasaver Screensaver (Left-click to configure, Right-click to launch)"
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.LeftButton) root.toggle()
      else if (buttonCode === Qt.RightButton) {
        if (root.bar) {
          var home = Quickshell.env("HOME")
          var pluginBin = home + "/.config/omarchy/plugins/nihal.omasaver/bin/omasaver"
          var localBin = home + "/.local/bin/omasaver"
          var binCmd = "([ -x " + localBin + " ] && " + localBin + " || [ -x " + pluginBin + " ] && " + pluginBin + " || omasaver)"
          root.bar.run(binCmd + " run")
        }
      }
    }
  }
}
