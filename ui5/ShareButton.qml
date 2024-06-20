// SPDX-FileCopyrightText: 2021 Aditya Mehra <aix.m@outlook.com>
//
// SPDX-License-Identifier: Apache-2.0

import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import org.kde.kirigami 2.11 as Kirigami
import QtGraphicalEffects 1.0
import Mycroft 1.0 as Mycroft

Button {
    id: shareControl
    property var provider
    
    background: Rectangle {
        color: "transparent"
    }
    
    contentItem: Kirigami.Icon {
        id: shareIcon
        source: provider
        color: Kirigami.Theme.textColor
    }

    onPressed: {
        shareControl.opacity = 0.5
    }

    onReleased: {
        shareControl.opacity = 1.0
    }
}