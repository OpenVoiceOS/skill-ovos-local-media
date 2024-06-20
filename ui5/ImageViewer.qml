// SPDX-FileCopyrightText: 2021 Aditya Mehra <aix.m@outlook.com>Kirigami
//
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import org.kde.kirigami 2.11 as Kirigami
import QtGraphicalEffects 1.0
import Mycroft 1.0 as Mycroft

Rectangle {
    id: imagePreview
    property bool opened: false
    color: Kirigami.Theme.backgroundColor
    visible: opened
    enabled: opened
    width: parent.width * 0.95
    height: parent.height * 0.95
    radius: 6
    property alias source: image.source
    layer.enabled: true
    layer.effect: DropShadow {
        horizontalOffset: 0
        verticalOffset: 0
        radius: 10
        color: "black"
        samples: 16
    }

    function open() {
        opened = true
    }

    function close() {
        opened = false
    }

    Item {
        anchors.fill: parent
        z: 100

        Image {
            id: image
            fillMode: Image.PreserveAspectFit
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: bottomBarOverlay.top
            smooth: true
        }

        Item {
            id: bottomBarOverlay
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: Mycroft.Units.gridUnit / 2
            anchors.rightMargin: Mycroft.Units.gridUnit / 2
            height: Mycroft.Units.gridUnit * 5

            Item {
                id: bottomBar
                anchors.right: closeButton.left
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom

                Label {
                    id: shareLabel
                    anchors.left: parent.left
                    anchors.leftMargin: Mycroft.Units.gridUnit / 2
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: shareLabel.implicitWidth
                    text: qsTr("Share") + ":"
                    color: Kirigami.Theme.textColor
                    Layout.fillHeight: true
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignLeft
                }

                ShareButton {
                    id: kdeConnectButton
                    anchors.left: shareLabel.right
                    anchors.leftMargin: Mycroft.Units.gridUnit / 2
                    width: parent.height - Mycroft.Units.gridUnit
                    height: parent.height - Mycroft.Units.gridUnit
                    anchors.verticalCenter: parent.verticalCenter
                    provider: Qt.resolvedUrl("images/share-kdeconnect.png")

                    onClicked: {
                        Mycroft.SoundEffects.playClickedSound(Qt.resolvedUrl("sounds/clicked.wav"))
                        imagePreview.close()
                        kdeConnectDevicesOverlay.open()
                    }
                }

                ShareButton {
                    id: bluetoothButton
                    anchors.left: kdeConnectButton.right
                    anchors.leftMargin: Mycroft.Units.gridUnit / 2
                    width: parent.height - Mycroft.Units.gridUnit
                    height: parent.height - Mycroft.Units.gridUnit
                    anchors.verticalCenter: parent.verticalCenter
                    enabled: false
                    visible: false
                    provider: Qt.resolvedUrl("images/share-bluetooth.svg")
                }
            }

            Button {
                id: closeButton
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                icon.name: "window-close"
                icon.color: Kirigami.Theme.textColor
                width: parent.height - Mycroft.Units.gridUnit
                height: parent.height - Mycroft.Units.gridUnit

                onClicked: {
                    Mycroft.SoundEffects.playClickedSound(Qt.resolvedUrl("sounds/clicked.wav"))
                    imagePreview.opened = false
                }
            }
        }
    }
}