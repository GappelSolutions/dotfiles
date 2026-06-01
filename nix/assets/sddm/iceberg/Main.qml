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

    function login() {
        sddm.login(selectedUser, password.text, sessionIndex)
    }

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

    Image {
        anchors.fill: parent
        source: Qt.resolvedUrl("background.png")
        fillMode: Image.PreserveAspectCrop
        smooth: true
        cache: true
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
            color: root.text
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
                    id: userTile
                    width: (users.width - users.spacing) / 2
                    height: users.height
                    radius: 8
                    color: selectedUser === name ? "#CC1E2132" : (userMouse.containsMouse ? "#B51E2132" : "#99161821")
                    border.color: selectedUser === name ? root.blue : root.outline
                    border.width: selectedUser === name || userMouse.containsMouse ? 1 : 0

                    MouseArea {
                        id: userMouse
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        z: 20
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
                            color: selectedUser === name ? root.blue : root.surfaceHigh
                            anchors.horizontalCenter: parent.horizontalCenter

                            Text {
                                anchors.centerIn: parent
                                text: (realName || name).slice(0, 1).toUpperCase()
                                color: selectedUser === name ? root.base : root.text
                                font.family: "Inter"
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                            }
                        }

                        Text {
                            width: parent.width
                            text: realName || name
                            color: selectedUser === name ? root.text : "#AEB4C6"
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

        Rectangle {
            width: parent.width
            height: userModel.count > 0 ? 0 : 44
            visible: userModel.count === 0
            radius: 8
            color: "#DD1E2132"
            border.color: userFallback.activeFocus ? root.blue : root.outline
            border.width: 1

            TextInput {
                id: userFallback
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                verticalAlignment: TextInput.AlignVCenter
                text: selectedUser
                color: root.text
                selectionColor: root.blue
                selectedTextColor: root.base
                font.family: "Inter"
                font.pixelSize: 15
                onTextChanged: selectedUser = text
            }
        }

        Rectangle {
            width: parent.width
            height: 44
            radius: 8
            color: "#DD1E2132"
            border.color: password.activeFocus ? root.blue : root.outline
            border.width: 1

            Text {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                verticalAlignment: Text.AlignVCenter
                text: "Password"
                color: root.muted
                opacity: password.text.length === 0 && !password.activeFocus ? 0.74 : 0
                font.family: "Inter"
                font.pixelSize: 15
            }

            TextInput {
                id: password
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                verticalAlignment: TextInput.AlignVCenter
                color: root.text
                selectionColor: root.blue
                selectedTextColor: root.base
                echoMode: TextInput.Password
                passwordCharacter: "•"
                font.family: "Inter"
                font.pixelSize: 15
                focus: true

                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.login()
                        event.accepted = true
                    }
                    if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
                        if (userModel.count > 1)
                            selectedUser = selectedUser === "wife" ? "cgpp" : "wife"
                        event.accepted = true
                    }
                    if (event.key === Qt.Key_Right || event.key === Qt.Key_Down) {
                        if (userModel.count > 1)
                            selectedUser = selectedUser === "cgpp" ? "wife" : "cgpp"
                        event.accepted = true
                    }
                }
            }
        }

        Rectangle {
            id: loginButton
            width: parent.width
            height: 44
            radius: 8
            color: loginMouse.containsMouse ? "#91ACD1" : root.blue

            MouseArea {
                id: loginMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                z: 20
                onClicked: root.login()
            }

            Text {
                anchors.centerIn: parent
                text: textConstants.login
                color: root.base
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
            color: root.red
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
            color: root.muted
            font.family: "Inter"
            font.pixelSize: 12
        }

        Text {
            id: rebootText
            text: textConstants.reboot
            color: rebootMouse.containsMouse ? "#95C4CE" : cyan
            font.family: "Inter"
            font.pixelSize: 12

            MouseArea {
                id: rebootMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                z: 20
                onClicked: sddm.reboot()
            }
        }

        Text {
            id: shutdownText
            text: textConstants.shutdown
            color: shutdownMouse.containsMouse ? "#95C4CE" : cyan
            font.family: "Inter"
            font.pixelSize: 12

            MouseArea {
                id: shutdownMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                z: 20
                onClicked: sddm.powerOff()
            }
        }
    }

    Text {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: 18
        anchors.bottomMargin: 14
        text: "iceberg-minimal"
            color: root.muted
        opacity: 0.45
        font.family: "Inter"
        font.pixelSize: 10
    }

    Component.onCompleted: password.focus = true
}
