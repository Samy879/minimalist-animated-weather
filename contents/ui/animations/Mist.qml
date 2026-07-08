import QtQuick
import Qt5Compat.GraphicalEffects
import org.kde.kirigami as Kirigami

Item {
    id: fogRoot
    anchors.fill: parent
    clip: true

    readonly property color fogBaseColor: Kirigami.Theme.textColor

    Repeater {
        model: 3
        delegate: Item {
            id: fogLayer
            width: fogRoot.width * 2.5
            height: 120

            readonly property real startX: -fogRoot.width * 0.6 - (index * 40)
            readonly property real startY: fogRoot.height - 60 - (index * 40)

            x: startX
            y: startY

            // Parenthèses ajoutées pour satisfaire la rigueur de QML 6
            property real baseOpacity: (Kirigami.Theme.brightness === Kirigami.Theme.Dark) ? (index === 1 ? 0.09 : 0.12) : (index === 1 ? 0.05 : 0.08)

            opacity: baseOpacity

            Item {
                anchors.fill: parent

                Rectangle {
                    x: index * 30; y: 40;
                    width: parent.width * 0.8; height: 50;
                    radius: 25; color: fogRoot.fogBaseColor
                }

                Rectangle {
                    x: parent.width * 0.15 - (index * 30); y: 25 + (index * 8);
                    width: parent.width * 0.6; height: 35 - (index * 5);
                    radius: 15; color: fogRoot.fogBaseColor
                }

                Rectangle {
                    x: parent.width * 0.4 - (index * 50); y: 70 - (index * 12);
                    width: parent.width * 0.45; height: 20 + (index * 2);
                    radius: 12; color: fogRoot.fogBaseColor
                }
            }

            layer.enabled: true
            layer.effect: GaussianBlur {
                radius: 24
                samples: 32
            }

            // --- ANIMATIONS CENTRALISÉES (Syntaxe QML 6 stricte) ---
            ParallelAnimation {
                running: true

                // Mouvement horizontal (dérive)
                SequentialAnimation {
                    loops: Animation.Infinite
                    NumberAnimation { target: fogLayer; property: "x"; from: fogLayer.startX; to: fogLayer.startX + (fogRoot.width * 0.35); duration: 55000 + (index * 18000); easing.type: Easing.InOutSine }
                    NumberAnimation { target: fogLayer; property: "x"; to: fogLayer.startX; duration: 55000 + (index * 18000); easing.type: Easing.InOutSine }
                }

                // Respiration verticale et fondue (Parallaxe)
                SequentialAnimation {
                    PauseAnimation { duration: index * 4500 } // Décalage pour le côté organique
                    SequentialAnimation {
                        loops: Animation.Infinite
                        ParallelAnimation {
                            NumberAnimation { target: fogLayer; property: "y"; to: fogLayer.startY + 8 + (index * 4); duration: 25000 + (index * 2000); easing.type: Easing.InOutSine }
                            NumberAnimation { target: fogLayer; property: "opacity"; to: fogLayer.baseOpacity + 0.03; duration: 25000 + (index * 2000); easing.type: Easing.InOutSine }
                            NumberAnimation { target: fogLayer; property: "scale"; to: 1.02 + (index * 0.01); duration: 25000 + (index * 2000); easing.type: Easing.InOutSine }
                        }
                        ParallelAnimation {
                            NumberAnimation { target: fogLayer; property: "y"; to: fogLayer.startY; duration: 25000 + (index * 2000); easing.type: Easing.InOutSine }
                            NumberAnimation { target: fogLayer; property: "opacity"; to: fogLayer.baseOpacity; duration: 25000 + (index * 2000); easing.type: Easing.InOutSine }
                            NumberAnimation { target: fogLayer; property: "scale"; to: 1.0; duration: 25000 + (index * 2000); easing.type: Easing.InOutSine }
                        }
                    }
                }
            }
        }
    }
}
