// SPDX-FileCopyrightText: 2021 Aditya Mehra <aix.m@outlook.com>
//
// SPDX-License-Identifier: Apache-2.0

import QtQuick.Layouts 1.4
import QtQuick 2.12
import QtQuick.Controls 2.12 as Controls
import org.kde.kirigami 2.10 as Kirigami
import QtGraphicalEffects 1.0
import Mycroft 1.0 as Mycroft

Item {
    id: controlBarArea
    property bool opened: false
    property bool enabled: true
    property var mountPoint: ""
    property var operation: ""

    clip: true
    implicitWidth: parent.width
    implicitHeight: Mycroft.Units.gridUnit * 3
    opacity: opened

    Behavior on opacity {
        OpacityAnimator {
            duration: Kirigami.Units.longDuration
            easing.type: Easing.InOutCubic
        }
    }

    onOpenedChanged: {
        if (opened) {
            hideTimer.restart();
        }
    }
    
    Timer {
        id: hideTimer
        interval: 6000
        onTriggered: { 
            controlBarArea.opened = false;
        }
    }
    
    Rectangle {
        width: parent.width
        height: parent.height
        color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.9)
        y: opened ? 0 : parent.height

        Behavior on y {
            YAnimator {
                duration: Kirigami.Units.longDuration
                easing.type: Easing.OutCubic
            }
        }
        
        RowLayout {
            id: mainLayout
            anchors.fill: parent
            anchors.margins: Mycroft.Units.gridUnit / 2
            
            Controls.Label {
                id: mountMessage
                Layout.fillWidth: true
                Layout.fillHeight: true
                text: operation == "mounting" ? qsTr("Mounting %1").arg(mountPoint) + "..." + qsTr("Please wait") : qsTr("Unmounting %1").arg(mountPoint) + "..." + qsTr("Please wait")
                color: Kirigami.Theme.textColor
            }
        }
    }
}
