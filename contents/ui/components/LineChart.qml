import QtQuick
import QtQuick.Layouts
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

Item {
    id: chartRoot

    property var values: []
    property color lineColor: Kirigami.Theme.highlightColor
    property string unit: ""
    property string label: ""
    property bool preciseTemp: false
    property int chartType: 0 // 0=Temp/Ressenti, 1=Hum, 2=Vent, 3=UV, 4=Pluie, 5=Nébulosité

    property bool isToday: true
    property bool viewActive: false

    property real currentHour: { let d = new Date();
        return d.getHours() + d.getMinutes() / 60; }

        function refreshCurrentHour() {
            let d = new Date();
            let h = d.getHours() + d.getMinutes() / 60;
            if (chartRoot.currentHour !== h) {
                chartRoot.currentHour = h;
            }
        }

        onViewActiveChanged: {
            if (viewActive) {
                refreshCurrentHour();
                canvas.requestPaint();
            }
        }

        Timer {
            interval: 30000
            running: chartRoot.viewActive
            repeat: true
            triggeredOnStart: true
            onTriggered: chartRoot.refreshCurrentHour()
        }

        property bool yAxisReadingEnabled: false // option utilisateur, désactivée par défaut
        property bool hoverDecimals: true   // option utilisateur, activée par défaut
        property bool xAxisPrecision: true    // option utilisateur, activée par défaut

        property real hoverIndex: -1 // index continu (ex: 13.42 = entre 13h et 14h), pas snappé à l'heure
        property real hoverYPos: -1  // position Y exacte pour la règle fluide
        property string hoverMode: "" // "x", "y" ou ""

        function arrMin(a) {
            if (!a || a.length === 0) return 0;
            let m = a[0];
            for (let i = 1; i < a.length; i++) { if (a[i] < m) m = a[i];
            }
            return m;
        }
        function arrMax(a) {
            if (!a || a.length === 0) return 1;
            let m = a[0];
            for (let i = 1; i < a.length; i++) { if (a[i] > m) m = a[i];
            }
            return m;
        }

        readonly property real minV: arrMin(values)
        readonly property real maxV: arrMax(values)

        // padLeft n'est plus une valeur figée : elle part d'un minimum
        // confortable (baselinePadLeft) que onPaint() peut ensuite agrandir
        // en mesurant (ctx.measureText) le libellé le plus large réellement
        // affiché sur l'axe Y. Ainsi, si les valeurs deviennent plus grandes
        // (3 chiffres, négatives, décimales...), la marge s'adapte toute
        // seule au lieu de couper les chiffres.
        readonly property real baselinePadLeft: (yAxisReadingEnabled || preciseTemp)
        ? Kirigami.Units.gridUnit * 1.3
        : Kirigami.Units.gridUnit * 0.9
        property real padLeft: baselinePadLeft
        readonly property real padRight:  Kirigami.Units.gridUnit * 0.6
        readonly property real padTop:    Kirigami.Units.gridUnit * 0.6
        readonly property real padBottom: Kirigami.Units.gridUnit * 1.2

        // --- CONVERSIONS COULEUR ---
        function hexToRgb(hex) {
            let h = hex.replace("#", "");
            if (h.length === 3) h = h[0] + h[0] + h[1] + h[1] + h[2] + h[2];
            return {
                r: parseInt(h.substring(0, 2), 16),
                g: parseInt(h.substring(2, 4), 16),
                b: parseInt(h.substring(4, 6), 16)
            };
        }

        function rgbToHex(r, g, b) {
            function toHex(c) {
                let v = Math.round(Math.max(0, Math.min(255, c)));
                let s = v.toString(16);
                return s.length === 1 ? "0" + s : s;
            }
            return "#" + toHex(r) + toHex(g) + toHex(b);
        }

        function hexToRgbString(hex) {
            let c = hexToRgb(hex);
            return c.r + ", " + c.g + ", " + c.b;
        }

        function rgbToHsl(r, g, b) {
            r /= 255;
            g /= 255; b /= 255;
            let max = Math.max(r, g, b), min = Math.min(r, g, b);
            let h = 0, s = 0, l = (max + min) / 2;
            if (max !== min) {
                let d = max - min;
                s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
                switch (max) {
                    case r: h = ((g - b) / d) % 6; break;
                    case g: h = (b - r) / d + 2; break;
                    default: h = (r - g) / d + 4; break;
                }
                h *= 60;
                if (h < 0) h += 360;
            }
            return { h: h, s: s, l: l };
        }

        function hslToRgb(h, s, l) {
            let c = (1 - Math.abs(2 * l - 1)) * s;
            let x = c * (1 - Math.abs(((h / 60) % 2) - 1));
            let m = l - c / 2;
            let r = 0, g = 0, b = 0;
            if (h < 60)        { r = c; g = x; b = 0; }
            else if (h < 120)  { r = x; g = c; b = 0; }
            else if (h < 180)  { r = 0; g = c; b = x; }
            else if (h < 240)  { r = 0; g = x; b = c; }
            else if (h < 300)  { r = x; g = 0; b = c; }
            else               { r = c; g = 0; b = x; }

            return {
                r: Math.round((r + m) * 255),
                g: Math.round((g + m) * 255),
                b: Math.round((b + m) * 255)
            };
        }

        function colorForValue(domain, stops, value) {
            let span = domain.top - domain.bottom;
            let pos = span !== 0 ? (domain.top - value) / span : 0;
            pos = Math.max(0, Math.min(1, pos));
            if (pos <= stops[0][0]) return stops[0][1];
            let last = stops[stops.length - 1];
            if (pos >= last[0]) return last[1];
            for (let i = 0; i < stops.length - 1; i++) {
                let s0 = stops[i], s1 = stops[i + 1];
                if (pos >= s0[0] && pos <= s1[0]) {
                    let segSpan = s1[0] - s0[0];
                    let t = segSpan > 0 ? (pos - s0[0]) / segSpan : 0;
                    let c0 = hexToRgb(s0[1]);
                    let c1 = hexToRgb(s1[1]);
                    return rgbToHex(
                        c0.r + (c1.r - c0.r) * t,
                                    c0.g + (c1.g - c0.g) * t,
                                    c0.b + (c1.b - c0.b) * t
                    );
                }
            }
            return last[1];
        }

        function relativeLuminance(r, g, b) {
            return 0.2126 * (r / 255) + 0.7152 * (g / 255) + 0.0722 * (b / 255);
        }

        function ensureReadable(colorStr, bgLum) {
            let parts = colorStr.split(",").map(function (s) { return parseFloat(s); });
            let r = parts[0], g = parts[1], b = parts[2];
            let lum = relativeLuminance(r, g, b);

            const minDiff = 0.30;
            let diff = lum - bgLum;
            if (Math.abs(diff) >= minDiff) return colorStr;

            let hsl = rgbToHsl(r, g, b);
            let lighten = (lum >= bgLum);
            let targetLum = lighten ? Math.min(1, bgLum + minDiff) : Math.max(0, bgLum - minDiff);
            let lo = lighten ? hsl.l : 0;
            let hi = lighten ? 1 : hsl.l;
            let bestL = hsl.l;
            for (let i = 0; i < 20; i++) {
                let mid = (lo + hi) / 2;
                let rgb = hslToRgb(hsl.h, hsl.s, mid);
                let midLum = relativeLuminance(rgb.r, rgb.g, rgb.b);
                bestL = mid;
                if (lighten) {
                    if (midLum < targetLum) lo = mid;
                    else hi = mid;
                } else {
                    if (midLum > targetLum) hi = mid;
                    else lo = mid;
                }
            }

            let finalRgb = hslToRgb(hsl.h, hsl.s, bestL);
            return Math.round(Math.max(0, Math.min(255, finalRgb.r))) + ", " +
            Math.round(Math.max(0, Math.min(255, finalRgb.g))) + ", " +
            Math.round(Math.max(0, Math.min(255, finalRgb.b)));
        }

        function paletteFor(type, unitText) {
            switch (type) {
                case 0: {
                    let isF = unitText.indexOf("F") !== -1;
                    return {
                        domain: isF ? { top: 113, bottom: 14 } : { top: 45, bottom: -10 },
                        stops: [
                            [0.000, "#8B0000"], [0.181, "#DC143C"], [0.272, "#FF4500"],
                            [0.363, "#FF8C00"], [0.454, "#FFD700"], [0.545, "#32CD32"],
                            [0.636, "#00BFFF"], [0.818, "#1E90FF"], [1.000, "#00008B"]
                        ]
                    };
                }
                case 1:
                    return {
                        domain: { top: 100, bottom: 0 },
                        stops: [[0.0, "#2C3E50"], [0.5, "#4A90E2"], [1.0, "#AED6F1"]]
                    };
                case 2: {
                    let isMph = unitText.indexOf("mph") !== -1;
                    return {
                        domain: { top: isMph ? 62 : 100, bottom: 0 },
                        stops: [[0.0, "#2A5070"], [0.5, "#4A7FA8"], [1.0, "#A8C8E0"]]
                    };
                }
                case 3:
                    return {
                        domain: { top: 12, bottom: 0 },
                        stops: [[0.00, "#800080"], [0.33, "#FF0000"], [0.50, "#FF8C00"], [0.75, "#FFD700"], [1.00, "#32CD32"]]
                    };
                case 4: // Probabilité de pluie (%)
                    return {
                        domain: { top: 100, bottom: 0 },
                        // pos=0.0 correspond à 100% (Sombre), pos=1.0 correspond à 0% (Clair)
                        stops: [[0.0, "#1A5276"], [0.5, "#2980B9"], [1.0, "#D4E6F1"]]
                    };
                case 5: // Nébulosité (%)
                    return {
                        domain: { top: 100, bottom: 0 },
                        // pos=0.0 correspond à 100% (Sombre), pos=1.0 correspond à 0% (Clair)
                        stops: [[0.0, "#424949"], [0.5, "#7F8C8D"], [1.0, "#E5E8E8"]]
                    };
                default:
                    return null;
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                PlasmaComponents3.Label {
                    text: chartRoot.label + (chartRoot.unit ? " (" + chartRoot.unit.trim() + ")" : "")
                    font.pixelSize: Kirigami.Units.gridUnit * 0.55
                    font.bold: true
                    color: Kirigami.Theme.textColor
                    opacity: 1.0
                }
                Item { Layout.fillWidth: true }

                PlasmaComponents3.Label {
                    text: chartRoot.values.length
                    ? (chartRoot.preciseTemp ? parseFloat(chartRoot.minV.toFixed(1)) : Math.round(chartRoot.minV)) + " – " +
                    (chartRoot.preciseTemp ? parseFloat(chartRoot.maxV.toFixed(1)) : Math.round(chartRoot.maxV))
                    : "--"
                    font.pixelSize: Kirigami.Units.gridUnit * 0.5
                    color: Kirigami.Theme.textColor
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

                    property real _entryX: -1
                    property real _entryY: -1
                    property bool _moved: false

                    onEntered: { _entryX = -1; _entryY = -1; _moved = false; }
                    onExited: { _moved = false; chartRoot.hoverIndex = -1; chartRoot.hoverYPos = -1; chartRoot.hoverMode = ""; }

                    // Pendant un défilement à la molette/pavé tactile, on
                    // suspend temporairement le suivi par la position de la
                    // souris : sans ça, le moindre micro-mouvement du
                    // pointeur (fréquent pendant un swipe trackpad) écrase
                    // immédiatement l'index qu'on vient de définir et on
                    // revient au point de départ.
                    property bool wheelNavActive: false

                    Timer {
                        id: wheelNavCooldown
                        interval: 400
                        onTriggered: parent.wheelNavActive = false
                    }

                    onPositionChanged: (mouse) => {
                        if (wheelNavActive) return;

                        if (_entryX < 0) { _entryX = mouse.x; _entryY = mouse.y; }
                        if (!_moved) {
                            let dx = mouse.x - _entryX, dy = mouse.y - _entryY;
                            if ((dx * dx + dy * dy) < 64) return;
                            _moved = true;
                        }

                        let w = canvas.width;
                        let h = canvas.height;
                        let n = chartRoot.values.length;
                        if (n < 2) return;

                        let pL = chartRoot.padLeft;
                        let pR = chartRoot.padRight;
                        let pT = chartRoot.padTop;
                        let pB = chartRoot.padBottom;

                        // --- LA VALEUR MAGIQUE POUR LA SYMÉTRIE ET L'ÉLARGISSEMENT ---
                        let margin = 25;

                        // Box de détection globale
                        let outOfBounds = mouse.x < pL - margin ||
                        mouse.x > w - pR + margin ||
                        mouse.y < pT - margin ||
                        mouse.y > h - pB + margin;

                        if (outOfBounds) {
                            chartRoot.hoverIndex = -1;
                            chartRoot.hoverYPos = -1;
                            chartRoot.hoverMode = "";
                            return;
                        }

                        let isBelowAxis = mouse.y > h - pB + 8;
                        let isYAxisBand = mouse.x < pL - 4 && !isBelowAxis;
                        if (isYAxisBand && chartRoot.yAxisReadingEnabled) {
                            chartRoot.hoverIndex = -1;
                            chartRoot.hoverMode  = "y";
                            chartRoot.hoverYPos = Math.max(pT, Math.min(mouse.y, h - pB));
                            return;
                        }

                        chartRoot.hoverYPos = -1;
                        chartRoot.hoverMode = "x";

                        let rawIdx = (mouse.x - pL) / (w - pL - pR) * (n - 1);
                        chartRoot.hoverIndex = Math.max(0, Math.min(rawIdx, n - 1));
                    }

                    // Molette / pavé tactile : avance ou recule d'un point sur la
                    // courbe, sur le même principe d'accumulateur que la liste
                    // d'icônes (le trackpad envoie une rafale de micro-deltas
                    // plutôt qu'un seul "cran" net comme la molette souris).
                    property real wheelAccum: 0
                    readonly property real wheelThreshold: 85 // plus réactif que la liste d'icônes (120)

                    onWheel: function(wheel) {
                        let n = chartRoot.values.length;
                        if (n < 2) { wheel.accepted = true; return; }

                        let delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x;
                        wheelAccum += delta;

                        // Point de départ : l'index déjà survolé, ou l'heure
                        // courante si aucun survol "x" n'est actif.
                        let base = (chartRoot.hoverMode === "x" && chartRoot.hoverIndex !== -1)
                        ? chartRoot.hoverIndex
                        : (chartRoot.isToday ? Math.max(0, Math.min(chartRoot.currentHour, n - 1)) : 0);
                        let idx = Math.round(base);

                        while (wheelAccum <= -wheelThreshold) {
                            idx = Math.min(n - 1, idx + 1);
                            wheelAccum += wheelThreshold;
                        }
                        while (wheelAccum >= wheelThreshold) {
                            idx = Math.max(0, idx - 1);
                            wheelAccum -= wheelThreshold;
                        }

                        wheelNavActive = true;
                        wheelNavCooldown.restart();
                        chartRoot.hoverYPos = -1;
                        chartRoot.hoverMode = "x";
                        chartRoot.hoverIndex = idx;
                        wheel.accepted = true;
                    }
                }

                onPaint: {
                    let ctx = getContext("2d");
                    ctx.reset();

                    let n = pts.length;
                    if (n < 2) return;

                    let w = width;
                    let h = height;
                    let range = (chartRoot.maxV - chartRoot.minV) || 1;
                    let textColor = Kirigami.Theme.textColor;
                    let bgColor   = Kirigami.Theme.backgroundColor;

                    let curIdx;
                    if (chartRoot.hoverMode === "x" && chartRoot.hoverIndex !== -1) {
                        curIdx = chartRoot.hoverIndex;
                    } else if (chartRoot.hoverMode !== "y" && chartRoot.isToday) {
                        curIdx = Math.max(0, Math.min(chartRoot.currentHour, n - 1));
                    } else {
                        curIdx = -1;
                    }

                    let bgLuminance = 0.2126 * bgColor.r + 0.7152 * bgColor.g + 0.0722 * bgColor.b;
                    let isLightTheme = bgLuminance > 0.5;
                    let axisOpacity  = 0.35;
                    let gridOpacity  = isLightTheme ? 0.22 : 0.12;
                    let guideOpacity = isLightTheme ? 0.34 : 0.22;
                    let labelOpacity = 0.80;

                    // --- padLeft dynamique ---
                    // On mesure le libellé le plus large parmi les 4 valeurs
                    // affichées sur l'axe Y (mêmes valeurs que drawYGrid,
                    // ySteps = 3) et on élargit padLeft si besoin, pour ne
                    // jamais couper les chiffres même si les valeurs
                    // deviennent plus grandes (3 chiffres, négatives...).
                    // On garde toujours au moins baselinePadLeft comme
                    // plancher pour ne pas resserrer le cas courant.
                    let yFontSizeMeasure = Math.round(Kirigami.Units.gridUnit * 0.48);
                    ctx.font = (chartRoot.yAxisReadingEnabled ? "bold " : "") + yFontSizeMeasure + "px sans-serif";
                    let widestLabelWidth = 0;
                    for (let s = 0; s <= 3; s++) {
                        let vLabel = chartRoot.minV + (range * s / 3);
                        let labelTextMeasure = chartRoot.preciseTemp
                        ? parseFloat(vLabel.toFixed(1)).toString()
                        : Math.round(vLabel).toString();
                        let textW = ctx.measureText(labelTextMeasure).width;
                        if (textW > widestLabelWidth) widestLabelWidth = textW;
                    }
                    let dynamicPadLeft = Math.max(chartRoot.baselinePadLeft, widestLabelWidth + Kirigami.Units.smallSpacing * 1.4);
                    if (Math.abs(chartRoot.padLeft - dynamicPadLeft) > 0.5) {
                        chartRoot.padLeft = dynamicPadLeft;
                    }

                    function xAt(i) { return pL + (w - pL - pR) * (i / (n - 1)); }
                    function yAt(v) { return pT + (h - pT - pB) * (1 - (v - chartRoot.minV) / range); }

                    function buildSmoothPath() {
                        ctx.moveTo(xAt(0), yAt(pts[0]));
                        for (let i = 0; i < n - 1; i++) {
                            let i0 = Math.max(0, i - 1), i3 = Math.min(n - 1, i + 2);
                            let x0 = xAt(i0), y0 = yAt(pts[i0]), x1 = xAt(i), y1 = yAt(pts[i]);
                            let x2 = xAt(i+1), y2 = yAt(pts[i+1]), x3 = xAt(i3), y3 = yAt(pts[i3]);
                            let cp1x = x1 + (x2 - x0) / 6, cp1y = y1 + (y2 - y0) / 6;
                            let cp2x = x2 - (x3 - x1) / 6, cp2y = y2 - (y3 - y1) / 6;
                            ctx.bezierCurveTo(cp1x, cp1y, cp2x, cp2y, x2, y2);
                        }
                    }

                    function drawYGrid() {
                        let ySteps = 3;
                        for (let s = 0; s <= ySteps; s++) {
                            let v  = chartRoot.minV + (range * s / ySteps);
                            let yy = yAt(v);

                            let hideLabel = false;
                            if (chartRoot.hoverMode === "y" && Math.abs(yy - chartRoot.hoverYPos) < 6) {
                                hideLabel = true;
                            }

                            if (!hideLabel) {
                                if (s > 0) {
                                    ctx.strokeStyle = Qt.rgba(textColor.r, textColor.g, textColor.b, gridOpacity);
                                    ctx.lineWidth = 0.9;
                                    ctx.beginPath();
                                    ctx.setLineDash([2, 4]);
                                    ctx.moveTo(pL, yy);
                                    ctx.lineTo(w - pR, yy);
                                    ctx.stroke();
                                    ctx.setLineDash([]);
                                }

                                let labelText = chartRoot.preciseTemp ? parseFloat(v.toFixed(1)).toString() : Math.round(v).toString();
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
                        }
                    }

                    function timeLabelFor(ci) {
                        let totalMinutes = Math.round(ci * 60);
                        let hh = Math.floor(totalMinutes / 60);
                        let mm = totalMinutes % 60;
                        if (!chartRoot.xAxisPrecision) return hh + "h";
                        return mm === 0 ? (hh + "h") : (hh + "h" + String(mm).padStart(2, "0"));
                    }

                    function drawXAxis(activeIdx, suppressList) {
                        let xLabels = [0, 6, 12, 18];
                        let xFontSize = Math.round(Kirigami.Units.gridUnit * 0.45);
                        ctx.font = xFontSize + "px sans-serif";

                        let activeCx = -1, activeHalfWidth = 0;
                        if (activeIdx !== -1) {
                            activeCx = xAt(activeIdx);
                            activeHalfWidth = ctx.measureText(timeLabelFor(activeIdx)).width / 2;
                        }

                        for (let k = 0; k < xLabels.length; k++) {
                            let xi = xLabels[k];
                            let xx = xAt(xi);
                            let lbl = xi + "h";
                            let lblHalfWidth = ctx.measureText(lbl).width / 2;
                            let isTooClose = activeIdx !== -1 &&
                            Math.abs(xx - activeCx) < (lblHalfWidth + activeHalfWidth + 2);

                            if (!isTooClose && suppressList) {
                                for (let si = 0; si < suppressList.length; si++) {
                                    if (Math.abs(xx - suppressList[si].cx) < (lblHalfWidth + suppressList[si].halfW + 2)) {
                                        isTooClose = true;
                                        break;
                                    }
                                }
                            }

                            if (!isTooClose) {
                                ctx.textAlign = "center";
                                ctx.textBaseline = "top";
                                ctx.fillStyle = Qt.rgba(textColor.r, textColor.g, textColor.b, labelOpacity);
                                ctx.shadowColor = Qt.rgba(bgColor.r, bgColor.g, bgColor.b, 0.85);
                                ctx.shadowBlur = 3;
                                ctx.fillText(lbl, xx, h - pB + 4);
                                ctx.shadowBlur = 0;
                            }

                            ctx.strokeStyle = Qt.rgba(textColor.r, textColor.g, textColor.b, axisOpacity);
                            ctx.lineWidth = 0.5;
                            ctx.beginPath();
                            ctx.moveTo(xx, h - pB);
                            ctx.lineTo(xx, h - pB + 3);
                            ctx.stroke();
                        }

                        ctx.strokeStyle = Qt.rgba(textColor.r, textColor.g, textColor.b, axisOpacity);
                        ctx.lineWidth = 0.5;
                        ctx.setLineDash([]);
                        ctx.beginPath();
                        ctx.moveTo(pL, h - pB);
                        ctx.lineTo(w - pR, h - pB);
                        ctx.stroke();
                    }

                    function drawAreaFill(colorStr) {
                        let gradFill = ctx.createLinearGradient(0, pT, 0, h - pB);
                        gradFill.addColorStop(0.0, "rgba(" + colorStr + ", 0.26)");
                        gradFill.addColorStop(0.6, "rgba(" + colorStr + ", 0.07)");
                        gradFill.addColorStop(1.0, "rgba(" + colorStr + ", 0.00)");

                        ctx.beginPath();
                        buildSmoothPath();
                        ctx.lineTo(xAt(n - 1), h - pB);
                        ctx.lineTo(xAt(0), h - pB);
                        ctx.closePath();
                        ctx.fillStyle = gradFill;
                        ctx.fill();
                    }

                    function drawCurveLine(strokeStyle) {
                        ctx.beginPath();
                        buildSmoothPath();
                        ctx.strokeStyle = strokeStyle;
                        ctx.lineWidth = 2.2;
                        ctx.lineJoin = "round";
                        ctx.lineCap = "round";
                        ctx.setLineDash([]);
                        ctx.stroke();
                    }

                    function catmullRomValue(p0, p1, p2, p3, t) {
                        let t2 = t * t, t3 = t2 * t;
                        return 0.5 * (
                            (2 * p1) +
                            (-p0 + p2) * t +
                            (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2 +
                            (-p0 + 3 * p1 - 3 * p2 + p3) * t3
                        );
                    }

                    function valueAtContinuous(ci) {
                        let i = Math.max(0, Math.min(Math.floor(ci), n - 2));
                        let t = ci - i;
                        let i0 = Math.max(0, i - 1);
                        let i2 = Math.min(i + 1, n - 1);
                        let i3 = Math.min(i + 2, n - 1);
                        return catmullRomValue(pts[i0], pts[i], pts[i2], pts[i3], t);
                    }

                    function drawMarkerX(strokeStyle, ci) {
                        let interpVal = valueAtContinuous(ci);
                        let cx = xAt(ci);
                        let cy = yAt(interpVal);

                        ctx.strokeStyle = Qt.rgba(textColor.r, textColor.g, textColor.b, guideOpacity);
                        ctx.lineWidth = 1.1;
                        ctx.setLineDash([2, 3]);
                        ctx.beginPath();
                        ctx.moveTo(cx, pT);
                        ctx.lineTo(cx, h - pB);
                        ctx.stroke();
                        ctx.setLineDash([]);

                        let timeLabel = timeLabelFor(ci);

                        let hourFontSize = Math.round(Kirigami.Units.gridUnit * 0.45);
                        ctx.font = hourFontSize + "px sans-serif";
                        ctx.textAlign = "center";
                        ctx.textBaseline = "top";
                        ctx.fillStyle = Qt.rgba(textColor.r, textColor.g, textColor.b, labelOpacity);
                        ctx.shadowColor = Qt.rgba(bgColor.r, bgColor.g, bgColor.b, 0.85);
                        ctx.shadowBlur = 3;
                        ctx.fillText(timeLabel, cx, h - pB + 4);
                        ctx.shadowBlur = 0;

                        ctx.strokeStyle = Qt.rgba(textColor.r, textColor.g, textColor.b, axisOpacity);
                        ctx.lineWidth = 0.8;
                        ctx.setLineDash([1, 2]);
                        ctx.beginPath();
                        ctx.moveTo(cx, h - pB);
                        ctx.lineTo(cx, h - pB + 3);
                        ctx.stroke();
                        ctx.setLineDash([]);

                        ctx.fillStyle = strokeStyle;
                        ctx.globalAlpha = 0.20;
                        ctx.beginPath();
                        ctx.arc(cx, cy, 6, 0, Math.PI * 2);
                        ctx.fill();
                        ctx.globalAlpha = 1.0;

                        ctx.fillStyle = strokeStyle;
                        ctx.beginPath();
                        ctx.arc(cx, cy, 3, 0, Math.PI * 2);
                        ctx.fill();
                        ctx.lineWidth = 1.5;
                        ctx.strokeStyle = Qt.rgba(bgColor.r, bgColor.g, bgColor.b, 1.0);
                        ctx.stroke();

                        let curValText = chartRoot.hoverDecimals
                        ? parseFloat(interpVal.toFixed(1)).toFixed(1)
                        : Math.round(interpVal).toString();
                        let fontSize = Math.round(Kirigami.Units.gridUnit * 0.55);
                        ctx.font = "bold " + fontSize + "px sans-serif";
                        let roundedIdx = Math.round(ci);
                        let alignText = roundedIdx <= 0 ? "left" : (roundedIdx >= n - 1 ? "right" : "center");
                        let isNearTop = cy < pT + 25;
                        ctx.textBaseline = isNearTop ? "top" : "bottom";
                        let yOff = isNearTop ? cy + 12 : cy - 10;

                        ctx.textAlign = alignText;
                        ctx.shadowColor = Qt.rgba(bgColor.r, bgColor.g, bgColor.b, 0.6);
                        ctx.shadowBlur = 4;
                        ctx.shadowOffsetY = 1;

                        let bgLum = chartRoot.relativeLuminance(bgColor.r * 255, bgColor.g * 255, bgColor.b * 255);
                        let palette2 = chartRoot.paletteFor(chartRoot.chartType, chartRoot.unit);
                        let defaultColorStr2 = Math.round(chartRoot.lineColor.r * 255) + "," +
                        Math.round(chartRoot.lineColor.g * 255) + "," +
                        Math.round(chartRoot.lineColor.b * 255);
                        let pointColorStr = palette2
                        ? chartRoot.hexToRgbString(chartRoot.colorForValue(palette2.domain, palette2.stops, interpVal))
                        : defaultColorStr2;
                        let readableColorStr = chartRoot.ensureReadable(pointColorStr, bgLum);
                        ctx.fillStyle = "rgb(" + readableColorStr + ")";
                        ctx.fillText(curValText, cx, yOff);
                        ctx.shadowColor = "transparent";
                        ctx.shadowBlur = 0;
                        ctx.shadowOffsetY = 0;
                    }

                    let defaultColorStr = Math.round(chartRoot.lineColor.r * 255) + "," +
                    Math.round(chartRoot.lineColor.g * 255) + "," +
                    Math.round(chartRoot.lineColor.b * 255);
                    let palette = chartRoot.paletteFor(chartRoot.chartType, chartRoot.unit);

                    let yModeIntersections = [];
                    if (chartRoot.hoverMode === "y" && chartRoot.hoverYPos !== -1) {
                        let gy0 = chartRoot.hoverYPos;
                        for (let ii = 0; ii < n - 1; ii++) {
                            let iy0 = yAt(pts[ii]);
                            let iy1 = yAt(pts[ii + 1]);
                            let iyMin = Math.min(iy0, iy1);
                            let iyMax = Math.max(iy0, iy1);
                            if (gy0 >= iyMin && gy0 <= iyMax) {
                                let it = (iy1 !== iy0) ? (gy0 - iy0) / (iy1 - iy0) : 0;
                                yModeIntersections.push(xAt(ii) + it * (xAt(ii + 1) - xAt(ii)));
                            }
                        }
                    }

                    let xFontPreview = Math.round(Kirigami.Units.gridUnit * 0.45);
                    ctx.font = xFontPreview + "px sans-serif";
                    let suppressList = yModeIntersections.map(function(icx) {
                        let ici = (w - pL - pR) > 0 ? (icx - pL) / (w - pL - pR) * (n - 1) : 0;
                        return { cx: icx, halfW: ctx.measureText(timeLabelFor(ici)).width / 2 };
                    });
                    drawYGrid();
                    drawXAxis(chartRoot.hoverMode === "y" ? -1 : curIdx,
                              suppressList.length > 0 ? suppressList : null);
                    let baseColorStr = palette
                    ? chartRoot.hexToRgbString(chartRoot.colorForValue(palette.domain, palette.stops, chartRoot.maxV))
                    : defaultColorStr;
                    drawAreaFill(baseColorStr);

                    let strokeStyle;
                    if (palette) {
                        strokeStyle = ctx.createLinearGradient(0, yAt(palette.domain.top), 0, yAt(palette.domain.bottom));
                        for (let i = 0; i < palette.stops.length; i++) {
                            strokeStyle.addColorStop(palette.stops[i][0], palette.stops[i][1]);
                        }
                    } else {
                        strokeStyle = chartRoot.lineColor;
                    }
                    drawCurveLine(strokeStyle);

                    if (chartRoot.hoverMode === "y") {
                        let gy = chartRoot.hoverYPos;
                        let refVal = chartRoot.minV + (1 - (gy - pT) / (h - pT - pB)) * range;
                        let intersections = yModeIntersections;

                        if (intersections.length > 0) {
                            let lastX = intersections[intersections.length - 1];
                            ctx.strokeStyle = Qt.rgba(textColor.r, textColor.g, textColor.b, guideOpacity);
                            ctx.lineWidth = 1.0;
                            ctx.setLineDash([3, 5]);
                            ctx.beginPath();
                            ctx.moveTo(pL, gy);
                            ctx.lineTo(lastX, gy);
                            ctx.stroke();
                            ctx.setLineDash([]);
                        }

                        let yLabelText = chartRoot.preciseTemp
                        ? parseFloat(refVal.toFixed(1)).toString()
                        : Math.round(refVal).toString();
                        let yFontSize = Math.round(Kirigami.Units.gridUnit * 0.50);
                        ctx.font = "bold " + yFontSize + "px sans-serif";
                        ctx.textAlign = "right";
                        ctx.textBaseline = "middle";

                        let bgLumY = chartRoot.relativeLuminance(bgColor.r * 255, bgColor.g * 255, bgColor.b * 255);
                        let refColorStr = palette
                        ? chartRoot.hexToRgbString(chartRoot.colorForValue(palette.domain, palette.stops, refVal))
                        : defaultColorStr;
                        let readableYColor = chartRoot.ensureReadable(refColorStr, bgLumY);

                        ctx.fillStyle = "rgb(" + readableYColor + ")";
                        ctx.shadowColor = Qt.rgba(bgColor.r, bgColor.g, bgColor.b, 0.85);
                        ctx.shadowBlur = 3;
                        ctx.fillText(yLabelText, pL - 4, gy);
                        ctx.shadowBlur = 0;

                        for (let k = 0; k < intersections.length; k++) {
                            let cx = intersections[k];
                            ctx.strokeStyle = Qt.rgba(textColor.r, textColor.g, textColor.b, guideOpacity * 0.7);
                            ctx.lineWidth = 0.9;
                            ctx.setLineDash([2, 4]);
                            ctx.beginPath();
                            ctx.moveTo(cx, gy);
                            ctx.lineTo(cx, h - pB);
                            ctx.stroke();
                            ctx.setLineDash([]);

                            ctx.fillStyle = "rgb(" + readableYColor + ")";
                            ctx.beginPath();
                            ctx.arc(cx, gy, 3.5, 0, Math.PI * 2);
                            ctx.fill();
                            ctx.lineWidth = 1.5;
                            ctx.strokeStyle = Qt.rgba(bgColor.r, bgColor.g, bgColor.b, 1.0);
                            ctx.stroke();
                        }

                        if (intersections.length > 0) {
                            let baseFontSizeY = Math.round(Kirigami.Units.gridUnit * 0.45);
                            let minFontSizeY  = Math.max(7, Math.round(baseFontSizeY * 0.65));
                            const labelGap = 4;

                            let rawLabels = intersections.map(function(icx) {
                                let ici = (w - pL - pR) > 0 ? (icx - pL) / (w - pL - pR) * (n - 1) : 0;
                                let roundedIci = Math.round(ici);
                                let align = roundedIci <= 0 ? "left" : (roundedIci >= n - 1 ? "right" : "center");
                                return { cx: icx, text: timeLabelFor(ici), align: align, ici: ici };
                            });

                            let labels = [];
                            for (let k = 0; k < rawLabels.length; k++) {
                                if (k === 0 || rawLabels[k].text !== rawLabels[k - 1].text) {
                                    labels.push(rawLabels[k]);
                                }
                            }

                            function labelEdges(lbl, fontSize) {
                                ctx.font = fontSize + "px sans-serif";
                                let textW = ctx.measureText(lbl.text).width;
                                let left = lbl.align === "left" ? lbl.cx
                                : lbl.align === "right" ? lbl.cx - textW
                                : lbl.cx - textW / 2;
                                return { left: left, right: left + textW };
                            }

                            let clusters = [];
                            let current = [labels[0]];
                            let prevEdges = labelEdges(labels[0], baseFontSizeY);
                            for (let k = 1; k < labels.length; k++) {
                                let edges = labelEdges(labels[k], baseFontSizeY);
                                if (edges.left < prevEdges.right + labelGap) {
                                    current.push(labels[k]);
                                } else {
                                    clusters.push(current);
                                    current = [labels[k]];
                                }
                                prevEdges = edges;
                            }
                            clusters.push(current);
                            function clusterFits(cluster, fontSize) {
                                let prevRight = null;
                                for (let i = 0; i < cluster.length; i++) {
                                    let e = labelEdges(cluster[i], fontSize);
                                    if (prevRight !== null && e.left < prevRight + labelGap) return false;
                                    prevRight = e.right;
                                }
                                return true;
                            }

                            ctx.textBaseline = "top";
                            ctx.fillStyle = Qt.rgba(textColor.r, textColor.g, textColor.b, labelOpacity);
                            ctx.shadowColor = Qt.rgba(bgColor.r, bgColor.g, bgColor.b, 0.85);
                            ctx.shadowBlur = 3;
                            for (let c = 0; c < clusters.length; c++) {
                                let cluster = clusters[c];
                                if (cluster.length === 1) {
                                    ctx.font = baseFontSizeY + "px sans-serif";
                                    ctx.textAlign = cluster[0].align;
                                    ctx.fillText(cluster[0].text, cluster[0].cx, h - pB + 4);
                                    continue;
                                }

                                let fittingSize = -1;
                                for (let fs = baseFontSizeY; fs >= minFontSizeY; fs--) {
                                    if (clusterFits(cluster, fs)) { fittingSize = fs;
                                        break; }
                                }

                                if (fittingSize !== -1) {
                                    ctx.font = fittingSize + "px sans-serif";
                                    for (let i = 0; i < cluster.length; i++) {
                                        ctx.textAlign = cluster[i].align;
                                        ctx.fillText(cluster[i].text, cluster[i].cx, h - pB + 4);
                                    }
                                } else {
                                    let sumCx = 0;
                                    let sumIci = 0;

                                    for (let i = 0; i < cluster.length; i++) {
                                        sumCx += cluster[i].cx;
                                        sumIci += cluster[i].ici;
                                    }

                                    let avgCx = sumCx / cluster.length;
                                    let avgIci = sumIci / cluster.length;

                                    let roundedAvgIci = Math.round(avgIci);
                                    let avgAlign = roundedAvgIci <= 0 ? "left" : (roundedAvgIci >= n - 1 ? "right" : "center");

                                    ctx.font = baseFontSizeY + "px sans-serif";
                                    ctx.textAlign = avgAlign;
                                    ctx.fillText(timeLabelFor(avgIci), avgCx, h - pB + 4);
                                }
                            }
                            ctx.shadowBlur = 0;
                        }

                    } else if (curIdx !== -1) {
                        drawMarkerX(strokeStyle, curIdx);
                    }
                }

                Component.onCompleted: requestPaint()
            }
        }

        onValuesChanged:      canvas.requestPaint()
        onWidthChanged:       canvas.requestPaint()
        onHeightChanged:      canvas.requestPaint()
        onCurrentHourChanged: canvas.requestPaint()
        onHoverIndexChanged:  canvas.requestPaint()
        onHoverYPosChanged:   canvas.requestPaint()
        onHoverModeChanged:   canvas.requestPaint()

        Connections {
            target: Kirigami.Theme
            function onTextColorChanged() { canvas.requestPaint(); }
            function onBackgroundColorChanged() { canvas.requestPaint(); }
            function onHighlightColorChanged() { canvas.requestPaint(); }
        }
}
