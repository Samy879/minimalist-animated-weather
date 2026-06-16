import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.kirigami 2.20 as Kirigami

Item {
    id: chartRoot

    property var values: []
    property color lineColor: Kirigami.Theme.highlightColor
    property string unit: ""
    property string label: ""
    property bool preciseTemp: false
    property int chartType: 0 // 0=Temp, 1=Hum, 2=Vent, 3=UV

    property int currentHour: new Date().getHours()
    property int hoverIndex: -1 // Pour le survol de la souris

    function arrMin(a) {
        if (!a || a.length === 0) return 0;
        let m = a[0];
        for (let i = 1; i < a.length; i++) { if (a[i] < m) m = a[i]; }
        return m;
    }
    function arrMax(a) {
        if (!a || a.length === 0) return 1;
        let m = a[0];
        for (let i = 1; i < a.length; i++) { if (a[i] > m) m = a[i]; }
        return m;
    }

    readonly property real minV: arrMin(values)
    readonly property real maxV: arrMax(values)

    // Ajustement Optique Asymétrique
    readonly property real padLeft:   Kirigami.Units.gridUnit * 1.5
    readonly property real padRight:  Kirigami.Units.gridUnit * 0.7
    readonly property real padTop:    Kirigami.Units.gridUnit * 0.5
    readonly property real padBottom: Kirigami.Units.gridUnit * 1.2

    ColumnLayout {
        anchors.fill: parent
        spacing: 2

        RowLayout {
            Layout.fillWidth: true
            PlasmaComponents3.Label {
                text: chartRoot.label + (chartRoot.unit ? " (" + chartRoot.unit.trim() + ")" : "")
                font.pixelSize: Kirigami.Units.gridUnit * 0.55
                font.bold: true
                opacity: 1.0
            }
            Item { Layout.fillWidth: true }
            PlasmaComponents3.Label {
                text: chartRoot.values.length
                ? (chartRoot.preciseTemp ? parseFloat(chartRoot.minV.toFixed(1)) : Math.round(chartRoot.minV)) + " – " +
                (chartRoot.preciseTemp ? parseFloat(chartRoot.maxV.toFixed(1)) : Math.round(chartRoot.maxV))
                : "--"
                font.pixelSize: Kirigami.Units.gridUnit * 0.5
                opacity: 0.9
            }
        }

        Canvas {
            id: canvas
            Layout.fillWidth: true
            Layout.fillHeight: true
            antialiasing: true
            renderTarget: Canvas.Image

            readonly property var pts: chartRoot.values
            readonly property real pL: chartRoot.padLeft
            readonly property real pR: chartRoot.padRight
            readonly property real pT: chartRoot.padTop
            readonly property real pB: chartRoot.padBottom

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onPositionChanged: (mouse) => {
                    let w = canvas.width;
                    let h = canvas.height;
                    let n = chartRoot.values.length;
                    if (n < 2) return;

                    let pL = chartRoot.padLeft;
                    let pR = chartRoot.padRight;
                    let pT = chartRoot.padTop;
                    let pB = chartRoot.padBottom;
                    let rawIdx = Math.round((mouse.x - pL) / (w - pL - pR) * (n - 1));
                    let idx = Math.max(0, Math.min(rawIdx, n - 1));

                    let range = (chartRoot.maxV - chartRoot.minV) || 1;
                    let val = chartRoot.values[idx];
                    let ptY = pT + (h - pT - pB) * (1 - (val - chartRoot.minV) / range);
                    let isAxisHover = mouse.y >= (h - pB - 15);
                    let isCurveHover = Math.abs(mouse.y - ptY) <= 30;
                    if (isAxisHover || isCurveHover) {
                        chartRoot.hoverIndex = idx;
                    } else {
                        chartRoot.hoverIndex = -1;
                    }
                }
                onExited: chartRoot.hoverIndex = -1
            }

            onPaint: {
                let ctx = getContext("2d");
                ctx.reset();

                let n = pts.length;
                if (n < 2) return;

                let w = width;
                let h = height;
                let range = (chartRoot.maxV - chartRoot.minV) || 1;

                function xAt(i) { return pL + (w - pL - pR) * (i / (n - 1)); }
                function yAt(v) { return pT + (h - pT - pB) * (1 - (v - chartRoot.minV) / range); }

                let textColor = Kirigami.Theme.textColor;
                let bgColor   = Kirigami.Theme.backgroundColor;
                let axisOpacity  = 0.50;
                let labelOpacity = 1.0;

                let ySteps = 3;
                for (let s = 0; s <= ySteps; s++) {
                    let v  = chartRoot.minV + (range * s / ySteps);
                    let yy = yAt(v);

                    if (s > 0) {
                        ctx.strokeStyle = Qt.rgba(textColor.r, textColor.g, textColor.b, axisOpacity);
                        ctx.lineWidth = 1;
                        ctx.beginPath();
                        ctx.setLineDash([3, 4]);
                        ctx.moveTo(pL, yy);
                        ctx.lineTo(w - pR, yy);
                        ctx.stroke();
                        ctx.setLineDash([]);
                    }

                    let labelText = chartRoot.preciseTemp ?
                    parseFloat(v.toFixed(1)).toString() : Math.round(v).toString();
                    let fontSize  = Math.round(Kirigami.Units.gridUnit * 0.50);
                    ctx.font = "bold " + fontSize + "px sans-serif";
                    ctx.fillStyle = Qt.rgba(textColor.r, textColor.g, textColor.b, labelOpacity);
                    ctx.textAlign = "right";
                    ctx.textBaseline = "middle";

                    ctx.shadowColor = Qt.rgba(bgColor.r, bgColor.g, bgColor.b, 0.9);
                    ctx.shadowBlur = 4;
                    ctx.fillText(labelText, pL - 5, yy);
                    ctx.shadowBlur = 0;
                }

                // Axe X : 24h inclus
                let xLabels = [0, 6, 12, 18, 24];
                let xFontSize = Math.round(Kirigami.Units.gridUnit * 0.47);
                ctx.font = "bold " + xFontSize + "px sans-serif";
                for (let k = 0; k < xLabels.length; k++) {
                    let xi  = xLabels[k];
                    let idx = (xi === 24) ? 23 : xi;
                    let xx  = xAt(idx);
                    let lbl = xi + "h";

                    ctx.textAlign = "center";
                    ctx.textBaseline = "top";
                    ctx.fillStyle = Qt.rgba(textColor.r, textColor.g, textColor.b, labelOpacity);
                    ctx.shadowColor = Qt.rgba(bgColor.r, bgColor.g, bgColor.b, 0.9);
                    ctx.shadowBlur = 4;
                    ctx.fillText(lbl, xx, h - pB + 5);
                    ctx.shadowBlur = 0;
                    ctx.strokeStyle = Qt.rgba(textColor.r, textColor.g, textColor.b, axisOpacity);
                    ctx.lineWidth = 1;
                    ctx.beginPath();
                    ctx.moveTo(xx, h - pB);
                    ctx.lineTo(xx, h - pB + 4);
                    ctx.stroke();
                }

                ctx.strokeStyle = Qt.rgba(textColor.r, textColor.g, textColor.b, axisOpacity);
                ctx.lineWidth = 1;
                ctx.setLineDash([]);
                ctx.beginPath();
                ctx.moveTo(pL, h - pB);
                ctx.lineTo(w - pR, h - pB);
                ctx.stroke();

                // Dégradé de Remplissage
                function getFillColor(type, v) {
                    if (type === 0) {
                        let isF = chartRoot.unit.indexOf("F") !== -1;
                        let valC = isF ? (v - 32) * 5/9 : v;

                        // Échelle synchronisée et logique
                        if(valC >= 35) return "220, 20, 60";   // Cramoisi (Extrême)
                        if(valC >= 30) return "255, 69, 0";    // Rouge-orangé (Très chaud)
                        if(valC >= 25) return "255, 140, 0";   // Orange (Chaud)
                        if(valC >= 20) return "255, 215, 0";   // Jaune doré (Agréable - englobe 22°C)
                        if(valC >= 15) return "50, 205, 50";   // Vert (Doux)
                        if(valC >= 10) return "0, 191, 255";   // Bleu ciel (Frais)
                        if(valC >= 0)  return "30, 144, 255";  // Bleu vif (Froid)
                        return "0, 0, 139";                    // Bleu nuit (Gel)
                    }
                    if (type === 1) return "74, 144, 226"; // Bleu doux / UI moderne pour l'humidité
                    if (type === 2) return "34, 146, 164"; // Bleu Sarcelle (Vent)
                    if (type === 3) {
                        if(v >= 8) return "255, 0, 0";
                        if(v >= 6) return "255, 140, 0";
                        if(v >= 3) return "255, 215, 0";
                        return "50, 205, 50";
                    }

                    return Math.round(chartRoot.lineColor.r*255) + "," + Math.round(chartRoot.lineColor.g*255) + "," + Math.round(chartRoot.lineColor.b*255);
                }

                let baseColorStr = getFillColor(chartRoot.chartType, chartRoot.maxV);
                let gradFill = ctx.createLinearGradient(0, pT, 0, h - pB);
                gradFill.addColorStop(0, "rgba(" + baseColorStr + ", 0.32)");
                gradFill.addColorStop(1, "rgba(" + baseColorStr + ", 0.0)");

                ctx.beginPath();
                ctx.moveTo(xAt(0), yAt(pts[0]));
                for (let i = 1; i < n; i++) { ctx.lineTo(xAt(i), yAt(pts[i])); }
                ctx.lineTo(xAt(n - 1), h - pB);
                ctx.lineTo(xAt(0), h - pB);
                ctx.closePath();
                ctx.fillStyle = gradFill;
                ctx.fill();

                // Dégradé de la Ligne
                let strokeGrad;
                if (chartRoot.chartType === 0) {
                    let isF = chartRoot.unit.indexOf("F") !== -1;
                    let maxT = isF ? 113 : 45;
                    let minT = isF ? 14 : -10;
                    strokeGrad = ctx.createLinearGradient(0, yAt(maxT), 0, yAt(minT));

                    // Paliers parfaitement synchronisés avec les couleurs du texte
                    strokeGrad.addColorStop(0.000, "#8B0000"); // 45°C
                    strokeGrad.addColorStop(0.181, "#DC143C"); // 35°C
                    strokeGrad.addColorStop(0.272, "#FF4500"); // 30°C
                    strokeGrad.addColorStop(0.363, "#FF8C00"); // 25°C
                    strokeGrad.addColorStop(0.454, "#FFD700"); // 20°C (Désormais 22°C sera un beau jaune pur)
                    strokeGrad.addColorStop(0.545, "#32CD32"); // 15°C
                    strokeGrad.addColorStop(0.636, "#00BFFF"); // 10°C
                    strokeGrad.addColorStop(0.818, "#1E90FF"); // 0°C
                    strokeGrad.addColorStop(1.000, "#00008B"); // -10°C
                } else if (chartRoot.chartType === 1) {
                    // Nouveau dégradé esthétique et minimaliste pour l'humidité
                    strokeGrad = ctx.createLinearGradient(0, yAt(100), 0, yAt(0));
                    strokeGrad.addColorStop(0.0, "#2C3E50"); // Ardoise sombre
                    strokeGrad.addColorStop(0.5, "#4A90E2"); // Bleu doux
                    strokeGrad.addColorStop(1.0, "#AED6F1"); // Bleu pastel clair
                } else if (chartRoot.chartType === 2) {
                    let isMph = chartRoot.unit.indexOf("mph") !== -1;
                    let maxW = isMph ? 62 : 100;
                    strokeGrad = ctx.createLinearGradient(0, yAt(maxW), 0, yAt(0));
                    strokeGrad.addColorStop(0.0, "#0F748F");
                    strokeGrad.addColorStop(0.5, "#2292A4");
                    strokeGrad.addColorStop(1.0, "#6EBFCC");
                } else if (chartRoot.chartType === 3) {
                    strokeGrad = ctx.createLinearGradient(0, yAt(12), 0, yAt(0));
                    strokeGrad.addColorStop(0.00, "#800080");
                    strokeGrad.addColorStop(0.33, "#FF0000");
                    strokeGrad.addColorStop(0.50, "#FF8C00");
                    strokeGrad.addColorStop(0.75, "#FFD700");
                    strokeGrad.addColorStop(1.00, "#32CD32");
                } else {
                    strokeGrad = chartRoot.lineColor;
                }

                ctx.beginPath();
                ctx.moveTo(xAt(0), yAt(pts[0]));
                for (let i = 1; i < n; i++) { ctx.lineTo(xAt(i), yAt(pts[i])); }
                ctx.strokeStyle = strokeGrad;
                ctx.lineWidth = 2;
                ctx.lineJoin = "round";
                ctx.lineCap = "round";
                ctx.setLineDash([]);
                ctx.stroke();

                // --- GESTION DU SURVOL (Points et Texte Minimaliste Pro) ---
                let curIdx = chartRoot.hoverIndex !== -1 ? chartRoot.hoverIndex : Math.max(0, Math.min(chartRoot.currentHour, n - 1));
                let cx = xAt(curIdx);
                let cy = yAt(pts[curIdx]);

                ctx.fillStyle = strokeGrad;

                ctx.globalAlpha = 0.25;
                ctx.beginPath();
                ctx.arc(cx, cy, 5, 0, Math.PI * 2);
                ctx.fill();
                ctx.globalAlpha = 1.0;

                ctx.beginPath();
                ctx.arc(cx, cy, 3, 0, Math.PI * 2);
                ctx.fill();

                ctx.lineWidth = 1;
                ctx.strokeStyle = Qt.rgba(bgColor.r, bgColor.g, bgColor.b, 1.0);
                ctx.stroke();

                let curVal = chartRoot.preciseTemp ? parseFloat(pts[curIdx].toFixed(1)) : Math.round(pts[curIdx]);
                let textToDraw = curVal.toString();
                let fontSize = Math.round(Kirigami.Units.gridUnit * 0.55);

                ctx.font = "bold " + fontSize + "px sans-serif";

                let alignText = "center";
                let xOff = cx;

                if (curIdx === 0) {
                    alignText = "left";
                } else if (curIdx === n - 1) {
                    alignText = "right";
                }

                let isNearTop = cy < pT + 25;
                ctx.textBaseline = isNearTop ? "top" : "bottom";
                let yOff = isNearTop ? cy + 12 : cy - 12;

                // --- Le chiffre coloré uniformément (sans capsule) ---
                let pointColorStr = getFillColor(chartRoot.chartType, pts[curIdx]);
                ctx.fillStyle = "rgb(" + pointColorStr + ")";
                ctx.textAlign = alignText;

                // Légère ombre pour qu'il reste lisible même s'il chevauche une ligne d'axe
                ctx.shadowColor = Qt.rgba(0, 0, 0, 0.4);
                ctx.shadowBlur = 3;
                ctx.shadowOffsetY = 1;

                ctx.fillText(textToDraw, xOff, yOff);

                ctx.shadowColor = "transparent";
                ctx.shadowBlur = 0;
                ctx.shadowOffsetY = 0;
            }

            Component.onCompleted: requestPaint()
        }
    }

    onValuesChanged:      canvas.requestPaint()
    onWidthChanged:       canvas.requestPaint()
    onHeightChanged:      canvas.requestPaint()
    onCurrentHourChanged: canvas.requestPaint()
    onHoverIndexChanged:  canvas.requestPaint()
}
