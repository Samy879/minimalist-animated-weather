import QtQuick
import QtQuick.Particles
import org.kde.kirigami as Kirigami

Item {
    id: rainRoot
    anchors.fill: parent
    clip: true

    readonly property color rainColor: Kirigami.Theme.textColor
    property url dropTextureSource: ""

    // Texture générée une seule fois (et régénérée si le thème change) :
    // reproduit le même dégradé transparent -> couleur -> transparent
    // qu'avant, mais servi comme simple image bitmap réutilisée par
    // toutes les particules au lieu d'un Item QML par goutte.
    Canvas {
        id: dropCanvas
        visible: false
        width: 32
        height: 32   // canvas CARRÉ : ImageParticle redimensionne toujours en size×size,
        // un canvas rectangulaire serait donc étiré/écrasé (c'était le bug)

        function drawTexture() {
            if (!available) return;
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            var r = Math.round(rainRoot.rainColor.r * 255);
            var g = Math.round(rainRoot.rainColor.g * 255);
            var b = Math.round(rainRoot.rainColor.b * 255);

            var gradient = ctx.createLinearGradient(0, 0, 0, height);
            gradient.addColorStop(0.0, "rgba(" + r + "," + g + "," + b + ",0)");
            gradient.addColorStop(0.15, "rgba(" + r + "," + g + "," + b + ",0.40)");
            gradient.addColorStop(0.85, "rgba(" + r + "," + g + "," + b + ",0.40)");
            gradient.addColorStop(1.0, "rgba(" + r + "," + g + "," + b + ",0)");

            // Trait fin centré, sur toute la hauteur du canvas
            ctx.fillStyle = gradient;
            ctx.fillRect(width / 2 - 1, 0, 2, height);
            requestPaint();
        }

        onPaint: {
            grabToImage(function(result) {
                rainRoot.dropTextureSource = result.url;
            });
        }

        onAvailableChanged: if (available) drawTexture()

        Connections {
            target: Kirigami.Theme
            function onTextColorChanged() { dropCanvas.drawTexture() }
        }
    }

    ParticleSystem {
        id: rainSystem
        anchors.fill: parent
    }

    ImageParticle {
        id: dropParticle
        system: rainSystem
        source: rainRoot.dropTextureSource
        entryEffect: ImageParticle.None   // pas de fondu supplémentaire, la texture gère déjà l'opacité
    }

    Emitter {
        id: rainEmitter
        system: rainSystem
        anchors.top: parent.top
        width: parent.width
        height: 1

        emitRate: 30
        lifeSpan: 1400
        lifeSpanVariation: 500

        size: 16
        sizeVariation: 8                  // remplace la variation "depth" d'avant : gouttes plus ou moins longues

        velocity: PointDirection {
            x: 0
            xVariation: 15
            y: 420
            yVariation: 190
        }

        acceleration: PointDirection {
            y: 50
        }
    }
}
