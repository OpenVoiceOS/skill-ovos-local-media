// SPDX-FileCopyrightText: 2021 Aditya Mehra <aix.m@outlook.com>
//
// SPDX-License-Identifier: Apache-2.0

import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import org.kde.kirigami 2.11 as Kirigami
import QtGraphicalEffects 1.0

ItemDelegate {
    id: delegate
    property int borderSize: Kirigami.Units.smallSpacing
    property int baseRadius: 3
    property var imageSource
    property bool imageTypeIcon: false

    readonly property Flickable gridView: {
        var candidate = parent;
        while (candidate) {
            if (candidate instanceof Flickable) {
                return candidate;
            }
            candidate = candidate.parent;
        }
        return null;
    }

    readonly property bool isCurrent: {
        gridView.currentIndex == index && activeFocus && !gridView.moving
    }

    leftPadding: Kirigami.Units.largeSpacing * 2
    topPadding: Kirigami.Units.largeSpacing * 2
    rightPadding: Kirigami.Units.largeSpacing * 2
    bottomPadding: Kirigami.Units.largeSpacing * 2

    leftInset: Kirigami.Units.largeSpacing
    topInset: Kirigami.Units.largeSpacing
    rightInset: Kirigami.Units.largeSpacing
    bottomInset: Kirigami.Units.largeSpacing

    implicitWidth: gridView.cellWidth
    height: gridView.cellHeight

    background: Item {
        id: background

        readonly property Item highlight: Rectangle {
            parent: delegate
            z: 1
            anchors {
                fill: parent
            }
            color: "transparent"
            border {
                width: delegate.borderSize
                color: delegate.Kirigami.Theme.highlightColor
            }
            opacity: delegate.isCurrent || delegate.highlighted
            Behavior on opacity {
                OpacityAnimator {
                    duration: Kirigami.Units.longDuration/2
                    easing.type: Easing.InOutQuad
                }
            }
        }

        Rectangle {
            id: frame
            anchors {
                fill: parent
            }
            radius: delegate.baseRadius
            color: delegate.Kirigami.Theme.backgroundColor
            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: false
                horizontalOffset: 1.25
                verticalOffset: 1
            }

            states: [
                State {
                    when: delegate.isCurrent
                    PropertyChanges {
                        target: delegate
                        leftInset: 0
                        rightInset: 0
                        topInset: 0
                        bottomInset: 0
                    }
                    PropertyChanges {
                        target: background.highlight.anchors
                        margins: 0
                    }
                    PropertyChanges {
                        target: frame
                        radius: delegate.baseRadius + delegate.borderSize
                    }
                    PropertyChanges {
                        target: background.highlight
                        radius: delegate.baseRadius + delegate.borderSize
                    }
                },
                State {
                    when: !delegate.isCurrent
                    PropertyChanges {
                        target: delegate
                        leftInset: Kirigami.Units.largeSpacing
                        rightInset: Kirigami.Units.largeSpacing
                        topInset: Kirigami.Units.largeSpacing
                        bottomInset: Kirigami.Units.largeSpacing
                    }
                    PropertyChanges {
                        target: background.highlight.anchors
                        margins: Kirigami.Units.largeSpacing
                    }
                    PropertyChanges {
                        target: frame
                        radius: delegate.baseRadius
                    }
                    PropertyChanges {
                        target: background.highlight
                        radius: delegate.baseRadius
                    }
                }
            ]

            transitions: Transition {
                ParallelAnimation {
                    NumberAnimation {
                        property: "leftInset"
                        duration: Kirigami.Units.longDuration
                        easing.type: Easing.InOutQuad
                    }
                    NumberAnimation {
                        property: "rightInset"
                        duration: Kirigami.Units.longDuration
                        easing.type: Easing.InOutQuad
                    }
                    NumberAnimation {
                        property: "topInset"
                        duration: Kirigami.Units.longDuration
                        easing.type: Easing.InOutQuad
                    }
                    NumberAnimation {
                        property: "bottomInset"
                        duration: Kirigami.Units.longDuration
                        easing.type: Easing.InOutQuad
                    }
                    NumberAnimation {
                        property: "radius"
                        duration: Kirigami.Units.longDuration
                        easing.type: Easing.InOutQuad
                    }
                    NumberAnimation {
                        property: "margins"
                        duration: Kirigami.Units.longDuration
                        easing.type: Easing.InOutQuad
                    }
                }
            }
        }
    }

    contentItem: ColumnLayout {
        spacing: Kirigami.Units.smallSpacing

        Item {
            id: imgRoot
            Layout.alignment: Qt.AlignTop
            Layout.fillWidth: true
            Layout.topMargin: -delegate.topPadding + delegate.topInset + extraBorder
            Layout.leftMargin: -delegate.leftPadding + delegate.leftInset + extraBorder
            Layout.rightMargin: -delegate.rightPadding + delegate.rightInset + extraBorder
            Layout.preferredHeight: width * 0.5625 + delegate.baseRadius
            property real extraBorder: 0

            layer.enabled: true
            layer.effect: OpacityMask {
                cached: true
                maskSource: Rectangle {
                    x: imgRoot.x;
                    y: imgRoot.y
                    width: imgRoot.width
                    height: imgRoot.height
                    radius: delegate.baseRadius
                }
            }

            Kirigami.Icon {
                enabled: imageTypeIcon
                visible: imageTypeIcon
                source: imageSource
                anchors {
                    fill: parent
                    bottomMargin: delegate.baseRadius
                }
                opacity: 1
            }

            Image {
                enabled: !imageTypeIcon
                visible: !imageTypeIcon
                source: imageSource
                anchors {
                    fill: parent
                    bottomMargin: delegate.baseRadius
                }
                opacity: 1
            }

            states: [
                State {
                    when: delegate.isCurrent
                    PropertyChanges {
                        target: imgRoot
                        extraBorder: delegate.borderSize
                    }
                },
                State {
                    when: !delegate.isCurrent
                    PropertyChanges {
                        target: imgRoot
                        extraBorder: 0
                    }
                }
            ]
            transitions: Transition {
                NumberAnimation {
                    property: "extraBorder"
                    duration: Kirigami.Units.longDuration
                    easing.type: Easing.InOutQuad
                }
            }
        }

        Label {
            id: videoLabel
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
            horizontalAlignment: Text.AlignLeft
            verticalAlignment: Text.AlignTop
            maximumLineCount: 1
            wrapMode: Text.Wrap
            elide: Text.ElideRight
            color: Kirigami.Theme.textColor

            Component.onCompleted: {
                text = fileName + (fileIsDir ? "/" : "")
            }
        }
    }

    Keys.onReturnPressed: {
        clicked()
    }
}