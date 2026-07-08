import QtQuick
import Qt5Compat.GraphicalEffects
import org.kde.kirigami as Kirigami

// --- ARC-EN-CIEL ---
// Effet bonus (débloqué via Rate/Star, cfg_rainbowEffect -> clé kcfg
// "RainbowEffect"). Superposé à l'effet pluie/soleil dans
// FullRepresentation.qml (visible seulement quand il pleut en averses avec
// le soleil encore présent), mais ce fichier est autonome et peut être
// chargé seul pour être testé/prévisualisé, y compris dans le testeur
// main.qml.
//
// --- ESPRIT DU DESIGN ---
// Un demi arc-en-ciel stylé et fin qui semble surgir du coin bas-droit de
// l'écran (le centre du cercle porteur est volontairement placé hors-cadre)
// et s'évanouit en filet vers le haut-gauche : un ruban de couleur qui a une
// "origine" (le bord) et une "pointe" qui se dissout dans le ciel. Le fondu
// le long du tracé est fait avec un dégradé natif du Canvas (pas des petits
// segments juxtaposés) pour rester parfaitement lisse, sans saccades ni
// coupures visibles. Couleurs délavées, flou doux, toujours visible (pas de
// clignotement) avec juste une respiration très légère.
Item {
    id: rainbowRoot
    anchors.fill: parent
    clip: true

    // Bandes délavées, dans l'ordre physique réel du rouge (extérieur) au
    // violet (intérieur). Toutes désaturées et éclaircies pour rester
    // discrètes — jamais de rouge/jaune/bleu purs qui sauteraient aux yeux.
    readonly property var bandColors: [
        "#E7897E", // rouge poudré
        "#EDB07E", // orange abricot doux
        "#EAD98A", // jaune paille
        "#A8D2A4", // vert sauge
        "#8FBBDE", // bleu ciel délavé
        "#A79EDB", // indigo pastel
        "#C6A6D6"  // violet pastel
    ]

    // Toujours visible : plus de clignotement complet, juste une très
    // légère respiration d'opacité (voir l'animation en bas de fichier) qui
    // ne redescend jamais jusqu'à zéro.
    property real arcOpacity: 0.42
    opacity: arcOpacity

    // Intensité de base des bandes (avant le fondu en dégradé le long du
    // tracé). Légèrement augmentée pour une meilleure visibilité tout en
    // restant discrète.
    readonly property real baseAlpha: 0.34

    // --- ÉCHELLE ET ANCRAGE ---
    // Le cercle porteur de l'arc est centré hors-cadre, dans le coin
    // bas-droit : on ne voit donc jamais qu'une portion de ce cercle, ce
    // qui donne ce demi arc-en-ciel qui semble jaillir du bord droit plutôt
    // qu'un dôme entier posé au milieu de l'écran.
    readonly property real arcRadius: Math.min(width, height) * 0.62
    // Bandes plus fines qu'avant (moins épais).
    readonly property real bandThickness: arcRadius * 0.022
    // Décalage hors-cadre exprimé en fraction de la plus petite dimension
    // (et non de la largeur totale) : le rendu reste cohérent même si le
    // widget est redimensionné en un format très large sur le bureau,
    // au lieu de repousser l'ancre hors de portée.
    readonly property real centerX: width + Math.min(width, height) * 0.08
    readonly property real centerY: height + Math.min(width, height) * 0.12

    // Portion de cercle dessinée, allongée par rapport à la version
    // précédente ("plus long") : l'ancrage reste proche du bord droit,
    // et la pointe s'étire nettement plus loin vers le haut-gauche.
    readonly property real anchorAngle: Math.PI * 1.85  // proche du bord droit
    readonly property real tipAngle: Math.PI * 1.05      // la pointe, allongée

    Canvas {
        id: canvas
        anchors.fill: parent
        renderStrategy: Canvas.Cooperative

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            ctx.clearRect(0, 0, width, height);
            ctx.lineCap = "round";

            var a0 = rainbowRoot.tipAngle;
            var a1 = rainbowRoot.anchorAngle;

            function hexToRgb(hex) {
                var v = parseInt(hex.replace("#", ""), 16);
                return { r: (v >> 16) & 255, g: (v >> 8) & 255, b: v & 255 };
            }

            for (var i = 0; i < rainbowRoot.bandColors.length; i++) {
                var r = rainbowRoot.arcRadius - i * rainbowRoot.bandThickness;

                var tipX = rainbowRoot.centerX + r * Math.cos(a0);
                var tipY = rainbowRoot.centerY + r * Math.sin(a0);
                var anchorX = rainbowRoot.centerX + r * Math.cos(a1);
                var anchorY = rainbowRoot.centerY + r * Math.sin(a1);

                // Dégradé natif le long de la corde pointe -> ancrage :
                // un seul tracé continu, donc aucune coupure ni saccade,
                // juste un fondu parfaitement lisse.
                var rgb = hexToRgb(rainbowRoot.bandColors[i]);
                var grad = ctx.createLinearGradient(tipX, tipY, anchorX, anchorY);
                grad.addColorStop(0.0, "rgba(" + rgb.r + "," + rgb.g + "," + rgb.b + ",0)");
                grad.addColorStop(1.0, "rgba(" + rgb.r + "," + rgb.g + "," + rgb.b + "," + rainbowRoot.baseAlpha + ")");

                ctx.strokeStyle = grad;
                ctx.lineWidth = rainbowRoot.bandThickness;
                ctx.globalAlpha = 1.0;

                ctx.beginPath();
                ctx.arc(rainbowRoot.centerX, rainbowRoot.centerY, r, a0, a1, false);
                ctx.stroke();
            }
        }

        // Flou doux type aquarelle, dans le même esprit que le flou des
        // nuages : gomme les arêtes du Canvas pour que l'arc se fonde dans
        // le ciel au lieu de ressembler à un dessin vectoriel net.
        layer.enabled: true
        layer.effect: GaussianBlur {
            radius: 7
            samples: 16
        }
    }

    // Respiration très légère, sans jamais disparaître : l'arc-en-ciel
    // reste toujours visible, il "vit" juste un peu, comme un ciel qui
    // change doucement de luminosité.
    SequentialAnimation {
        id: breatheAnim
        running: true
        loops: Animation.Infinite
        NumberAnimation { target: rainbowRoot; property: "arcOpacity"; from: 0.42; to: 0.50; duration: 7000; easing.type: Easing.InOutSine }
        NumberAnimation { target: rainbowRoot; property: "arcOpacity"; from: 0.50; to: 0.42; duration: 7000; easing.type: Easing.InOutSine }
    }
}
