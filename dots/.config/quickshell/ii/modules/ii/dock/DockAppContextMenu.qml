import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland

PopupWindow {
    id: root

    required property var appToplevel
    required property var desktopEntry
    property var appListRoot: null

    color: "transparent"
    property real padding: Appearance.sizes.elevationMargin

    implicitWidth: popupBackground.implicitWidth + root.padding * 2
    implicitHeight: popupBackground.implicitHeight + root.padding * 2

    visible: true

    Component.onCompleted: {
        GlobalFocusGrab.addDismissable(root);
    }

    Component.onDestruction: {
        GlobalFocusGrab.removeDismissable(root);
    }

    Connections {
        target: GlobalFocusGrab
        function onDismissed() {
            root.closed();
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.BackButton | Qt.RightButton
        onPressed: event => {
            if (event.button === Qt.BackButton || event.button === Qt.RightButton) {
                root.closed();
            }
        }
    }

    StyledRectangularShadow {
        target: popupBackground
    }

    Rectangle {
        id: popupBackground
        readonly property real innerPadding: 4
        anchors.fill: parent
        anchors.margins: root.padding
        color: Appearance.colors.colLayer0
        radius: Appearance.rounding.windowRounding
        border.width: 1
        border.color: Appearance.colors.colLayer0Border
        clip: true

        property real offset: 15
        opacity: 0
        transform: Translate { y: popupBackground.offset }

        Component.onCompleted: {
            opacity = 1;
            offset = 0;
        }

        Behavior on opacity {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        Behavior on offset {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        implicitWidth: menuColumn.implicitWidth + popupBackground.innerPadding * 2
        implicitHeight: menuColumn.implicitHeight + popupBackground.innerPadding * 2

        ColumnLayout {
            id: menuColumn
            anchors.centerIn: parent
            spacing: 0

            // 1. App Desktop actions (e.g. New Window, Private Window)
            Repeater {
                model: root.desktopEntry?.actions ?? []
                delegate: MenuButton {
                    Layout.fillWidth: true
                    required property var modelData
                    buttonText: modelData.name
                    onClicked: {
                        modelData.execute();
                        root.closed();
                    }
                }
            }

            // Separator if there are actions and we have other options
            Rectangle {
                visible: (root.desktopEntry?.actions?.length ?? 0) > 0
                Layout.fillWidth: true
                Layout.topMargin: 4
                Layout.bottomMargin: 4
                implicitHeight: 1
                color: Appearance.colors.colLayer0Border
            }

            // 2. Pin/Unpin
            RippleButton {
                id: pinButton
                Layout.fillWidth: true
                buttonRadius: 0
                implicitHeight: 36
                implicitWidth: pinText.implicitWidth + 14 * 2 + 18 + 8

                onClicked: {
                    TaskbarApps.togglePin(root.appToplevel.appId);
                    root.closed();
                }

                contentItem: Item {
                    anchors.fill: parent

                    MaterialSymbol {
                        id: pinIcon
                        anchors.left: parent.left
                        anchors.leftMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        iconSize: 18
                        text: "push_pin"
                        color: pinButton.enabled ? Appearance.m3colors.m3onSurface : Appearance.m3colors.m3outline

                        Behavior on color {
                            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                        }
                    }

                    StyledText {
                        id: pinText
                        anchors.left: pinIcon.right
                        anchors.leftMargin: 8
                        anchors.right: parent.right
                        anchors.rightMargin: 14
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.appToplevel.pinned ? Translation.tr("Unpin from dock") : Translation.tr("Pin to dock")
                        font.pixelSize: Appearance.font.pixelSize.small
                        color: pinButton.enabled ? Appearance.m3colors.m3onSurface : Appearance.m3colors.m3outline
                        horizontalAlignment: Text.AlignLeft

                        Behavior on color {
                            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                        }
                    }
                }
            }

            // 3. Separator before close
            Rectangle {
                visible: root.appToplevel.toplevels.length > 0
                Layout.fillWidth: true
                Layout.topMargin: 4
                Layout.bottomMargin: 4
                implicitHeight: 1
                color: Appearance.colors.colLayer0Border
            }

            // 4. Close (only if there are running toplevels)
            MenuButton {
                visible: root.appToplevel.toplevels.length > 0
                Layout.fillWidth: true
                buttonText: Translation.tr("Close")
                onClicked: {
                    for (let toplevel of root.appToplevel.toplevels) {
                        toplevel.close();
                    }
                    root.closed();
                }
            }
        }
    }
}
