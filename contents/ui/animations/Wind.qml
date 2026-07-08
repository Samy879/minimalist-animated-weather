import QtQuick
import Qt5Compat.GraphicalEffects
import org.kde.kirigami as Kirigami

Item {
    id: windRoot
    anchors.fill: parent
    clip: true

    readonly property color windColor: Kirigami.Theme.textColor

    Repeater {
        model: 8 // Un peu plus de traits pour compenser la finesse
        delegate: Item {
            id: windStreak

            // --- PROPRIÉTÉS DE TRAJECTOIRE ---
            property real progress: 0.0
            property real currentY: Math.random() * (windRoot.height > 0 ? windRoot.height : 500)
            property real currentWidth: 150 + Math.random() * 250
            property real currentSpeed: 3000 + Math.random() * 3000

            width: currentWidth
            height: 1.2 // Très fin pour l'élégance

            // Position calculée dynamiquement
            x: -width + (progress * (windRoot.width + width * 2))
            y: currentY

            opacity: 0

            // 1. DESSIN DU TRAIT
            Rectangle {
                anchors.fill: parent
                radius: height / 2
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    // Opacité un peu plus haute pour être sûr de bien le voir
                    GradientStop { position: 0.5; color: Qt.alpha(windRoot.windColor, 0.3) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            // 2. BOUCLE D'ANIMATION PRINCIPALE
            SequentialAnimation {
                id: mainLoop
                loops: Animation.Infinite

                // Pause entre deux souffles
                PauseAnimation { duration: 500 + Math.random() * 4000 }

                // Les durées ci-dessous sont assignées directement (via les
                // "id" progressAnim/fadeInAnim/fadeHold/fadeOutAnim) plutôt
                // que bindées en direct à windStreak.currentSpeed : comme ce
                // ScriptAction modifie currentSpeed à chaque tour de la
                // boucle infinie, un binding vivant provoquerait le même
                // "Binding loop detected for property duration" que dans
                // pluie.qml.
                ScriptAction {
                    script: {
                        // On réinitialise pour le prochain passage
                        windStreak.currentY = Math.random() * windRoot.height;
                        windStreak.progress = 0;
                        windStreak.currentSpeed = 3000 + Math.random() * 3000;

                        progressAnim.duration = windStreak.currentSpeed;
                        fadeInAnim.duration = windStreak.currentSpeed * 0.2;
                        fadeHold.duration = windStreak.currentSpeed * 0.6;
                        fadeOutAnim.duration = windStreak.currentSpeed * 0.2;
                    }
                }

                ParallelAnimation {
                    // Mouvement de progression
                    NumberAnimation {
                        id: progressAnim
                        target: windStreak
                        property: "progress"
                        from: 0.0
                        to: 1.0
                        easing.type: Easing.InOutSine
                    }

                    // Gestion de l'opacité (entrée/sortie en fondu)
                    SequentialAnimation {
                        NumberAnimation { id: fadeInAnim; target: windStreak; property: "opacity"; to: 1.0 }
                        PauseAnimation { id: fadeHold }
                        NumberAnimation { id: fadeOutAnim; target: windStreak; property: "opacity"; to: 0 }
                    }
                }
            }

            // 3. DÉMARRAGE INSTANTANÉ
            Component.onCompleted: {
                // On pré-positionne le trait n'importe où
                windStreak.progress = Math.random();

                // On lance une petite animation pour finir le trajet en cours
                initialFade.start();
                initialMove.duration = windStreak.currentSpeed * (1.0 - windStreak.progress);
                initialMove.start();
            }

            // Animations de démarrage (jouées une seule fois)
            NumberAnimation { id: initialFade; target: windStreak; property: "opacity"; to: 1.0; duration: 500 }
            NumberAnimation {
                id: initialMove
                target: windStreak
                property: "progress"
                to: 1.0
                easing.type: Easing.InSine
                onFinished: {
                    windStreak.opacity = 0;
                    mainLoop.start(); // Une fois fini, on lance la boucle avec pauses
                }
            }

            // Effet de flou léger
            layer.enabled: true
            layer.effect: GaussianBlur { radius: 1.2; samples: 8 }
        }
    }
}
