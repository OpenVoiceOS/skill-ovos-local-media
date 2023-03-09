
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

Item {
    id: placesView
    property bool horizontalMode: width > height ? 1 : 0

    Rectangle {
        id: headerArea
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: Mycroft.Units.gridUnit * 3
        color: Kirigami.Theme.highlightColor

        RowLayout {
            anchors.fill: parent
            anchors.margins: Mycroft.Units.gridUnit / 2
            spacing: Mycroft.Units.gridUnit / 2

            Kirigami.Icon {
                source: "folder-symbolic"
                Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
            }

            Controls.Label {
                text: "File Browser"
                Layout.fillWidth: true
                Layout.fillHeight: true
                horizontalAlignment: Text.AlignLeft
                verticalAlignment: Text.AlignVCenter
                Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                elide: Text.ElideRight
                font.bold: true
                font.pixelSize: headerArea.height / 2
            }
        }

        Kirigami.Separator {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 1
            color: Kirigami.Theme.textColor
        }
    }

    Controls.ScrollBar {
        id: placesScrollBar
        anchors.right: parent.right
        anchors.top: headerArea.bottom
        anchors.bottom: parent.bottom
        width: Mycroft.Units.gridUnit * 2
    }

    Flickable {
        id: placesFlickable
        anchors.top: headerArea.bottom
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: placesScrollBar.left
        anchors.margins: Mycroft.Units.gridUnit
        contentWidth: width
        contentHeight: placesGridLayout.implicitHeight
        clip: true
        Controls.ScrollBar.vertical: placesScrollBar

        GridLayout {
            id: placesGridLayout
            width: parent.width
            height: parent.height
            columns: horizontalMode ? 3 : 1
            rows: Math.ceil(placesModelRepeater.count / columns)

            Repeater {
                id: placesModelRepeater
                model: OVOSPlugin.PlacesModel
                delegate: Controls.Button {
                    id: placesSelectionButton
                    Layout.fillWidth: true
                    Layout.preferredHeight: Mycroft.Units.gridUnit * 4

                    background: Rectangle {
                        color: model.isMounted ? Kirigami.Theme.backgroundColor : Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, 0.5)
                        border.width: 1
                        border.color: Kirigami.Theme.textColor
                        radius: 6
                    }

                    contentItem: Item {
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Mycroft.Units.gridUnit / 2
                            spacing: Mycroft.Units.gridUnit / 2

                            Kirigami.Icon {
                                source: model.icon
                            }

                            Controls.Label {
                                text: model.name
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                                elide: Text.ElideRight
                            }
                        }
                    }

                    onClicked: {
                        Mycroft.SoundEffects.playClickedSound(Qt.resolvedUrl("sounds/clicked.wav"))
                        if(model.isMounted) {
                            placesView.parent.currentIndex = 1
                            placesView.parent.device = {
                                "path": model.path,
                                "deviceIndex": index,
                                "deviceRemovable": model.isRemovable,
                                "deviceSystem": model.isSystem,
                                "literalPath": model.literalPath
                            }
                        } else {
                            placesView.parent.showNotification(model.name, "mounting")
                            OVOSPlugin.PlacesModel.mount(index)
                        }
                    }
                }
            }
        }
    }
}
