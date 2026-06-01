import QtQuick 2.15
import SddmComponents 2.0

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#161821"

    property string selectedUser: userModel.lastUser || "cgpp"
    property int sessionIndex: sessionModel.lastIndex
    readonly property color base: "#161821"
    readonly property color mantle: "#0F1117"
    readonly property color surface: "#1E2132"
    readonly property color surfaceHigh: "#2E313F"
    readonly property color outline: "#444B71"
    readonly property color text: "#C6C8D1"
    readonly property color muted: "#6B7089"
    readonly property color blue: "#84A0C6"
    readonly property color cyan: "#89B8C2"
    readonly property color red: "#E27878"

    TextConstants { id: textConstants }

    Connections {
        target: sddm
        function onLoginFailed() {
            password.text = ""
            message.text = textConstants.loginFailed
            password.focus = true
        }
        function onLoginSucceeded() {
            message.text = textConstants.loginSucceeded
        }
        function onInformationMessage(text) {
            message.text = text
        }
    }

    Background {
        anchors.fill: parent
        source: config.background
        fillMode: Image.PreserveAspectCrop
    }

    Rectangle {
        anchors.fill: parent
        color: "#0B0D12"
        opacity: 0.58
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#00161821" }
            GradientStop { position: 0.58; color: "#33161821" }
            GradientStop { position: 1.0; color: "#CC0B0D12" }
        }
    }

    Column {
        id: card
        width: Math.min(420, root.width - 48)
        spacing: 18
        anchors.centerIn: parent

        Text {
            width: parent.width
            text: sddm.hostName
            color: text
            opacity: 0.86
            font.family: "Inter"
            font.pixelSize: 18
            font.weight: Font.Medium
            horizontalAlignment: Text.AlignHCenter
        }

        Row {
            id: users
            width: parent.width
            height: 78
            spacing: 10

            Repeater {
                model: userModel

                Rectangle {
                    width: (users.width - users.spacing) / 2
                    height: users.height
                    radius: 8
                    color: selectedUser === name ? "#CC1E2132" : "#99161821"
                    border.color: selectedUser === name ? blue : outline
                    border.width: selectedUser === name ? 1 : 0

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            selectedUser = name
                            password.focus = true
                        }
                    }

                    Column {
                        anchors.centerIn: parent
                        width: parent.width - 20
                        spacing: 5

                        Rectangle {
                            width: 32
                            height: 32
                            radius: 16
                            color: selectedUser === name ? blue : surfaceHigh
                            anchors.horizontalCenter: parent.horizontalCenter

                            Text {
                                anchors.centerIn: parent
                                text: (realName || name).slice(0, 1).toUpperCase()
                                color: selectedUser === name ? base : text
                                font.family: "Inter"
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                            }
                        }

                        Text {
                            width: parent.width
                            text: realName || name
                            color: selectedUser === name ? text : "#AEB4C6"
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                            font.family: "Inter"
                            font.pixelSize: 13
                            font.weight: Font.Medium
                        }
                    }
                }
            }
        }

        TextBox {
            id: userFallback
            width: parent.width
            height: userModel.count > 0 ? 0 : 42
            visible: userModel.count === 0
            text: selectedUser
            color: surface
            textColor: text
            borderColor: outline
            focusColor: blue
            hoverColor: surfaceHigh
            font.family: "Inter"
            font.pixelSize: 14
            onTextChanged: selectedUser = text
        }

        PasswordBox {
            id: password
            width: parent.width
            height: 44
            color: "#DD1E2132"
            textColor: text
            borderColor: outline
            focusColor: blue
            hoverColor: surfaceHigh
            font.family: "Inter"
            font.pixelSize: 15
            focus: true

            Keys.onPressed: {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    sddm.login(selectedUser, password.text, sessionIndex)
                    event.accepted = true
                }
            }
        }

        Rectangle {
            width: parent.width
            height: 44
            radius: 8
            color: blue

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: sddm.login(selectedUser, password.text, sessionIndex)
            }

            Text {
                anchors.centerIn: parent
                text: textConstants.login
                color: base
                font.family: "Inter"
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }
        }

        Text {
            id: message
            width: parent.width
            height: 18
            text: ""
            color: red
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            font.family: "Inter"
            font.pixelSize: 12
        }
    }

    Row {
        spacing: 18
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 28

        Text {
            text: "Hyprland"
            color: muted
            font.family: "Inter"
            font.pixelSize: 12
        }

        Text {
            text: textConstants.reboot
            color: cyan
            font.family: "Inter"
            font.pixelSize: 12

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: sddm.reboot()
            }
        }

        Text {
            text: textConstants.shutdown
            color: cyan
            font.family: "Inter"
            font.pixelSize: 12

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: sddm.powerOff()
            }
        }
    }

    Component.onCompleted: password.focus = true
}
