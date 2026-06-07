pragma ComponentBehavior: Bound
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions

Item {
    id: root
    property real maxWindowPreviewHeight: 200
    property real maxWindowPreviewWidth: 300
    property real windowControlsHeight: 30
    property real buttonPadding: 5

    property Item lastHoveredButton: null
    property bool buttonHovered: false
    property bool contextMenuOpen: false
    property bool requestDockShow: previewPopup.show || contextMenuOpen

    property int monitorId: 0
    property var unpinnedAppOrder: []

    property list<var> filteredApps: {
        const _trigger1 = ToplevelManager.toplevels.values;
        const _trigger2 = HyprlandData.windowList;
        const _trigger3 = Config.options?.dock.pinnedApps;
        const _trigger4 = root.unpinnedAppOrder;

        const monitorWindows = [];
        for (const toplevel of ToplevelManager.toplevels.values) {
            const client = HyprlandData.clientForToplevel(toplevel);
            if (client && client.monitor === root.monitorId) {
                monitorWindows.push({ toplevel: toplevel, client: client });
            }
        }

        const pinnedApps = Config.options?.dock.pinnedApps ?? [];
        const pinnedEntries = [];
        const runningAppIdsOnThisMonitor = new Set();

        for (const appId of pinnedApps) {
            const appIdLower = appId.toLowerCase();
            const appToplevels = monitorWindows
                .filter(mw => mw.toplevel.appId.toLowerCase() === appIdLower)
                .map(mw => mw.toplevel);

            pinnedEntries.push({
                appId: appIdLower,
                pinned: true,
                toplevels: appToplevels
            });
            runningAppIdsOnThisMonitor.add(appIdLower);
        }

        const unpinnedEntries = [];
        for (const mw of monitorWindows) {
            const appIdLower = mw.toplevel.appId.toLowerCase();
            if (runningAppIdsOnThisMonitor.has(appIdLower)) {
                continue;
            }

            if (unpinnedEntries.some(e => e.appId === appIdLower)) {
                continue;
            }

            const appToplevels = monitorWindows
                .filter(mw2 => mw2.toplevel.appId.toLowerCase() === appIdLower)
                .map(mw2 => mw2.toplevel);

            unpinnedEntries.push({
                appId: appIdLower,
                pinned: false,
                toplevels: appToplevels
            });
        }

        // Sort unpinned entries according to root.unpinnedAppOrder
        const orderMap = {};
        const currentOrder = root.unpinnedAppOrder || [];
        for (let i = 0; i < currentOrder.length; i++) {
            orderMap[currentOrder[i]] = i;
        }

        unpinnedEntries.sort((a, b) => {
            const idxA = orderMap[a.appId] !== undefined ? orderMap[a.appId] : 999999;
            const idxB = orderMap[b.appId] !== undefined ? orderMap[b.appId] : 999999;
            if (idxA !== idxB) {
                return idxA - idxB;
            }
            return a.appId.localeCompare(b.appId);
        });

        // Synchronize root.unpinnedAppOrder
        let needsUpdate = false;
        let newOrder = currentOrder.slice();
        newOrder = newOrder.filter(appId => unpinnedEntries.some(e => e.appId === appId));
        if (newOrder.length !== currentOrder.length) {
            needsUpdate = true;
        }

        for (const entry of unpinnedEntries) {
            if (newOrder.indexOf(entry.appId) === -1) {
                newOrder.push(entry.appId);
                needsUpdate = true;
            }
        }

        if (needsUpdate) {
            Qt.callLater(() => {
                root.unpinnedAppOrder = newOrder;
            });
        }

        const result = [];
        for (const entry of pinnedEntries) {
            result.push(entry);
        }

        if (pinnedEntries.length > 0 && unpinnedEntries.length > 0) {
            result.push({
                appId: "SEPARATOR",
                pinned: false,
                toplevels: []
            });
        }

        for (const entry of unpinnedEntries) {
            result.push(entry);
        }

        return result;
    }

    function canMoveLeft(appId, isPinned) {
        const appIdLower = appId.toLowerCase();
        if (isPinned) {
            const pinnedApps = Config.options?.dock.pinnedApps ?? [];
            const idx = pinnedApps.findIndex(id => id.toLowerCase() === appIdLower);
            return idx > 0;
        } else {
            const idx = unpinnedAppOrder.indexOf(appIdLower);
            return idx > 0;
        }
    }

    function canMoveRight(appId, isPinned) {
        const appIdLower = appId.toLowerCase();
        if (isPinned) {
            const pinnedApps = Config.options?.dock.pinnedApps ?? [];
            const idx = pinnedApps.findIndex(id => id.toLowerCase() === appIdLower);
            return idx !== -1 && idx < pinnedApps.length - 1;
        } else {
            const idx = unpinnedAppOrder.indexOf(appIdLower);
            return idx !== -1 && idx < unpinnedAppOrder.length - 1;
        }
    }

    function moveLeft(appId, isPinned) {
        const appIdLower = appId.toLowerCase();
        if (isPinned) {
            let pinnedApps = (Config.options?.dock.pinnedApps ?? []).slice();
            const idx = pinnedApps.findIndex(id => id.toLowerCase() === appIdLower);
            if (idx > 0) {
                const temp = pinnedApps[idx];
                pinnedApps[idx] = pinnedApps[idx - 1];
                pinnedApps[idx - 1] = temp;
                Config.options.dock.pinnedApps = pinnedApps;
            }
        } else {
            let newOrder = unpinnedAppOrder.slice();
            const idx = newOrder.indexOf(appIdLower);
            if (idx > 0) {
                const temp = newOrder[idx];
                newOrder[idx] = newOrder[idx - 1];
                newOrder[idx - 1] = temp;
                unpinnedAppOrder = newOrder;
            }
        }
    }

    function moveRight(appId, isPinned) {
        const appIdLower = appId.toLowerCase();
        if (isPinned) {
            let pinnedApps = (Config.options?.dock.pinnedApps ?? []).slice();
            const idx = pinnedApps.findIndex(id => id.toLowerCase() === appIdLower);
            if (idx !== -1 && idx < pinnedApps.length - 1) {
                const temp = pinnedApps[idx];
                pinnedApps[idx] = pinnedApps[idx + 1];
                pinnedApps[idx + 1] = temp;
                Config.options.dock.pinnedApps = pinnedApps;
            }
        } else {
            let newOrder = unpinnedAppOrder.slice();
            const idx = newOrder.indexOf(appIdLower);
            if (idx !== -1 && idx < newOrder.length - 1) {
                const temp = newOrder[idx];
                newOrder[idx] = newOrder[idx + 1];
                newOrder[idx + 1] = temp;
                unpinnedAppOrder = newOrder;
            }
        }
    }

    Layout.fillHeight: true
    Layout.topMargin: Appearance.sizes.hyprlandGapsOut
    implicitWidth: listView.implicitWidth

    function popupCenterXForButton(button) {
        if (!button || !root.QsWindow)
            return 0;
        return root.QsWindow.mapFromItem(button, button.width / 2, 0).x;
    }

    StyledListView {
        id: listView
        spacing: 2
        orientation: ListView.Horizontal
        anchors {
            top: parent.top
            bottom: parent.bottom
        }
        implicitWidth: contentWidth

        Behavior on implicitWidth {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        model: ScriptModel {
            objectProp: "appId"
            values: root.filteredApps
        }
        delegate: DockAppButton {
            required property var modelData
            appToplevel: modelData
            appListRoot: root

            topInset: Appearance.sizes.hyprlandGapsOut + root.buttonPadding
            bottomInset: Appearance.sizes.hyprlandGapsOut + root.buttonPadding
        }
    }

    PopupWindow {
        id: previewPopup
        property var appTopLevel: root.lastHoveredButton?.appToplevel

        property bool shouldShow: (popupMouseArea.containsMouse || root.buttonHovered) && appTopLevel && appTopLevel.toplevels && appTopLevel.toplevels.length > 0

        property bool show: false
        property real cachedCenterX: 0

        Connections {
            target: root
            function onLastHoveredButtonChanged() {
                if (root.lastHoveredButton && root.QsWindow)
                    previewPopup.cachedCenterX = root.popupCenterXForButton(root.lastHoveredButton);
            }
            function onButtonHoveredChanged() {
                if (root.buttonHovered && root.lastHoveredButton && root.QsWindow)
                    previewPopup.cachedCenterX = root.popupCenterXForButton(root.lastHoveredButton);
                updateTimer.restart();
            }
        }

        onShouldShowChanged: {
            updateTimer.restart();
        }

        Timer {
            id: updateTimer
            interval: 100
            onTriggered: {
                previewPopup.show = previewPopup.shouldShow;
            }
        }

        anchor {
            window: root.QsWindow.window
            adjustment: PopupAdjustment.None
            gravity: Edges.Top | Edges.Right
            edges: Edges.Top | Edges.Left
        }

        visible: popupBackground.opacity > 0
        color: "transparent"
        implicitWidth: root.QsWindow.window?.width ?? 1
        implicitHeight: popupMouseArea.implicitHeight + root.windowControlsHeight + Appearance.sizes.elevationMargin * 2

        MouseArea {
            id: popupMouseArea
            anchors.bottom: parent.bottom
            implicitWidth: popupBackground.implicitWidth + Appearance.sizes.elevationMargin * 2
            implicitHeight: root.maxWindowPreviewHeight + root.windowControlsHeight + Appearance.sizes.elevationMargin * 2
            hoverEnabled: true
            x: previewPopup.cachedCenterX - width / 2

            StyledRectangularShadow {
                target: popupBackground
                opacity: previewPopup.show ? 1 : 0
                visible: opacity > 0
                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }

            Rectangle {
                id: popupBackground
                property real padding: 5
                opacity: previewPopup.show ? 1 : 0
                visible: opacity > 0
                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                clip: true
                color: Appearance.m3colors.m3surfaceContainer
                radius: Appearance.rounding.normal
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Appearance.sizes.elevationMargin
                anchors.horizontalCenter: parent.horizontalCenter
                implicitHeight: previewRowLayout.implicitHeight + padding * 2
                implicitWidth: previewRowLayout.implicitWidth + padding * 2
                Behavior on implicitWidth {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                Behavior on implicitHeight {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }

                RowLayout {
                    id: previewRowLayout
                    anchors.centerIn: parent
                    Repeater {
                        model: ScriptModel {
                            values: previewPopup.appTopLevel?.toplevels ?? []
                        }
                        RippleButton {
                            id: windowButton
                            Layout.fillHeight: true
                            required property var modelData
                            padding: 0
                            middleClickAction: () => {
                                windowButton.modelData?.close();
                            }
                            onClicked: {
                                const toplevel = windowButton.modelData;
                                if (toplevel) {
                                    const client = HyprlandData.clientForToplevel(toplevel);
                                    if (client && (client.workspace.id === -99 || client.workspace.name.indexOf("special") === 0)) {
                                        toplevel.activate();
                                        Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.window.move({ workspace = \"e+0\" })"]);
                                    } else {
                                        toplevel.activate();
                                    }
                                }
                            }
                            contentItem: ColumnLayout {
                                implicitWidth: screencopyView.implicitWidth
                                implicitHeight: screencopyView.implicitHeight

                                ButtonGroup {
                                    contentWidth: parent.width - anchors.margins * 2
                                    StyledText {
                                        Layout.margins: 5
                                        Layout.fillWidth: true
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        text: windowButton.modelData?.title
                                        elide: Text.ElideRight
                                        color: Appearance.m3colors.m3onSurface
                                    }
                                    GroupButton {
                                        id: closeButton
                                        colBackground: ColorUtils.transparentize(Appearance.colors.colSurfaceContainer)
                                        baseWidth: root.windowControlsHeight
                                        baseHeight: root.windowControlsHeight
                                        buttonRadius: Appearance.rounding.full
                                        contentItem: MaterialSymbol {
                                            anchors.centerIn: parent
                                            horizontalAlignment: Text.AlignHCenter
                                            text: "close"
                                            iconSize: Appearance.font.pixelSize.normal
                                            color: Appearance.m3colors.m3onSurface
                                        }
                                        onClicked: {
                                            windowButton.modelData?.close();
                                        }
                                    }
                                }
                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    implicitHeight: screencopyView.height
                                    implicitWidth: screencopyView.width
                                    ScreencopyView {
                                        id: screencopyView
                                        anchors.centerIn: parent
                                        captureSource: windowButton.modelData
                                        live: true
                                        paintCursor: true
                                        constraintSize: Qt.size(root.maxWindowPreviewWidth, root.maxWindowPreviewHeight)
                                        layer.enabled: true
                                        layer.effect: OpacityMask {
                                            maskSource: Rectangle {
                                                width: screencopyView.width
                                                height: screencopyView.height
                                                radius: Appearance.rounding.small
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
