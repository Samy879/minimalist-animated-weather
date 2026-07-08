import QtQuick
import Qt5Compat.GraphicalEffects
import org.kde.kirigami as Kirigami

Item {
    id: hailRoot
    anchors.fill: parent
    clip: true

    Component {
        id: hailComponent
        Item {
            id: hailGroup
            property int animSpeed: 600
            property int animWait: 0

            width: 30; height: hailRoot.height

            // La bille de grêle
            Rectangle {
                id: ball
                anchors.horizontalCenter: parent.horizontalCenter
                width: 3; height: 3; radius: 1.5
                color: Kirigami.Theme.textColor
                opacity: 0.8
            }

            // Impact au sol
            Rectangle {
                id: impact
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                width: 6; height: 2; radius: 1
                color: Kirigami.Theme.textColor
                opacity: 0; scale: 1
            }

            SequentialAnimation {
                running: true; loops: Animation.Infinite
                PauseAnimation { duration: hailGroup.animWait }

                // Chute rapide
                NumberAnimation {
                    target: ball; property: "y";
                    from: -10; to: hailRoot.height - 5;
                    duration: hailGroup.animSpeed; easing.type: Easing.InQuad
                }

                // Disparition de la bille et flash de l'impact
                ParallelAnimation {
                    PropertyAction { target: ball; property: "opacity"; value: 0 }
                    SequentialAnimation {
                        NumberAnimation { target: impact; property: "opacity"; to: 0.6; duration: 20 }
                        NumberAnimation { target: impact; property: "scale"; to: 2.5; duration: 50 }
                        NumberAnimation { target: impact; property: "opacity"; to: 0; duration: 100 }
                    }
                }
                PropertyAction { target: ball; property: "y"; value: -10 }
                PropertyAction { target: ball; property: "opacity"; value: 0.8 }
                PropertyAction { target: impact; property: "scale"; value: 1 }
            }
        }
    }

    Repeater {
        model: 15
        delegate: Loader {
            x: Math.random() * hailRoot.width
            sourceComponent: hailComponent
            onLoaded: {
                // Vitesse très rapide (400ms - 800ms)
                item.animSpeed = 400 + Math.random() * 400;
                item.animWait = Math.random() * 2000;
            }
        }
    }
}
