import qs
import qs.services
import qs.modules.common
import qs.modules.common.models
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Qt5Compat.GraphicalEffects

Item {
    id: root
    property bool vertical: false
    property bool borderless: Config.options.bar.borderless
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(root.QsWindow.window?.screen)
    readonly property Toplevel activeWindow: ToplevelManager.activeToplevel
    readonly property int effectiveActiveWorkspaceId: monitor?.activeWorkspace?.id ?? 1
    
    readonly property int workspacesShown: Config.options.bar.workspaces.shown
    readonly property int workspaceGroup: Math.floor((effectiveActiveWorkspaceId - 1) / root.workspacesShown)
    property list<bool> workspaceOccupied: []
    property int widgetPadding: 4
    property int workspaceButtonWidth: 26
    property real activeWorkspaceMargin: 2
    property real workspaceIconSize: workspaceButtonWidth * 0.69
    property real workspaceIconSizeShrinked: workspaceButtonWidth * 0.55
    property real workspaceIconOpacityShrinked: 1
    property real workspaceIconMarginShrinked: -4
    property int workspaceIndexInGroup: (effectiveActiveWorkspaceId - 1) % root.workspacesShown

    property bool showNumbers: false
    Timer {
        id: showNumbersTimer
        interval: (Config?.options.bar.autoHide.showWhenPressingSuper.delay ?? 100)
        repeat: false
        onTriggered: {
            root.showNumbers = true
        }
    }
    Connections {
        target: GlobalStates
        function onSuperDownChanged() {
            if (!Config?.options.bar.autoHide.showWhenPressingSuper.enable) return;
            if (GlobalStates.superDown) showNumbersTimer.restart();
            else {
                showNumbersTimer.stop();
                root.showNumbers = false;
            }
        }
        function onSuperReleaseMightTriggerChanged() { 
            showNumbersTimer.stop()
        }
    }

    // Function to update workspaceOccupied
    function updateWorkspaceOccupied() {
        workspaceOccupied = Array.from({ length: root.workspacesShown }, (_, i) => {
            return Hyprland.workspaces.values.some(ws => ws.id === workspaceGroup * root.workspacesShown + i + 1);
        })
    }

    // Occupied workspace updates
    Component.onCompleted: updateWorkspaceOccupied()
    Connections {
        target: Hyprland.workspaces
        function onValuesChanged() {
            updateWorkspaceOccupied();
        }
    }
    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() {
            updateWorkspaceOccupied();
        }
    }
    onWorkspaceGroupChanged: {
        updateWorkspaceOccupied();
    }

    implicitWidth: root.vertical ? Appearance.sizes.verticalBarWidth : bgGrid.width
    implicitHeight: root.vertical ? bgGrid.height : Appearance.sizes.barHeight

    function getPropInterpolated(idx, isPos) {
        if (idx < 0) return 0;
        let intIdx = Math.floor(idx);
        let frac = idx - intIdx;
        let item1 = bgRepeater.itemAt(intIdx);
        let item2 = bgRepeater.itemAt(intIdx + 1);
        
        if (!item1) return 0;
        
        let p1 = isPos ? (root.vertical ? item1.y : item1.x) : (root.vertical ? item1.height : item1.width);
        let p2 = p1;
        if (item2) {
            p2 = isPos ? (root.vertical ? item2.y : item2.x) : (root.vertical ? item2.height : item2.width);
        } else if (isPos) {
            p2 = p1 + (root.vertical ? item1.height : item1.width);
        }
        return p1 + frac * (p2 - p1);
    }

    // Scroll to switch workspaces
    WheelHandler {
        onWheel: (event) => {
            if (event.angleDelta.y < 0)
                Hyprland.dispatch(`workspace r+1`);
            else if (event.angleDelta.y > 0)
                Hyprland.dispatch(`workspace r-1`);
        }
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.BackButton
        onPressed: (event) => {
            if (event.button === Qt.BackButton) {
                Hyprland.dispatch(`togglespecialworkspace`);
            } 
        }
    }

    // Workspaces - Track Background (Unified)
    Rectangle {
        id: trackBg
        z: 0
        anchors.fill: bgGrid
        anchors.margins: -1
        radius: height / 2
        color: ColorUtils.transparentize(Appearance.colors.colLayer1, 0.2)
        border.color: ColorUtils.transparentize(Appearance.colors.colOutlineVariant, 0.1)
        border.width: root.borderless ? 0 : 1
    }

    // Workspaces - individual pills/circles
    Grid {
        id: bgGrid
        z: 1
        anchors.centerIn: parent

        rowSpacing: 4
        columnSpacing: 4
        columns: root.vertical ? 1 : root.workspacesShown
        rows: root.vertical ? root.workspacesShown : 1

        Repeater {
            id: bgRepeater
            model: root.workspacesShown

            Rectangle {
                z: 1
                property var workspaceWindows: HyprlandData.sortedWindowsForWorkspace(workspaceGroup * root.workspacesShown + index + 1)
                property int numWindows: workspaceWindows.length > 0 ? workspaceWindows.length : 1
                implicitWidth: root.vertical ? workspaceButtonWidth : (numWindows * workspaceButtonWidth)
                implicitHeight: root.vertical ? (numWindows * workspaceButtonWidth) : workspaceButtonWidth
                
                radius: (root.vertical ? width : height) / 2
                
                color: ColorUtils.transparentize(Appearance.m3colors.m3secondaryContainer, 0.4)
                opacity: (workspaceOccupied[index] && !(!activeWindow?.activated && root.effectiveActiveWorkspaceId === index+1)) ? 1 : 0

                Behavior on implicitWidth { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
                Behavior on implicitHeight { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
                Behavior on opacity { animation: Appearance.animation.elementMove.numberAnimation.createObject(this) }
            }

        }

    }

    // Active workspace
    Rectangle {
        z: 2
        radius: Appearance.rounding.full
        color: Appearance.colors.colPrimary

        anchors {
            verticalCenter: vertical ? undefined : parent.verticalCenter
            horizontalCenter: vertical ? parent.horizontalCenter : undefined
        }

        AnimatedTabIndexPair {
            id: idxPair
            index: root.workspaceIndexInGroup
        }

        property real forceEval: bgGrid.width + bgGrid.height
        property real pos1: { var __v = forceEval; return root.getPropInterpolated(idxPair.idx1, true); }
        property real pos2: { var __v = forceEval; return root.getPropInterpolated(idxPair.idx2, true); }
        property real size1: { var __v = forceEval; return root.getPropInterpolated(idxPair.idx1, false); }
        property real size2: { var __v = forceEval; return root.getPropInterpolated(idxPair.idx2, false); }

        property real indicatorPosition: Math.min(pos1, pos2) + root.activeWorkspaceMargin
        property real indicatorLength: Math.max(pos1 + size1, pos2 + size2) - Math.min(pos1, pos2) - root.activeWorkspaceMargin * 2
        property real indicatorThickness: workspaceButtonWidth - root.activeWorkspaceMargin * 2

        x: root.vertical ? null : indicatorPosition
        implicitWidth: root.vertical ? indicatorThickness : indicatorLength
        y: root.vertical ? indicatorPosition : null
        implicitHeight: root.vertical ? indicatorLength : indicatorThickness
    }

    // Workspaces - numbers
    Grid {
        z: 3

        columns: root.vertical ? 1 : root.workspacesShown
        rows: root.vertical ? root.workspacesShown : 1
        columnSpacing: 4
        rowSpacing: 4

        anchors.fill: parent

        Repeater {
            model: root.workspacesShown

            Item {
                id: workspaceItem
                property int workspaceValue: workspaceGroup * root.workspacesShown + index + 1
                property var workspaceWindows: HyprlandData.sortedWindowsForWorkspace(workspaceValue)
                property int numWindows: workspaceWindows.length > 0 ? workspaceWindows.length : 1
                
                implicitWidth: root.vertical ? Appearance.sizes.verticalBarWidth : (numWindows * workspaceButtonWidth)
                implicitHeight: root.vertical ? (numWindows * workspaceButtonWidth) : Appearance.sizes.barHeight

                Behavior on implicitWidth { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
                Behavior on implicitHeight { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }

                Button {
                    id: button
                    anchors.fill: parent
                    onPressed: Hyprland.dispatch(`workspace ${workspaceItem.workspaceValue}`)
                    
                    background: Item {
                        id: workspaceButtonBackground
                        implicitWidth: parent.width
                        implicitHeight: parent.height
                        property bool hasWindows: workspaceItem.workspaceWindows.length > 0
                        property bool showIcons: Config.options?.bar.workspaces.showAppIcons && hasWindows && !root.showNumbers

                        StyledText { // Workspace number text
                            opacity: (root.showNumbers || (Config.options?.bar.workspaces.alwaysShowNumbers && !workspaceButtonBackground.showIcons)) ? 1 : 0
                            z: 3

                            anchors.centerIn: parent
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font {
                                pixelSize: Appearance.font.pixelSize.small - ((text.length - 1) * (text !== "10") * 2)
                                family: Config.options?.bar.workspaces.useNerdFont ? Appearance.font.family.iconNerd : defaultFont
                            }
                            text: Config.options?.bar.workspaces.numberMap[workspaceItem.workspaceValue - 1] || workspaceItem.workspaceValue
                            elide: Text.ElideRight
                            color: (root.effectiveActiveWorkspaceId == workspaceItem.workspaceValue) ? 
                                Appearance.m3colors.m3onPrimary : 
                                (workspaceOccupied[index] ? Appearance.m3colors.m3onSecondaryContainer : 
                                    Appearance.colors.colOnLayer1Inactive)

                            Behavior on opacity {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                            }
                        }
                        Rectangle { // Dot instead of ws number
                            id: wsDot
                            opacity: (root.showNumbers || workspaceButtonBackground.showIcons || Config.options?.bar.workspaces.alwaysShowNumbers) ? 0 : 1
                            visible: opacity > 0
                            anchors.centerIn: parent
                            width: workspaceButtonWidth * 0.18
                            height: width
                            radius: width / 2
                            color: (root.effectiveActiveWorkspaceId == workspaceItem.workspaceValue) ? 
                                Appearance.m3colors.m3onPrimary : 
                                (workspaceOccupied[index] ? Appearance.m3colors.m3onSecondaryContainer : 
                                    Appearance.colors.colOnLayer1Inactive)

                            Behavior on opacity {
                                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                            }
                        }
                    }
                }

                // Interaction / Icon Overlay
                Item {
                    anchors.fill: parent
                    z: 5 // Ensure it's on top of the button's internal MouseArea
                    property bool hasWindows: workspaceItem.workspaceWindows.length > 0

                    // App icons
                    Grid {
                        anchors.centerIn: parent
                        columns: root.vertical ? 1 : workspaceItem.numWindows
                        rows: root.vertical ? workspaceItem.numWindows : 1
                        spacing: 0
                        opacity: workspaceButtonBackground.showIcons ? 1 : 0
                        visible: opacity > 0

                        Behavior on opacity {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }

                        Repeater {
                            model: workspaceItem.workspaceWindows
                            
                            Item {
                                width: workspaceButtonWidth
                                height: workspaceButtonWidth

                                property var windowRef: modelData
                                property string mainAppIconSource: {
                                    if (!windowRef) return "";
                                    const icon = AppSearch.guessWindowIcon(windowRef);
                                    if (icon.startsWith("file://") || icon.startsWith("/")) {
                                        const path = icon.startsWith("/") ? "file://" + icon : icon;
                                        return Qt.resolvedUrl(path);
                                    }
                                    return Quickshell.iconPath(icon, "image-missing");
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (windowRef && windowRef.address) {
                                            let addr = windowRef.address;
                                            if (!addr.startsWith("0x")) addr = "0x" + addr;
                                            Hyprland.dispatch(`focuswindow address:${addr}`);
                                        }
                                    }
                                }

                                IconImage {
                                    id: mainAppIcon
                                    anchors.bottom: parent.bottom
                                    anchors.right: parent.right
                                    anchors.bottomMargin: (!root.showNumbers && Config.options?.bar.workspaces.showAppIcons) ? 
                                        (workspaceButtonWidth - workspaceIconSize) / 2 : workspaceIconMarginShrinked
                                    anchors.rightMargin: (!root.showNumbers && Config.options?.bar.workspaces.showAppIcons) ? 
                                        (workspaceButtonWidth - workspaceIconSize) / 2 : workspaceIconMarginShrinked

                                    source: mainAppIconSource
                                    implicitSize: (!root.showNumbers && Config.options?.bar.workspaces.showAppIcons) ? workspaceIconSize : workspaceIconSizeShrinked

                                    Behavior on anchors.bottomMargin {
                                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                                    }
                                    Behavior on anchors.rightMargin {
                                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                                    }
                                    Behavior on implicitSize {
                                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                                    }
                                }

                                Loader {
                                    active: Config.options.bar.workspaces.monochromeIcons
                                    anchors.fill: mainAppIcon
                                    sourceComponent: Item {
                                        Desaturate {
                                            id: desaturatedIcon
                                            visible: false // There's already color overlay
                                            anchors.fill: parent
                                            source: mainAppIcon
                                            desaturation: 0.8
                                        }
                                        ColorOverlay {
                                            anchors.fill: desaturatedIcon
                                            source: desaturatedIcon
                                            color: ColorUtils.transparentize((root.effectiveActiveWorkspaceId == workspaceItem.workspaceValue) ? Appearance.m3colors.m3onPrimary : wsDot.color, 0.2)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Separator
                    Rectangle {
                        visible: index !== root.workspacesShown - 1
                        color: Appearance.colors.colOutlineVariant
                        anchors.right: root.vertical ? undefined : parent.right
                        anchors.bottom: root.vertical ? parent.bottom : undefined
                        anchors.verticalCenter: root.vertical ? undefined : parent.verticalCenter
                        anchors.horizontalCenter: root.vertical ? parent.horizontalCenter : undefined
                        anchors.rightMargin: root.vertical ? 0 : -2.5
                        anchors.bottomMargin: root.vertical ? -2.5 : 0
                        
                        width: root.vertical ? 10 : 1
                        height: root.vertical ? 1 : 10
                        opacity: 0.3
                    }
                }
            }
        }
    }

}
