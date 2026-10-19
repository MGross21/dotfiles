pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../components"
import "../config"
import "providers"

Item {
    id: root

    property var item
    readonly property var preview: root.item?.preview ?? null
    readonly property string kind: root.preview?.kind ?? ""
    readonly property string path: root.preview?.path ?? ""
    readonly property bool isImage: root.kind === "image" || root.kind === "file" && root.preview.fileKind === "image"
    property string fileText: ""

    onPathChanged: {
        root.fileText = "";
        if (root.kind === "file" && !root.isImage)
            peek.restart();
        else
            job.stop();
    }

    Timer {
        id: peek

        interval: 120
        onTriggered: {
            if (root.preview?.fileKind === "folder")
                job.start(["ls", "-1Ap", "--group-directories-first", root.path]);
            else
                job.start(["sh", "-c", 'file -b "$1"; echo; case "$(file -b --mime-type "$1")" in text/*|*json|*xml|*javascript|*x-shellscript|inode/x-empty) head -c 3000 "$1" ;; esac', "sh", root.path]);
        }
    }

    Job {
        id: job

        onDone: out => root.fileText = out
    }

    Glass {
        anchors.fill: parent
        radius: Theme.launcherRowRadius
        alpha: Theme.surfaceAlpha / 2
    }

    Column {
        id: header

        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: Theme.launcherPadding
        }
        spacing: Theme.gap * 2
        visible: root.kind !== "" && root.kind !== "window" && !root.isImage

        ItemIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            item: root.kind === "glyph" ? {
                glyph: root.preview.glyph
            } : root.kind === "generic" ? {
                icon: root.preview.icon
            } : root.item
            size: root.kind === "glyph" ? Theme.launcherPreviewIconSize * 1.4 : Theme.launcherPreviewIconSize
            color: Theme.fg
        }

        Text {
            width: parent.width
            text: root.preview?.title ?? root.item?.title ?? ""
            color: Theme.hi
            font.family: Theme.fontSans
            font.pixelSize: Theme.fontSizeHeading
            font.weight: Font.Bold
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            maximumLineCount: 3
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            visible: text !== ""
            text: {
                const p = root.preview;
                if (!p)
                    return "";
                if (p.kind === "app") {
                    const a = p.app;
                    return [a.genericName, a.comment, p.windows > 0 ? `${p.windows} open window${p.windows > 1 ? "s" : ""}` : ""].filter(s => s).join("\n\n");
                }
                if (p.kind === "file")
                    return p.path;
                return p.detail ?? root.item?.subtitle ?? "";
            }
            color: Theme.fg
            font.family: Theme.fontSans
            font.pixelSize: Theme.fontSize
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
        }
    }

    Flickable {
        anchors {
            top: header.visible ? header.bottom : parent.top
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            margins: Theme.launcherPadding
        }
        visible: body.text !== ""
        contentHeight: body.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Text {
            id: body

            width: parent.width
            text: {
                const p = root.preview;
                if (!p)
                    return "";
                if (p.kind === "app")
                    return [p.app.execString, p.app.categories.join(" · ")].filter(s => s).join("\n\n");
                if (p.kind === "file")
                    return root.fileText;
                if (p.kind === "text")
                    return p.text;
                return "";
            }
            color: Theme.inkDim
            font.family: Theme.font
            font.pixelSize: Theme.fontSizeSmall
            wrapMode: Text.WrapAnywhere
            textFormat: Text.PlainText
        }
    }

    Image {
        anchors {
            fill: parent
            margins: Theme.launcherPadding
        }
        visible: root.isImage
        source: root.isImage ? `file://${root.path}` : ""
        sourceSize: Qt.size(Theme.launcherPreviewWidth * 2, Theme.launcherPreviewWidth * 2)
        fillMode: Image.PreserveAspectFit
        asynchronous: true
    }

    Loader {
        anchors.fill: parent
        active: root.kind === "window" && root.preview.toplevel !== null

        sourceComponent: Item {
            ScreencopyView {
                id: shot

                anchors {
                    top: parent.top
                    topMargin: Theme.launcherPadding
                    horizontalCenter: parent.horizontalCenter
                }
                width: implicitWidth
                height: implicitHeight
                captureSource: root.preview.toplevel
                live: true
                constraintSize: Qt.size(parent.width - Theme.launcherPadding * 2, parent.height * 0.62)
            }

            Column {
                anchors {
                    top: shot.bottom
                    left: parent.left
                    right: parent.right
                    margins: Theme.launcherPadding
                }
                spacing: Theme.gap

                Text {
                    width: parent.width
                    text: root.preview.title
                    color: Theme.hi
                    font.family: Theme.fontSans
                    font.pixelSize: Theme.fontSizeLarge
                    font.weight: Font.Bold
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: `${root.preview.appId} · workspace ${root.preview.workspace}`
                    color: Theme.inkDim
                    font.family: Theme.font
                    font.pixelSize: Theme.fontSize
                    elide: Text.ElideRight
                }
            }
        }
    }
}
