import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Strings.js" as Strings

Panel {
  id: root
  moduleName: "gread.window-layout"
  ipcTarget: "gread.window-layout"
  manageIpc: true

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root

  readonly property string script: Qt.resolvedUrl("bin/window-layout").toString().replace(/^file:\/\//, "")
  readonly property int maxOutputChars: 32768

  readonly property color fg: root.bar ? root.bar.foreground : Color.foreground
  readonly property string fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
  // The panel already pads its content; buttons fill whatever width is left.
  readonly property real innerWidth: Math.max(Style.space(200), keyCatcher.width - Style.space(4))
  readonly property real gap: Style.space(6)

  // The widget's "language" setting, or the system language when "auto".
  readonly property string lang: Strings.resolve(root.setting("language", "auto"),
    Quickshell.env("LC_ALL") || Quickshell.env("LC_MESSAGES") || Quickshell.env("LANG"))

  function tr(key, a1, a2, a3) {
    return Strings.tr(root.lang, key, a1, a2, a3)
  }

  // Last `window-layout status` and the window the panel acts on. The window is
  // captured when the panel opens: while it is open the panel holds keyboard
  // focus, so "the active window" would no longer mean the one you came from.
  property var info: null
  property string target: ""
  property bool busy: false
  property string errorText: ""

  readonly property var win: info && info.window ? info.window : null
  readonly property bool hasWindow: win !== null && target !== ""
  readonly property bool tiled: hasWindow && !win.floating && win.fullscreen === 0
  readonly property bool dwindle: info ? info.layout === "dwindle" : false
  readonly property var otherMonitors: {
    if (!info || !win) return []
    return info.monitors.filter(function(m) { return m.name !== win.monitor })
  }

  function monitorLabel(m) {
    if (info && m.name === info.laptop) return root.tr("laptop")
    return m.model && !/^0x/.test(m.model) ? m.model : m.name
  }

  function open() {
    root.target = ""
    root.errorText = ""
    root.controller.show()
    refreshStatus()
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
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  // Structured argv (never a "bash -c" string), behind `timeout` so a wedged
  // hyprctl can't hang the panel.
  function command(args) {
    return ["timeout", "-k", "2", "10", "bash", root.script].concat(args)
  }

  function refreshStatus() {
    if (statusProc.running) statusProc.running = false
    statusProc.command = root.command(root.target ? ["status", root.target] : ["status"])
    statusProc.running = true
  }

  // Window actions carry the captured address; gaps/laptop/mirror are global.
  function act(action, arg) {
    if (root.busy) return
    var args = [action]
    if (action !== "gaps" && action !== "laptop" && action !== "mirror") {
      if (!root.hasWindow) return
      args.push(root.target)
      if (arg !== undefined) args.push(String(arg))
    }
    root.busy = true
    root.errorText = ""
    actionProc.command = root.command(args)
    actionProc.running = true
  }

  Process {
    id: statusProc
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var raw = String(text || "").slice(0, root.maxOutputChars).trim()
        try {
          root.info = JSON.parse(raw)
        } catch (e) {
          root.info = null
          root.errorText = root.tr("errStatus")
          return
        }
        if (!root.target && root.info.window) root.target = root.info.window.address
        else if (root.target && (!root.info.window || root.info.window.address !== root.target))
          root.target = ""
      }
    }
  }

  Process {
    id: actionProc
    stdout: StdioCollector { waitForEnd: true }
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var err = String(text || "").slice(0, 400).trim()
        if (err) root.errorText = Strings.errorText(root.lang, err)
      }
    }
    onExited: function(exitCode) {
      root.busy = false
      // Hyprland applies some changes (reloads, monitor toggles) a moment later.
      refreshTimer.restart()
    }
  }

  Timer {
    id: refreshTimer
    interval: 250
    onTriggered: root.refreshStatus()
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(380))
    contentHeight: panel.fittedContentHeight(content.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: content.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
          id: content
          width: parent.width
          spacing: Style.space(10)
          topPadding: Style.space(4)
          bottomPadding: Style.space(4)

          // ---- Header: the window every button below acts on
          Column {
            width: root.innerWidth
            spacing: Style.space(2)

            Row {
              spacing: Style.space(8)

              Text {
                id: title
                text: root.tr("title")
                color: root.fg
                font.family: root.fontFamily
                font.pixelSize: Style.font.title
                font.bold: true
              }

              Text {
                anchors.baseline: title.baseline
                text: "by Gread"
                color: Qt.darker(root.fg, 1.4)
                font.family: root.fontFamily
                font.pixelSize: Style.font.caption
              }
            }

            Text {
              width: parent.width
              text: root.hasWindow ? root.tr("window", root.win.title || root.win.class) : root.tr("noWindow")
              color: root.fg
              font.family: root.fontFamily
              font.pixelSize: Style.font.bodySmall
              elide: Text.ElideRight
              textFormat: Text.PlainText
            }

            Text {
              visible: root.hasWindow
              text: root.hasWindow
                ? root.tr("status", root.win.workspace, root.win.monitor, root.info.layout)
                : ""
              color: Qt.darker(root.fg, 1.4)
              font.family: root.fontFamily
              font.pixelSize: Style.font.caption
              textFormat: Text.PlainText
            }
          }

          // ---- Window
          PanelSectionHeader { text: root.tr("sectionWindow"); foreground: root.fg; fontFamily: root.fontFamily }

          Grid {
            columns: 3
            spacing: root.gap
            Btn { width: root.cell(3); icon: "󰊓"; label: root.tr("fullscreen"); active: root.hasWindow && root.win.fullscreen === 2; available: root.hasWindow; onClicked: root.act("fullscreen") }
            Btn { width: root.cell(3); icon: "󰁌"; label: root.tr("maximize"); active: root.hasWindow && root.win.fullscreen === 1; available: root.hasWindow; onClicked: root.act("maximize") }
            Btn { width: root.cell(3); icon: "󰖲"; label: root.tr("float"); active: root.hasWindow && root.win.floating; available: root.hasWindow; onClicked: root.act("float") }
            Btn { width: root.cell(3); icon: "󰐃"; label: root.tr("pin"); active: root.hasWindow && root.win.pinned; available: root.hasWindow; onClicked: root.act("pop") }
            Btn { width: root.cell(3); icon: "󰅖"; label: root.tr("close"); available: root.hasWindow; onClicked: root.act("close") }
          }

          // ---- Split
          PanelSectionHeader { text: root.tr("sectionSplit"); foreground: root.fg; fontFamily: root.fontFamily }

          Row {
            spacing: root.gap
            Btn { width: root.cell(2); icon: "󰯌"; label: root.tr("toggleSplit"); available: root.tiled && root.dwindle; onClicked: root.act("togglesplit") }
            Btn { width: root.cell(2); icon: "󰓡"; label: root.tr("swapSides"); available: root.tiled && root.dwindle; onClicked: root.act("swapsplit") }
          }

          Row {
            spacing: root.gap
            Repeater {
              model: [
                { label: "30 | 70", ratio: "0.6" },
                { label: "40 | 60", ratio: "0.8" },
                { label: "50 | 50", ratio: "1.0" },
                { label: "60 | 40", ratio: "1.2" },
                { label: "70 | 30", ratio: "1.4" }
              ]
              Btn { width: root.cell(5); label: modelData.label; available: root.tiled && root.dwindle; onClicked: root.act("ratio", modelData.ratio) }
            }
          }

          Hint { text: root.tr("ratioHint") }

          // ---- Move window
          PanelSectionHeader { text: root.tr("sectionMove"); foreground: root.fg; fontFamily: root.fontFamily }

          Row {
            spacing: Style.space(12)

            Grid {
              columns: 3
              spacing: root.gap / 2
              Item { width: Style.space(34); height: Style.space(30) }
              Btn { width: Style.space(34); height: Style.space(30); label: "↑"; available: root.tiled; onClicked: root.act("swap", "u") }
              Item { width: Style.space(34); height: Style.space(30) }
              Btn { width: Style.space(34); height: Style.space(30); label: "←"; available: root.tiled; onClicked: root.act("swap", "l") }
              Item { width: Style.space(34); height: Style.space(30) }
              Btn { width: Style.space(34); height: Style.space(30); label: "→"; available: root.tiled; onClicked: root.act("swap", "r") }
              Item { width: Style.space(34); height: Style.space(30) }
              Btn { width: Style.space(34); height: Style.space(30); label: "↓"; available: root.tiled; onClicked: root.act("swap", "d") }
              Item { width: Style.space(34); height: Style.space(30) }
            }

            Column {
              spacing: Style.space(4)
              anchors.verticalCenter: parent.verticalCenter
              Hint { text: root.tr("arrowsHint") }
              Hint { text: root.tr("numbersHint") }
            }
          }

          Grid {
            columns: 9
            spacing: root.gap / 2
            Repeater {
              model: 9
              Btn {
                width: (root.innerWidth - 8 * root.gap / 2) / 9
                label: String(index + 1)
                active: root.hasWindow && root.win.workspace === index + 1
                available: root.hasWindow && root.win.workspace !== index + 1
                onClicked: root.act("workspace", index + 1)
              }
            }
          }

          Flow {
            width: root.innerWidth
            spacing: root.gap
            visible: root.otherMonitors.length > 0
            Hint { text: root.tr("toDisplay"); height: Style.space(34); verticalAlignment: Text.AlignVCenter }
            Repeater {
              model: root.otherMonitors
              Btn { width: root.cell(3); icon: "󰍹"; label: root.monitorLabel(modelData); available: root.hasWindow; onClicked: root.act("monitor", modelData.name) }
            }
          }

          // ---- Workspace
          PanelSectionHeader { text: root.tr("sectionWorkspace"); foreground: root.fg; fontFamily: root.fontFamily }

          Row {
            spacing: root.gap
            Btn {
              width: root.cell(2)
              icon: "󱂬"
              label: root.tr("layout", root.info && root.info.layout ? root.info.layout : "dwindle")
              available: root.hasWindow
              onClicked: root.act("layout")
            }
            Btn {
              width: root.cell(2)
              icon: "󰕮"
              label: root.tr("gaps")
              active: root.info ? !root.info.gapsOff : false
              onClicked: root.act("gaps")
            }
          }

          Flow {
            width: root.innerWidth
            spacing: root.gap
            visible: root.otherMonitors.length > 0
            Hint { text: root.tr("workspaceToDisplay"); height: Style.space(34); verticalAlignment: Text.AlignVCenter }
            Repeater {
              model: root.otherMonitors
              Btn { width: root.cell(3); icon: "󰍺"; label: root.monitorLabel(modelData); available: root.hasWindow; onClicked: root.act("workspace-monitor", modelData.name) }
            }
          }

          // ---- Displays (laptops only)
          PanelSectionHeader {
            visible: root.info ? root.info.laptop !== "" : false
            text: root.tr("sectionDisplays")
            foreground: root.fg
            fontFamily: root.fontFamily
          }

          Row {
            visible: root.info ? root.info.laptop !== "" : false
            spacing: root.gap
            Btn {
              width: root.cell(2)
              icon: "󰌢"
              label: root.tr("laptopDisplay")
              active: root.info ? !root.info.laptopOff : false
              // Omarchy refuses to turn off the only active display.
              available: root.info ? (root.info.laptopOff || root.info.monitors.length > 1) : false
              onClicked: root.act("laptop")
            }
            Btn {
              width: root.cell(2)
              icon: "󰍺"
              label: root.tr("mirrorLaptop")
              active: root.info ? root.info.mirror : false
              onClicked: root.act("mirror")
            }
          }

          Text {
            visible: root.errorText !== ""
            width: root.innerWidth
            text: root.errorText
            color: Color.urgent
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
            wrapMode: Text.WordWrap
            textFormat: Text.PlainText
          }
        }
      }
    }
  }

  function cell(columns) {
    return (root.innerWidth - (columns - 1) * root.gap) / columns
  }

  component Hint: Text {
    color: Qt.darker(root.fg, 1.4)
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
    textFormat: Text.PlainText
  }

  component Btn: Rectangle {
    id: btn
    property string label: ""
    property string icon: ""
    property bool active: false
    property bool available: true
    signal clicked()

    height: Style.space(34)
    radius: Style.cornerRadius
    color: btn.active ? Style.hoverFillFor(root.fg, Color.accent)
      : (area.containsMouse && btn.available ? Qt.alpha(root.fg, 0.10) : "transparent")
    border.width: 1
    border.color: btn.active ? Color.accent : Qt.alpha(root.fg, 0.18)
    opacity: btn.available && !root.busy ? 1 : 0.4

    Row {
      anchors.centerIn: parent
      spacing: Style.space(6)
      width: Math.min(implicitWidth, btn.width - Style.space(8))
      clip: true

      Text {
        visible: btn.icon !== ""
        text: btn.icon
        color: btn.active ? Style.hoverStateColor(root.fg, Color.accent) : root.fg
        font.family: root.fontFamily
        font.pixelSize: Style.font.subtitle
        anchors.verticalCenter: parent.verticalCenter
      }

      Text {
        text: btn.label
        color: btn.active ? Style.hoverStateColor(root.fg, Color.accent) : root.fg
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
        elide: Text.ElideRight
        anchors.verticalCenter: parent.verticalCenter
      }
    }

    MouseArea {
      id: area
      anchors.fill: parent
      hoverEnabled: true
      enabled: btn.available && !root.busy
      cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
      onClicked: btn.clicked()
    }
  }
}
