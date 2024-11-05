// SPDX-FileCopyrightText: 2021 Aditya Mehra <aix.m@outlook.com>
//
// SPDX-License-Identifier: Apache-2.0

import QtQuick 2.12
import QtQuick.Controls 2.12 as Controls
import QtQuick.Layouts 1.12
import Mycroft 1.0 as Mycroft
import org.kde.kirigami 2.11 as Kirigami
import Qt.labs.folderlistmodel 2.12
import OVOSPlugin 1.0 as OVOSPlugin
import "." as Local


Mycroft.Delegate {
    id: root
    fillWidth: true
    topPadding: 0
    bottomPadding: 0
    leftPadding: 0
    rightPadding: 0

    background: Rectangle {
        color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.3)
    }

    controlBar: Local.ControllerArea {
        id: controllerArea
        anchors {
            bottom: parent.bottom
        }
        z: 4
    }

    Connections {
        target: OVOSPlugin.PlacesModel

        onPlaceMounted: {
            controlBarItem.opened = false
            browserStackLayout.device = {
                "path": path,
                "deviceIndex": index,
                "deviceRemovable": removable,
                "deviceSystem": system,
                "literalPath": literalPath
            }
            browserStackLayout.currentIndex = 1

        }
        onPlaceUnmounted: {
            controlBarItem.opened = false
            browserStackLayout.device = {
                "path": path,
                "deviceIndex": index,
                "deviceRemovable": removable,
                "deviceSystem": system,
                "literalPath": literalPath
            }
            browserStackLayout.currentIndex = 0
        }
    }

    StackLayout {
        id: browserStackLayout
        width: parent.width
        height: parent.height
        currentIndex: 0
        property var device
        z: 80

        function showNotification(path, mode) {
            controlBarItem.mountPoint = path
            controlBarItem.operation = mode
            controlBarItem.opened = !controlBarItem.opened
        }

        PlacesView {
            id: placesView
        }

        BrowserView {
            id: browserView
            device: browserStackLayout.device
        }
    }
}
