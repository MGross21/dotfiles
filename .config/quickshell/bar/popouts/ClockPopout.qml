import QtQuick
import Quickshell
import "../components"
import "../config"

Popout {
    id: root

    property date shown: new Date()

    readonly property date today: clock.date
    readonly property int shownYear: shown.getFullYear()
    readonly property int shownMonth: shown.getMonth()

    // Sunday-first offset of the 1st, and length of the shown month.
    readonly property int firstDow: new Date(shownYear, shownMonth, 1).getDay()
    readonly property int daysInMonth: new Date(shownYear, shownMonth + 1, 0).getDate()

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    onVisibleChanged: if (visible)
        shown = new Date()

    function shift(months: int): void {
        shown = new Date(shownYear, shownMonth + months, 1);
    }

    Column {
        spacing: 10

        // ── big clock ──────────────────────────────────────────────────
        Column {
            spacing: 0

            Text {
                text: Qt.formatDateTime(clock.date, "h:mm AP")
                color: Theme.fg
                font.family: Theme.font
                font.pixelSize: Theme.fontSizeDisplay
                font.bold: true
            }

            Text {
                text: Qt.formatDateTime(clock.date, "dddd, d MMMM yyyy")
                color: Theme.fgDim
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
            }
        }

        Rectangle {
            width: grid.width
            height: 1
            color: Theme.surface(Theme.rimAlpha)
        }

        // ── month header ───────────────────────────────────────────────
        Item {
            width: grid.width
            height: 22

            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                text: Qt.formatDate(root.shown, "MMMM yyyy")
                color: Theme.fg
                font.family: Theme.font
                font.pixelSize: Theme.fontSize
                font.bold: true
            }

            Row {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                spacing: 2

                Repeater {
                    model: [-1, 1]

                    delegate: Item {
                        id: nav

                        required property int modelData

                        width: 20
                        height: 20

                        Glass {
                            anchors.fill: parent
                            radius: 6
                            alpha: navHover.hovered ? Theme.surfaceHoverAlpha : 0.0
                            rim: navHover.hovered
                        }

                        Icon {
                            anchors.centerIn: parent
                            size: 12
                            source: Icons.chevron
                            // Dimming is opacity, not a darker color: the
                            // recolor path saturates lightness.
                            color: Theme.fg
                            opacity: navHover.hovered ? 0.9 : 0.5
                            rotation: nav.modelData < 0 ? 90 : -90
                        }

                        HoverHandler {
                            id: navHover
                        }

                        TapHandler {
                            onTapped: root.shift(nav.modelData)
                        }
                    }
                }
            }
        }

        // ── day-of-week header ─────────────────────────────────────────
        Row {
            Repeater {
                model: ["S", "M", "T", "W", "T", "F", "S"]

                delegate: Text {
                    required property string modelData
                    width: 26
                    horizontalAlignment: Text.AlignHCenter
                    text: modelData
                    color: Theme.fgDim
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSizeSmall
                    font.bold: true
                }
            }
        }

        // ── month grid ─────────────────────────────────────────────────
        // Hand-rolled rather than QtQuick.Controls MonthGrid: the Calendar
        // types moved between Qt versions and this has no such dependency.
        Grid {
            id: grid
            columns: 7

            Repeater {
                model: 42

                delegate: Item {
                    id: cell
                    required property int index

                    readonly property int dayNum: index - root.firstDow + 1
                    readonly property bool inMonth: dayNum >= 1 && dayNum <= root.daysInMonth
                    readonly property bool isToday: inMonth && dayNum === root.today.getDate() && root.shownMonth === root.today.getMonth() && root.shownYear === root.today.getFullYear()

                    width: 26
                    height: 24

                    Rectangle {
                        anchors.centerIn: parent
                        width: 22
                        height: 22
                        radius: 7
                        color: cell.isToday ? Theme.accent : Theme.transparent
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: cell.inMonth
                        text: cell.dayNum
                        color: cell.isToday ? Theme.base : Theme.fg
                        font.family: Theme.font
                        font.pixelSize: Theme.fontSize
                        font.bold: cell.isToday
                    }
                }
            }
        }
    }
}
