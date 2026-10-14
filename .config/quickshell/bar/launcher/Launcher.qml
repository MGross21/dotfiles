pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import "../components"
import "../config"
import "../services"

Scope {
    id: root

    property bool open: false
    property bool sampling: false
    property ShellScreen target: Quickshell.screens[0]
    readonly property ShellScreen focused: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? Quickshell.screens[0]
    readonly property int maxHeight: Theme.launcherPadding * 3 + Theme.launcherFieldHeight + Theme.launcherRows * Theme.launcherRowHeight
    readonly property int barZone: Theme.barHeight + Theme.barMargin
    // Centered in the area below the bar, in screen coordinates.
    readonly property int paneTop: root.barZone + (root.target.height - root.barZone - root.maxHeight) / 2
    readonly property real minContrast: 4.5 // WCAG AA

    function toggle(): void {
        if (root.open || root.sampling) {
            root.open = false;
            root.sampling = false;
            return;
        }
        root.target = root.focused;
        root.sampling = true;
    }

    function show(light: bool): void {
        scheme.light = light;
        root.sampling = false;
        root.open = true;
    }

    function launch(app: DesktopEntry): void {
        if (!app)
            return;
        root.open = false;
        AppSearch.launch(app);
    }

    function _luminance(c: color): real {
        const lin = v => v <= 0.04045 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
        return 0.2126 * lin(c.r) + 0.7152 * lin(c.g) + 0.0722 * lin(c.b);
    }

    // WCAG contrast of `ink` over `paper` blended onto a backdrop of luminance `behind`.
    function _contrast(ink: color, paper: color, behind: real): real {
        const ground = Theme.launcherAlpha * root._luminance(paper) + (1 - Theme.launcherAlpha) * behind;
        const text = root._luminance(ink);
        return (Math.max(text, ground) + 0.05) / (Math.min(text, ground) + 0.05);
    }

    function _prefersLight(backdrop: real): bool {
        const behind = backdrop * (1 - Theme.scrimAlpha);
        const dark = root._contrast(Theme.fg, Theme.base, behind);
        return dark < root.minContrast && root._contrast(Theme.base, Theme.hi, behind) > dark;
    }

    Scheme {
        id: scheme
    }

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            root.toggle();
        }
    }

    Timer {
        interval: 250
        running: root.sampling
        onTriggered: root.show(false)
    }

    PanelWindow {
        screen: root.target
        visible: root.sampling || root.open
        color: root.open ? Theme.shade(Theme.scrimAlpha) : Theme.transparent

        WlrLayershell.namespace: "quickshell-launcher-scrim"
        WlrLayershell.layer: WlrLayer.Top
        exclusionMode: ExclusionMode.Ignore

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        MouseArea {
            anchors.fill: parent
            onClicked: root.toggle()
        }

        Loader {
            active: root.sampling

            sourceComponent: BackdropProbe {
                screen: root.target
                region: Qt.rect((root.target.width - Theme.launcherWidth) / 2, root.paneTop, Theme.launcherWidth, root.maxHeight)
                onMeasured: luminance => root.show(root._prefersLight(luminance))
            }
        }
    }

    LazyLoader {
        active: root.open

        PanelWindow {
            screen: root.target
            color: Theme.transparent

            WlrLayershell.namespace: scheme.light ? "quickshell-launcher-light" : "quickshell-launcher"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
            exclusionMode: ExclusionMode.Ignore

            anchors.top: true
            margins.top: root.paneTop
            implicitWidth: Theme.launcherWidth
            implicitHeight: root.maxHeight
            mask: Region {
                item: body
            }

            Item {
                id: body

                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }
                height: column.implicitHeight + Theme.launcherPadding * 2

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.launcherRadius
                    color: Theme.tinted(scheme.paper, Theme.launcherAlpha)
                    antialiasing: true
                }

                Glass {
                    anchors.fill: parent
                    radius: Theme.launcherRadius
                    alpha: 0
                }

                Column {
                    id: column

                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        margins: Theme.launcherPadding
                    }
                    spacing: Theme.launcherPadding

                    Item {
                        width: parent.width
                        height: Theme.launcherFieldHeight

                        Glass {
                            anchors.fill: parent
                            radius: Theme.launcherFieldRadius
                            alpha: field.text === "" ? Theme.surfaceAlpha / 2 : Theme.surfaceAlpha
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: Theme.launcherFieldRadius
                            color: Theme.transparent
                            border.width: 1
                            border.color: Theme.tinted(scheme.accent, Theme.selectionRimAlpha)
                            antialiasing: true
                        }

                        Icon {
                            id: glyph

                            anchors {
                                left: parent.left
                                leftMargin: Theme.launcherPadding
                                verticalCenter: parent.verticalCenter
                            }
                            source: Icons.search
                            color: field.text === "" ? scheme.inkDim : scheme.accent
                        }

                        TextInput {
                            id: field

                            anchors {
                                left: glyph.right
                                leftMargin: Theme.launcherPadding
                                right: parent.right
                                rightMargin: Theme.launcherPadding
                                verticalCenter: parent.verticalCenter
                            }
                            focus: true
                            color: scheme.inkStrong
                            selectionColor: Theme.tinted(scheme.accent, Theme.selectionRimAlpha)
                            selectedTextColor: scheme.ink
                            font.family: Theme.font
                            font.pixelSize: Theme.fontSizeInput
                            clip: true
                            Component.onCompleted: forceActiveFocus()
                            onAccepted: root.launch((list.currentItem as AppRow)?.modelData)

                            Keys.onPressed: event => {
                                const ctrl = event.modifiers & Qt.ControlModifier;
                                const page = Theme.launcherRows - 1;
                                if (event.key === Qt.Key_Escape)
                                    root.toggle();
                                else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab || ctrl && (event.key === Qt.Key_J || event.key === Qt.Key_N))
                                    list.incrementCurrentIndex();
                                else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab || ctrl && (event.key === Qt.Key_K || event.key === Qt.Key_P))
                                    list.decrementCurrentIndex();
                                else if (event.key === Qt.Key_PageDown)
                                    list.currentIndex = Math.min(list.count - 1, list.currentIndex + page);
                                else if (event.key === Qt.Key_PageUp)
                                    list.currentIndex = Math.max(0, list.currentIndex - page);
                                else
                                    return;
                                event.accepted = true;
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Search apps"
                                color: scheme.inkDim
                                font: parent.font
                                visible: field.text === ""
                            }
                        }
                    }

                    ListView {
                        id: list

                        width: parent.width
                        height: Math.min(count, Theme.launcherRows) * Theme.launcherRowHeight
                        visible: count > 0
                        model: AppSearch.query(field.text)
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        highlightMoveDuration: Theme.durFast
                        highlightResizeDuration: 0

                        highlight: Rectangle {
                            radius: Theme.launcherRowRadius
                            color: Theme.tinted(scheme.accent, Theme.selectionAlpha)
                            border.width: 1
                            border.color: Theme.tinted(scheme.accent, Theme.selectionRimAlpha)
                            antialiasing: true
                        }

                        delegate: AppRow {
                            id: row

                            width: list.width
                            scheme: scheme
                            onHovered: list.currentIndex = row.index
                            onActivated: root.launch(row.modelData)
                        }

                        Behavior on height {
                            NumberAnimation {
                                duration: Theme.durBase
                                easing.type: Theme.easeStandard
                            }
                        }
                    }

                    Text {
                        width: parent.width
                        height: Theme.launcherRowHeight
                        visible: list.count === 0
                        text: "No matches"
                        color: scheme.inkDim
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSizeLarge
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
    }
}
