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
    id: browserView
    property var device
    property bool internalSystemCheck: device ? OVOSPlugin.PlacesModel.hasHintSystem(device.literalPath) : false
    property bool deviceSystem: device ? device.deviceSystem : false
    property alias currentFolder: folderModel.folder
    property bool horizontalMode: width > height ? 1 : 0

    function getFileType(file) {
        // Based on the file extension, return the file type
        var extension = file.toString().split(".").pop().toLowerCase()
        var audioTypes = ["aac", "ac3", "aiff", "amr", "ape", "au", "flac", "m4a", "m4b", "m4p", "mid", "mp2", "mp3", "mpc", "oga", "ogg", "opus", "ra", "wav", "wma"]
        var videoTypes = ["3g2", "3gp", "3gpp", "asf", "avi", "flv", "m2ts", "mkv", "mov", "mp4", "mpeg", "mpg", "mts", "ogm", "ogv", "qt", "rm", "vob", "webm", "wmv"]
        var imageTypes = ["png", "jpg", "jpeg", "gif", "bmp", "ppm", "tiff", "svg"]
         
        if (audioTypes.indexOf(extension) > -1) {
            return "audio"
        } else if (videoTypes.indexOf(extension) > -1) {
            return "video"
        } else if (imageTypes.indexOf(extension) > -1) {
            return "image"
        } else {
            return "other"
        }
    }

    function getFileThumbnail(type, file) {
        if (type == "audio") {
            return "audio-x-generic"
        } else if (type == "video") {
            return "video-x-generic"
        } else if (type == "image") {
            // remove file:// from the path
            var path = file.toString().replace("file://", "")
            return Qt.resolvedUrl("file://" + path)
        } else {
            return "text-x-generic"
        }
    }

    function shareFile(deviceID) {
        triggerGuiEvent("file.kdeconnect.send", {"file": imageViewer.source, "deviceID": deviceID})
    }

    onDeviceChanged: {
        if(device) {
            browserView.internalSystemCheck = OVOSPlugin.PlacesModel.hasHintSystem(device.literalPath)

            if(device.path == "/") {
                browserView.currentFolder = "file://../"
                pathTextArea.text = "/"
            } else if(device.path == "/boot/efi") {
                browserView.currentFolder = "file:///boot/"
                pathTextArea.text = folderModel.folder.toString().replace("file://", "")
            } else {
                if(device.path != ""){
                    browserView.currentFolder = "file://" + device.path
                    pathTextArea.text = folderModel.folder.toString().replace("file://", "")
                }
            }
        }
    }

    FolderListModel {
        id: folderModel
        folder: Qt.resolvedUrl("file://tmp/")
        rootFolder: Qt.resolvedUrl("file://../")
        showDirs: true
        showFiles: false
        showDotAndDotDot: true
        sortCaseSensitive: false
        nameFilters: [".*"]

        onStatusChanged: {
            if(folderModel.status == FolderListModel.Ready) {
                fileModel.folder = folderModel.folder
            }
        }
    }

    FolderListModel {
        id: fileModel
        showDirs: false
        showDotAndDotDot: false
        showOnlyReadable: true
        sortCaseSensitive: false
        nameFilters: ["*.3g2", "*.3gp", "*.3gpp", "*.asf", "*.avi", "*.flv", "*.m2ts", "*.mkv", "*.mov", "*.mp4", "*.mpeg", "*.mpg", "*.mts", "*.ogm", "*.ogv", "*.qt", "*.rm", "*.vob", "*.webm", "*.wmv", "*.aac", "*.ac3", "*.aiff", "*.amr", "*.ape", "*.au", "*.flac", "*.m4a", "*.m4b", "*.m4p", "*.mid", "*.mp2", "*.mp3", "*.mpc", "*.oga", "*.ogg", "*.opus", "*.ra", "*.wav", "*.wma", "*.png", "*.jpg", "*.jpeg", "*.gif", "*.bmp", "*.ppm", "*.tiff", "*.svg"]

        onFolderChanged: {
            testModelView.model = fileModel
        }
    }

    ImageViewer {
        id: imageViewer
        anchors.centerIn: parent
        z: 10
    }

    KdeConnectDevices {
        id: kdeConnectDevicesOverlay
        anchors.centerIn: parent
        z: 200
    }

    Item {
        width: parent.width
        height: parent.height
        enabled: !imageViewer.opened ? 1 : 0
        opacity: enabled ? 1 : 0.5

        RowLayout {
            id: headerAreaBMLPg1
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: Kirigami.Units.gridUnit * 3

            Rectangle {
                color: Kirigami.Theme.backgroundColor
                radius: 10
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.margins: Kirigami.Units.smallSpacing

                Controls.Label {
                    id: pathTextArea
                    anchors.fill: parent
                    anchors.leftMargin: Kirigami.Units.largeSpacing
                    anchors.topMargin: Kirigami.Units.smallSpacing
                    anchors.bottomMargin: Kirigami.Units.smallSpacing
                    anchors.rightMargin: Kirigami.Units.largeSpacing
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignLeft
                    color: Kirigami.Theme.textColor
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    text: folderModel.folder.toString().replace("file://", "")
                }
            }

            Controls.RoundButton {
                id: placesButton
                Layout.alignment: Qt.AlignRight
                Layout.fillHeight: true
                Layout.preferredWidth: Mycroft.Units.gridUnit * 10
                Layout.margins: Kirigami.Units.smallSpacing
                radius: 10              
                icon.name: "tag-places"
                icon.color: Kirigami.Theme.textColor
                text: "Places"

                onClicked: {
                    Mycroft.SoundEffects.playClickedSound(Qt.resolvedUrl("sounds/clicked.wav"))
                    browserView.parent.currentIndex = 0
                }
            }

            Controls.RoundButton {
                id: unmountButton
                Layout.alignment: Qt.AlignRight
                Layout.fillHeight: true
                Layout.preferredWidth: Mycroft.Units.gridUnit * 10
                Layout.margins: Kirigami.Units.smallSpacing
                radius: 10              
                icon.name: "media-eject"
                icon.color: Kirigami.Theme.textColor
                enabled: !deviceSystem && !internalSystemCheck ? 1 : 0
                opacity: !deviceSystem && !internalSystemCheck ? 1 : 0.5
                text: "Unmount"

                onClicked: {
                    Mycroft.SoundEffects.playClickedSound(Qt.resolvedUrl("sounds/clicked.wav"))
                    browserView.parent.showNotification(browserView.device.path, "unmounting")
                    OVOSPlugin.PlacesModel.unmount(browserView.device.deviceIndex)
                }
            }

            Controls.RoundButton {
                id: folderPlaylistButton
                Layout.alignment: Qt.AlignRight
                Layout.fillHeight: true
                Layout.preferredWidth: Mycroft.Units.gridUnit * 5
                Layout.margins: Kirigami.Units.smallSpacing
                radius: 10              
                icon.name: "source-playlist"
                icon.color: Kirigami.Theme.textColor
                enabled: testModelView.count > 0 ? 1 : 0
                opacity: testModelView.count > 0 ? 1 : 0.5

                onClicked: {
                    Mycroft.SoundEffects.playClickedSound(Qt.resolvedUrl("sounds/clicked.wav"))
                    triggerGuiEvent("folder.play", {"path": folderModel.folder.toString().replace("file://", "")})
                }
            }
        }

        Kirigami.Separator {
            id: headrSeptBml
            anchors.top: headerAreaBMLPg1.bottom
            width: parent.width
            height: 1
        }

        RowLayout {
            anchors.top: headrSeptBml.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: Kirigami.Units.largeSpacing

            ListView {
                id: fileModelFolderSelector
                model: folderModel
                Layout.preferredWidth: parent.width * 0.30
                Layout.fillHeight: true
                keyNavigationEnabled: true
                highlightFollowsCurrentItem: true
                highlightRangeMode: GridView.ApplyRange
                spacing: Kirigami.Units.smallSpacing
                clip: true
                KeyNavigation.right: testModelView
                delegate: MenuButton {
                    iconSource: "folder"
                    text: fileName

                    onClicked: {
                        Mycroft.SoundEffects.playClickedSound(Qt.resolvedUrl("sounds/clicked.wav"))
                        folderModel.folder = fileUrl
                    }
                }
            }

            GridView {
                id: testModelView
                Layout.fillWidth: true
                Layout.fillHeight: true
                cellWidth: horizontalMode ? parent.width / 4.75 : parent.width / 3
                cellHeight: horizontalMode ? cellWidth : cellWidth * 1.25
                keyNavigationEnabled: true
                highlightFollowsCurrentItem: true
                highlightRangeMode: GridView.ApplyRange
                snapMode: GridView.SnapToRow
                cacheBuffer: width
                highlightMoveDuration: Kirigami.Units.longDuration
                clip: true
                Controls.ScrollBar.vertical: filesScrollBar
                KeyNavigation.left: fileModelFolderSelector
                delegate: FileItemDelegate {
                    imageSource: browserView.getFileThumbnail(browserView.getFileType(fileUrl), fileUrl)
                    imageTypeIcon: browserView.getFileType(fileUrl) == "image" ? 0 : 1

                    onClicked: {
                        Mycroft.SoundEffects.playClickedSound(Qt.resolvedUrl("sounds/clicked.wav"))
                        if(browserView.getFileType(fileUrl) == "image"){
                            imageViewer.source = fileUrl
                            imageViewer.open()
                        } else {
                            triggerGuiEvent("file.play", {"fileURL": fileUrl})
                        }
                    }
                }

                onCountChanged: {
                    if(testModelView.count > 0){
                        testModelView.forceActiveFocus()
                        testModelView.currentIndex = 0
                        fileModelFolderSelector.currentIndex = 0
                    } else {
                        fileModelFolderSelector.forceActiveFocus()
                        fileModelFolderSelector.currentIndex = 0
                    }
                }

                move: Transition {
                    SmoothedAnimation {
                        property: "x"
                        duration: Kirigami.Units.longDuration
                    }
                }
            }

            Controls.ScrollBar {
                id: filesScrollBar
                Layout.preferredWidth: Mycroft.Units.gridUnit * 2
                Layout.alignment: Qt.AlignRight
                Layout.fillHeight: true
            }
        }
    }
}
