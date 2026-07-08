import QtQuick
import QtQuick.Particles
import Qt5Compat.GraphicalEffects
import org.kde.kirigami as Kirigami

Item {
    id: snowRoot
    anchors.fill: parent
    clip: true

    property int flakeCount: 75

    ParticleSystem {
        id: snowSystem
        anchors.fill: parent
    }

    // Le vent : on lui donne plus de force pour reproduire l'ancien "windDrift"
    Wander {
        system: snowSystem
        anchors.fill: parent
        affectedParameter: Wander.Position

        pace: 2.0        // Accélération du rythme d'oscillation
        xVariance: 60    // Amplitude doublée pour de vrais zigzags
        yVariance: 0
    }

    ItemParticle {
        system: snowSystem

        delegate: Item {
            property real depth: Math.random()
            property real size: 1.5 + depth * 3.0
            property real opacityValue: 0.2 + depth * 0.5

            width: size * 4
            height: size * 4
            z: depth

            RadialGradient {
                anchors.fill: parent
                horizontalRadius: parent.width * 0.25
                verticalRadius: horizontalRadius

                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.alpha(Kirigami.Theme.textColor, opacityValue) }
                    GradientStop { position: 0.5; color: Qt.alpha(Kirigami.Theme.textColor, opacityValue * 0.3) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }
        }
    }

    Emitter {
        system: snowSystem
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.leftMargin: -50
        anchors.right: parent.right
        anchors.rightMargin: -50
        height: 1

        emitRate: snowRoot.flakeCount / 4.0
        lifeSpan: 8000
        lifeSpanVariation: 2000

        velocity: PointDirection {
            y: 67
            yVariation: 42

            // LA NOUVEAUTÉ : casse la ligne droite parfaite dès le départ.
            // Les flocons partent avec un léger angle aléatoire vers la gauche ou la droite.
            xVariation: 25
        }
    }
}
