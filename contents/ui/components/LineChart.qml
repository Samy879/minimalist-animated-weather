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

    // BUG FIX : currentHour est maintenu à jour par un Timer interne.
    // La valeur passée depuis FullRepresentation (new Date().getHours()) était
    // figée à l'heure de chargement du composant. Le Timer corrige ce problème.
    property int currentHour: new Date().getHours()

    Timer {
        interval: 60000   // Vérifie toutes les minutes
        running: chartRoot.visible // Optimisation : le timer s'arrête si le widget n'est pas affiché
        repeat: true
        onTriggered: {
            let actualHour = new Date().getHours();

            // On ne met à jour (et on ne redessine) QUE si l'heure a tourné
            if (chartRoot.currentHour !== actualHour) {
                chartRoot.currentHour = actualHour;
            }
        }
    }

    property int hoverIndex: -1

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

    // Marges asymétriques (identiques à l'original)
    readonly property real padLeft:   Kirigami.Units.gridUnit * 1.5
    readonly property real padRight:  Kirigami.Units.gridUnit * 0.7
    readonly property real padTop:    Kirigami.Units.gridUnit * 0.6
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

                // --- AMÉLIORATION : Courbes Catmull-Rom → Bézier cubiques ---
                // Produit une courbe lisse qui passe exactement par chaque donnée,
                // sans les angles droits visibles des lineTo précédents.
                function buildSmoothPath() {
                    ctx.moveTo(xAt(0), yAt(pts[0]));
                    for (let i = 0; i < n - 1; i++) {
                        let i0 = Math.max(0, i - 1);
                        let i3 = Math.min(n - 1, i + 2);
                        let x0 = xAt(i0), y0 = yAt(pts[i0]);
                        let x1 = xAt(i),   y1 = yAt(pts[i]);
                        let x2 = xAt(i+1), y2 = yAt(pts[i+1]);
                        let x3 = xAt(i3), y3 = yAt(pts[i3]);
                        // Formule standard Catmull-Rom (tension = 1/6)
                        let cp1x = x1 + (x2 - x0) / 6;
                        let cp1y = y1 + (y2 - y0) / 6;
                        let cp2x = x2 - (x3 - x1) / 6;
                        let cp2y = y2 - (y3 - y1) / 6;
                        ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x2, y2);
                    }
                }

                let textColor = Kirigami.Theme.textColor;
                let bgColor   = Kirigami.Theme.backgroundColor;
                let axisOpacity  = 0.30;
                let labelOpacity = 0.80;

                // --- Lignes de grille Y (plus fines et discrètes) ---
                let ySteps = 3;
                for (let s = 0; s <= ySteps; s++) {
                    let v  = chartRoot.minV + (range * s / ySteps);
                    let yy = yAt(v);

                    if (s > 0) {
                        ctx.strokeStyle = Qt.rgba(textColor.r, textColor.g, textColor.b, axisOpacity);
                        ctx.lineWidth = 0.5;
                        ctx.beginPath();
                        ctx.setLineDash([2, 6]);
                        ctx.moveTo(pL, yy);
                        ctx.lineTo(w - pR, yy);
                        ctx.stroke();
                        ctx.setLineDash([]);
                    }

                    let labelText = chartRoot.preciseTemp ?
                    parseFloat(v.toFixed(1)).toString() : Math.round(v).toString();
                    let fontSize = Math.round(Kirigami.Units.gridUnit * 0.48);
                    ctx.font = fontSize + "px sans-serif";
                    ctx.fillStyle = Qt.rgba(textColor.r, textColor.g, textColor.b, labelOpacity);
                    ctx.textAlign = "right";
                    ctx.textBaseline = "middle";
                    ctx.shadowColor = Qt.rgba(bgColor.r, bgColor.g, bgColor.b, 0.85);
                    ctx.shadowBlur = 3;
                    ctx.fillText(labelText, pL - 4, yy);
                    ctx.shadowBlur = 0;
                }

                // --- BUG FIX : Axe X corrigé ---
                // Avant : [0, 6, 12, 18, 24] où "24h" était placé à l'index 23 (= 23h réels),
                // ce qui décalait visuellement tous les repères et induisait en erreur.
                // Maintenant : [0, 6, 12, 18] — propre, exact, sans ambiguïté.
                let xLabels = [0, 6, 12, 18];
                let xFontSize = Math.round(Kirigami.Units.gridUnit * 0.45);
                ctx.font = xFontSize + "px sans-serif";
                for (let k = 0; k < xLabels.length; k++) {
                    let xi = xLabels[k];
                    let xx = xAt(xi);
                    let lbl = xi + "h";

                    ctx.textAlign = xi === 0 ? "left" : "center";
                    ctx.textBaseline = "top";
                    ctx.fillStyle = Qt.rgba(textColor.r, textColor.g, textColor.b, labelOpacity);
                    ctx.shadowColor = Qt.rgba(bgColor.r, bgColor.g, bgColor.b, 0.85);
                    ctx.shadowBlur = 3;
                    ctx.fillText(lbl, xx, h - pB + 4);
                    ctx.shadowBlur = 0;

                    ctx.strokeStyle = Qt.rgba(textColor.r, textColor.g, textColor.b, axisOpacity);
                    ctx.lineWidth = 0.5;
                    ctx.beginPath();
                    ctx.moveTo(xx, h - pB);
                    ctx.lineTo(xx, h - pB + 3);
                    ctx.stroke();
                }

                // Ligne de base X
                ctx.strokeStyle = Qt.rgba(textColor.r, textColor.g, textColor.b, axisOpacity);
                ctx.lineWidth = 0.5;
                ctx.setLineDash([]);
                ctx.beginPath();
                ctx.moveTo(pL, h - pB);
                ctx.lineTo(w - pR, h - pB);
                ctx.stroke();

                // --- Couleurs par type et valeur ---
                function getFillColor(type, v) {
                    if (type === 0) {
                        let isF = chartRoot.unit.indexOf("F") !== -1;
                        let valC = isF ? (v - 32) * 5/9 : v;
                        if(valC >= 35) return "220, 20, 60";
                        if(valC >= 30) return "255, 69, 0";
                        if(valC >= 25) return "255, 140, 0";
                        if(valC >= 20) return "255, 215, 0";
                        if(valC >= 15) return "50, 205, 50";
                        if(valC >= 10) return "0, 191, 255";
                        if(valC >= 0)  return "30, 144, 255";
                        return "0, 0, 139";
                    }
                    if (type === 1) return "74, 144, 226";
                    if (type === 2) return "34, 146, 164";
                    if (type === 3) {
                        if(v >= 8) return "255, 0, 0";
                        if(v >= 6) return "255, 140, 0";
                        if(v >= 3) return "255, 215, 0";
                        return "50, 205, 50";
                    }
                    return Math.round(chartRoot.lineColor.r*255) + "," +
                    Math.round(chartRoot.lineColor.g*255) + "," +
                    Math.round(chartRoot.lineColor.b*255);
                }

                // --- Gradient de remplissage (3 stops pour une transition plus douce) ---
                let baseColorStr = getFillColor(chartRoot.chartType, chartRoot.maxV);
                let gradFill = ctx.createLinearGradient(0, pT, 0, h - pB);
                gradFill.addColorStop(0.0, "rgba(" + baseColorStr + ", 0.26)");
                gradFill.addColorStop(0.6, "rgba(" + baseColorStr + ", 0.07)");
                gradFill.addColorStop(1.0, "rgba(" + baseColorStr + ", 0.00)");

                ctx.beginPath();
                buildSmoothPath();
                ctx.lineTo(xAt(n - 1), h - pB);
                ctx.lineTo(xAt(0), h - pB);
                ctx.closePath();
                ctx.fillStyle = gradFill;
                ctx.fill();

                // --- Gradient de la ligne ---
                let strokeGrad;
                if (chartRoot.chartType === 0) {
                    let isF = chartRoot.unit.indexOf("F") !== -1;
                    let maxT = isF ? 113 : 45;
                    let minT = isF ? 14 : -10;
                    strokeGrad = ctx.createLinearGradient(0, yAt(maxT), 0, yAt(minT));
                    strokeGrad.addColorStop(0.000, "#8B0000");
                    strokeGrad.addColorStop(0.181, "#DC143C");
                    strokeGrad.addColorStop(0.272, "#FF4500");
                    strokeGrad.addColorStop(0.363, "#FF8C00");
                    strokeGrad.addColorStop(0.454, "#FFD700");
                    strokeGrad.addColorStop(0.545, "#32CD32");
                    strokeGrad.addColorStop(0.636, "#00BFFF");
                    strokeGrad.addColorStop(0.818, "#1E90FF");
                    strokeGrad.addColorStop(1.000, "#00008B");
                } else if (chartRoot.chartType === 1) {
                    strokeGrad = ctx.createLinearGradient(0, yAt(100), 0, yAt(0));
                    strokeGrad.addColorStop(0.0, "#2C3E50");
                    strokeGrad.addColorStop(0.5, "#4A90E2");
                    strokeGrad.addColorStop(1.0, "#AED6F1");
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

                // AMÉLIORATION : trait plus épais (2 → 2.5px) + courbe lisse Bézier
                ctx.beginPath();
                buildSmoothPath();
                ctx.strokeStyle = strokeGrad;
                ctx.lineWidth = 2.5;
                ctx.lineJoin = "round";
                ctx.lineCap = "round";
                ctx.setLineDash([]);
                ctx.stroke();

                // --- Marqueur heure courante / survol ---
                let curIdx = chartRoot.hoverIndex !== -1
                ? chartRoot.hoverIndex
                : Math.max(0, Math.min(chartRoot.currentHour, n - 1));
                let cx = xAt(curIdx);
                let cy = yAt(pts[curIdx]);

                // AMÉLIORATION : ligne verticale guide à l'heure courante
                ctx.strokeStyle = Qt.rgba(textColor.r, textColor.g, textColor.b, 0.12);
                ctx.lineWidth = 1;
                ctx.setLineDash([2, 4]);
                ctx.beginPath();
                ctx.moveTo(cx, pT);
                ctx.lineTo(cx, h - pB);
                ctx.stroke();
                ctx.setLineDash([]);

                // Halo du point
                ctx.fillStyle = strokeGrad;
                ctx.globalAlpha = 0.20;
                ctx.beginPath();
                ctx.arc(cx, cy, 6, 0, Math.PI * 2);
                ctx.fill();
                ctx.globalAlpha = 1.0;

                // Point central
                ctx.beginPath();
                ctx.arc(cx, cy, 3, 0, Math.PI * 2);
                ctx.fill();

                // Bordure blanche/fond
                ctx.lineWidth = 1.5;
                ctx.strokeStyle = Qt.rgba(bgColor.r, bgColor.g, bgColor.b, 1.0);
                ctx.stroke();

                // Valeur textuelle
                let curVal = chartRoot.preciseTemp
                ? parseFloat(pts[curIdx].toFixed(1))
                : Math.round(pts[curIdx]);
                let textToDraw = curVal.toString();
                let fontSize = Math.round(Kirigami.Units.gridUnit * 0.55);
                ctx.font = "bold " + fontSize + "px sans-serif";

                let alignText = curIdx === 0 ? "left" : (curIdx === n - 1 ? "right" : "center");
                let isNearTop = cy < pT + 25;
                ctx.textBaseline = isNearTop ? "top" : "bottom";
                let yOff = isNearTop ? cy + 12 : cy - 10;

                let pointColorStr = getFillColor(chartRoot.chartType, pts[curIdx]);
                ctx.fillStyle = "rgb(" + pointColorStr + ")";
                ctx.textAlign = alignText;
                ctx.shadowColor = Qt.rgba(bgColor.r, bgColor.g, bgColor.b, 0.6);
                ctx.shadowBlur = 4;
                ctx.shadowOffsetY = 1;
                ctx.fillText(textToDraw, cx, yOff);
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
