import QtQuick
import Qt5Compat.GraphicalEffects
import org.kde.kirigami as Kirigami

Item {
    id: stormRoot
    anchors.fill: parent
    clip: true

    // --- CONFIGURATION ADAPTATIVE ---
    readonly property color flashColor: Kirigami.Theme.textColor

    readonly property color fogColor: Kirigami.Theme.brightness === Kirigami.Theme.Dark
    ? Qt.rgba(0.2, 0.3, 0.4, 0.4)
    : Qt.rgba(0.7, 0.7, 0.8, 0.3)

    // --- BROUILLARD ATMOSPHÉRIQUE DYNAMIQUE ---
    Item {
        id: fogLayer
        anchors.fill: parent
        opacity: 0.6

        Repeater {
            model: 2
            delegate: Item {
                width: parent.width * 1.5; height: parent.height * 1.5
                x: index === 0 ? -100 : 50
                y: index === 0 ? -50 : 100

                RadialGradient {
                    anchors.fill: parent
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: stormRoot.fogColor }
                        GradientStop { position: 0.7; color: "transparent" }
                    }
                }

                SequentialAnimation on x {
                    loops: Animation.Infinite
                    NumberAnimation { from: -100; to: 100; duration: 25000 + (index * 5000); easing.type: Easing.InOutQuad }
                    NumberAnimation { from: 100; to: -100; duration: 25000 + (index * 5000); easing.type: Easing.InOutQuad }
                }
            }
        }

        layer.enabled: true
        layer.effect: GaussianBlur { radius: 80 }
    }

    // --- GESTIONNAIRE D'ÉCLAIRS NERVEUX ---
    Item {
        id: boltManager
        property real currentIntensity: 0.3
        anchors.fill: parent

        RadialGradient {
            id: boltGrad
            anchors.centerIn: parent
            width: parent.width * 2; height: parent.height * 2
            opacity: 0
            gradient: Gradient {
                GradientStop { position: 0.0; color: stormRoot.flashColor }
                GradientStop { position: 0.45; color: "transparent" }
            }
        }

        // Animation "Nerveuse" Simple
        SequentialAnimation {
            id: animSingle
            NumberAnimation { target: boltGrad; property: "opacity"; to: boltManager.currentIntensity; duration: 40 }
            NumberAnimation { target: boltGrad; property: "opacity"; to: boltManager.currentIntensity * 0.3; duration: 30 }
            NumberAnimation { target: boltGrad; property: "opacity"; to: boltManager.currentIntensity * 0.7; duration: 80 }
            NumberAnimation { target: boltGrad; property: "opacity"; to: 0; duration: 400 }
        }

        // Animation "Double Impact"
        SequentialAnimation {
            id: animDouble
            NumberAnimation { target: boltGrad; property: "opacity"; to: boltManager.currentIntensity * 0.8; duration: 60 }
            NumberAnimation { target: boltGrad; property: "opacity"; to: 0.1; duration: 30 }
            NumberAnimation { target: boltGrad; property: "opacity"; to: boltManager.currentIntensity; duration: 100 }
            NumberAnimation { target: boltGrad; property: "opacity"; to: 0; duration: 500 }
        }

        layer.enabled: true
        layer.effect: GaussianBlur { radius: 60 }
    }

    // --- GÉNÉRATEUR RYTHMIQUE AVANCÉ (FRÉQUENCE LÉGÈREMENT ADOUCIE) ---
    Timer {
        id: lightningSpawner
        running: true; repeat: true
        interval: 1000 // Premier impact un tout petit peu plus tardif

        onTriggered: {
            boltGrad.anchors.horizontalCenterOffset = (Math.random() * stormRoot.width) - (stormRoot.width / 2)
            boltGrad.anchors.verticalCenterOffset = (Math.random() * stormRoot.height) - (stormRoot.height / 2)

            var randInt = Math.random();
            if (randInt > 0.8) boltManager.currentIntensity = 0.6;
            else if (randInt > 0.4) boltManager.currentIntensity = 0.35;
            else boltManager.currentIntensity = 0.15;

            if (Math.random() > 0.5) animSingle.start(); else animDouble.start();

            var rhythmType = Math.random();

            // On baisse un peu la probabilité des rafales (25% au lieu de 35%)
            if (rhythmType < 0.25) {
                // Rafale rapide un peu moins frénétique
                interval = 250 + Math.random() * 400;
            } else if (rhythmType < 0.65) {
                // Battement régulier très légèrement plus espacé
                interval = 1200 + Math.random() * 1500;
            } else {
                // Période de calme un peu plus longue (max 7s au lieu de 6s)
                interval = 3500 + Math.random() * 3500;
            }
        }
    }
}
