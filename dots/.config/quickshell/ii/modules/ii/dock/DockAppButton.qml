import qs.services
import qs.modules.common
import qs.modules.common.functions
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Hyprland

DockButton {
    id: root
    property var appToplevel
    property var appListRoot
    property int lastFocused: -1
    property real iconSize: 35
    property real countDotWidth: 10
    property real countDotHeight: 4
    property bool appIsActive: appToplevel.toplevels.find(t => (t.activated == true)) !== undefined

    readonly property bool isSeparator: appToplevel.appId === "SEPARATOR"
    property var desktopEntry: DesktopEntries.heuristicLookup(appToplevel.appId)
    enabled: !isSeparator
    implicitWidth: isSeparator ? 1 : implicitHeight - topInset - bottomInset

    Connections {
        target: DesktopEntries

        function onApplicationsChanged() {
            root.desktopEntry = DesktopEntries.heuristicLookup(appToplevel.appId);
        }
    }

    Loader {
        active: isSeparator
        anchors {
            fill: parent
            topMargin: dockVisualBackground.margin + dockRow.padding + Appearance.rounding.normal
            bottomMargin: dockVisualBackground.margin + dockRow.padding + Appearance.rounding.normal
        }
        sourceComponent: DockSeparator {}
    }

    Loader {
        anchors.fill: parent
        active: appToplevel.toplevels.length > 0
        sourceComponent: MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            onEntered: {
                appListRoot.lastHoveredButton = root
                appListRoot.buttonHovered = true
                lastFocused = appToplevel.toplevels.length - 1
            }
            onExited: {
                if (appListRoot.lastHoveredButton === root) {
                    appListRoot.buttonHovered = false
                }
            }
        }
    }

    function launchOrCycle() {
        if (appToplevel.toplevels.length === 0) {
            root.desktopEntry?.execute();
            return;
        }
        lastFocused = (lastFocused + 1) % appToplevel.toplevels.length
        const toplevel = appToplevel.toplevels[lastFocused];
        const client = HyprlandData.clientForToplevel(toplevel);
        if (client) {
            Quickshell.execDetached([Quickshell.shellPath("scripts/hyprland/restore_window.sh"), client.address]);
        } else {
            toplevel.activate();
        }
    }

    opacity: !root.enabled ? 0.4
        : (appListRoot.dragging && appListRoot.draggedAppId === appToplevel.appId) ? 0.3
        : 1.0
    Behavior on opacity {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    DropArea {
        id: dropArea
        anchors.fill: parent
        enabled: !root.isSeparator && appListRoot.dragging

        function handleDrop(drag) {
            if (!appListRoot.dragging) return;
            if (appListRoot.draggedAppId === root.appToplevel.appId) return;
            if (appListRoot.draggedPinned !== root.appToplevel.pinned) return;
            const dropBefore = drag.x < width / 2;
            appListRoot.reorder(appListRoot.draggedAppId, appListRoot.draggedPinned, root.appToplevel.appId, dropBefore);
        }
        onEntered: drag => handleDrop(drag)
        onPositionChanged: drag => handleDrop(drag)
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        drag.target: root.isSeparator ? null : appListRoot.ghostItem
        drag.axis: Drag.XAndYAxis
        drag.threshold: 8

        onPressed: mouse => {
            if (root.isSeparator) return;
            const ghost = appListRoot.ghostItem;
            const pos = appListRoot.mapFromItem(dragArea, mouse.x, mouse.y);
            ghost.x = pos.x - ghost.width / 2;
            ghost.y = pos.y - ghost.height / 2;
        }
        onPositionChanged: mouse => {
            if (dragArea.drag.active && !appListRoot.dragging && !root.isSeparator) {
                appListRoot.beginDrag(root.appToplevel.appId, root.appToplevel.pinned);
            }
        }
        // Qt suppresses this after a drag, so it only fires for genuine clicks.
        onClicked: mouse => root.launchOrCycle()
        onReleased: () => {
            if (appListRoot.dragging) appListRoot.endDrag();
        }
        onCanceled: () => {
            if (appListRoot.dragging) appListRoot.endDrag();
        }
    }

    middleClickAction: () => {
        root.desktopEntry?.execute();
    }

    altAction: () => {
        contextMenuLoader.active = true;
    }

    Loader {
        id: contextMenuLoader
        active: false
        onActiveChanged: {
            appListRoot.contextMenuOpen = active;
        }
        sourceComponent: DockAppContextMenu {
            appToplevel: root.appToplevel
            desktopEntry: root.desktopEntry
            appListRoot: root.appListRoot
            anchor {
                window: root.QsWindow.window
                item: root
                gravity: Edges.Top | Edges.Right
                edges: Edges.Top | Edges.Left
            }
            onClosed: {
                contextMenuLoader.active = false;
            }
        }
    }

    contentItem: Loader {
        active: !isSeparator
        sourceComponent: Item {
            anchors.centerIn: parent

            Loader {
                id: iconImageLoader
                anchors {
                    left: parent.left
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                }
                active: !root.isSeparator
                sourceComponent: IconImage {
                    source: Quickshell.iconPath(AppSearch.guessIcon(appToplevel.appId), "image-missing")
                    implicitSize: root.iconSize
                }
            }

            Loader {
                active: Config.options.dock.monochromeIcons
                anchors.fill: iconImageLoader
                sourceComponent: Item {
                    Desaturate {
                        id: desaturatedIcon
                        visible: false // There's already color overlay
                        anchors.fill: parent
                        source: iconImageLoader
                        desaturation: 0.8
                    }
                    ColorOverlay {
                        anchors.fill: desaturatedIcon
                        source: desaturatedIcon
                        color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.9)
                    }
                }
            }

            RowLayout {
                spacing: 3
                anchors {
                    top: iconImageLoader.bottom
                    topMargin: 2
                    horizontalCenter: parent.horizontalCenter
                }
                Repeater {
                    model: Math.min(appToplevel.toplevels.length, 3)
                    delegate: Rectangle {
                        required property int index
                        radius: Appearance.rounding.full
                        implicitWidth: (appToplevel.toplevels.length <= 3) ? 
                            root.countDotWidth : root.countDotHeight // Circles when too many
                        implicitHeight: root.countDotHeight
                        color: appIsActive ? Appearance.colors.colPrimary : ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.4)
                    }
                }
            }
        }
    }
}
