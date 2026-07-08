import QtQuick
import Qt5Compat.GraphicalEffects
import org.kde.kirigami as Kirigami

Item {
    id: drizzleRoot
    anchors.fill: parent
    clip: true

    // Angle d'inclinaison de la bruine (vent léger)
    property real windAngle: 12

    Repeater {
        model: 70 // Légèrement augmenté car les gouttes sont plus fines et discrètes
        delegate: Item {
            id: dropGroup

            // On initialise les variables aléatoires à la création de l'élément
            Component.onCompleted: {
                // On étend la zone de spawn pour compenser l'angle d'inclinaison
                x = Math.random() * (drizzleRoot.width * 1.5) - (drizzleRoot.width * 0.2)
                y = -20
                animSpeed = 1800 + Math.random() * 1200 // Un poil plus rapide pour le dynamisme
                animWait = Math.random() * 2500
                dropOpacity = 0.08 + Math.random() * 0.12 // Très subtil (max 0.20)
                dropLength = 8 + Math.random() * 8 // Longueur variable pour la profondeur
            }

            property int animSpeed: 2000
            property int animWait: 0
            property real dropOpacity: 0.15
            property real dropLength: 10

            width: 2
            height: drizzleRoot.height + 50
            rotation: drizzleRoot.windAngle // Application de l'angle du vent

            Rectangle {
                id: drop
                anchors.horizontalCenter: parent.horizontalCenter
                width: 0.8 // Extrêmement fin
                height: dropGroup.dropLength
                radius: width / 2 // Bords arrondis pour la douceur

                // Effet de traînée (motion blur) : transparent en haut, visible en bas
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: Kirigami.Theme.textColor }
                }

                opacity: 0 // Commence invisible
            }

            SequentialAnimation {
                running: true
                loops: Animation.Infinite

                PauseAnimation { duration: dropGroup.animWait }

                ParallelAnimation {
                    // Chute de la goutte
                    NumberAnimation {
                        target: drop
                        property: "y"
                        from: -20
                        to: drizzleRoot.height + 20
                        duration: dropGroup.animSpeed
                        easing.type: Easing.InQuad // Légère accélération due à la gravité
                    }

                    // Apparition / Disparition douce
                    SequentialAnimation {
                        NumberAnimation { target: drop; property: "opacity"; to: dropGroup.dropOpacity; duration: 250 }
                        PauseAnimation { duration: dropGroup.animSpeed - 500 }
                        NumberAnimation { target: drop; property: "opacity"; to: 0; duration: 250 }
                    }
                }

                // Reset propre pour la boucle
                PropertyAction { target: drop; property: "y"; value: -20 }
            }
        }
    }
}
