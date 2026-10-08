import QtQuick
import qs.Commons
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.Ui
import "Strings.js" as Strings

BarWidget {
  id: root
  moduleName: "gread.window-layout"

  readonly property string lang: Strings.resolve(root.settings ? root.settings.language : "auto",
    Quickshell.env("LC_ALL") || Quickshell.env("LC_MESSAGES") || Quickshell.env("LANG"))

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
  }

  function togglePanel() {
    if (panelLoader.item && panelLoader.item.toggle) panelLoader.item.toggle()
  }

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false

  function open() {
    if (panelLoader.item && panelLoader.item.open) panelLoader.item.open()
  }

  function close() {
    if (panelLoader.item && panelLoader.item.close) panelLoader.item.close()
  }

  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  // ---- Optional automations (bin/session reads ~/.config/gread.window-layout
  // and returns at once when an option is off). Every bar instance runs this;
  // the script locks and remembers what it already did.
  readonly property string sessionScript: Qt.resolvedUrl("bin/session").toString().replace(/^file:\/\//, "")
  property string pendingDock: ""

  // Restore the saved layout once per Hyprland session. Also catch up on a
  // display plugged in while the shell was down (it restarts around resume),
  // whose monitoradded event this widget never heard.
  Component.onCompleted: {
    loginProc.running = true
    root.dock("added")
  }

  Process {
    id: loginProc
    command: ["bash", root.sessionScript, "login"]
  }

  function dock(event) {
    if (dockProc.running) {
      root.pendingDock = event
      return
    }
    dockProc.command = ["bash", root.sessionScript, "dock", event]
    dockProc.running = true
  }

  Process {
    id: dockProc
    onExited: function() {
      if (root.pendingDock === "") return
      var next = root.pendingDock
      root.pendingDock = ""
      root.dock(next)
    }
  }

  // Only external displays matter. The laptop panel itself is "added" and
  // "removed" whenever it is switched on or off, and FALLBACK comes and goes
  // with the last display.
  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (event.name !== "monitorremovedv2" && event.name !== "monitoraddedv2") return
      // v2 data: "ID,NAME,DESCRIPTION"
      var monitor = String(event.data || "").split(",")[1] || ""
      if (/^(eDP|LVDS|DSI)-|^FALLBACK$|^HEADLESS-/.test(monitor)) return
      root.dock(event.name === "monitorremovedv2" ? "removed" : "added")
    }
  }

  // No real display left (only Hyprland's virtual FALLBACK): typically the lid
  // opened, or the system resumed, while the laptop display was off.
  Timer {
    interval: 3000
    repeat: true
    running: true
    onTriggered: {
      var real = Hyprland.monitors.values.filter(function(m) { return !/^(FALLBACK|HEADLESS-)/.test(m.name) })
      if (real.length === 0) root.dock("lid")
    }
  }

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
    text: "󰕰"
    slotSize: Style.bar.statusSlot
    tooltipText: Strings.tr(root.lang, "title")
    onPressed: function(b) { root.togglePanel() }
  }
}
