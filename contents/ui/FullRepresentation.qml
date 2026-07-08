import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import "components" as Components
import "js/DetailsCatalog.js" as Catalog
import org.kde.kirigami as Kirigami

Item {
    id: rootItem

    property var weatherData
    property int temperatureUnit: root.temperatureUnit

    // 0 = gauche, 1 = milieu, 2 = droite. Réglable dans Apparence > Vue
    // étendue, s'applique aussi bien en mode panneau qu'en mode bureau
    // (voir conditionLabel dans le header).
    readonly property int conditionAlignment: Plasmoid.configuration.conditionAlignment

    readonly property string unitStr: (parseInt(temperatureUnit) === 0) ? "°C" : "°F"
    readonly property string currentTempText: (weatherData && weatherData.currentTemperatureRounded) ? weatherData.currentTemperatureRounded : "--"

    readonly property var detailsOrderIds: {
        try {
            let parsed = JSON.parse(Plasmoid.configuration.detailsOrder || "[]");
            return Array.isArray(parsed) ? parsed : [];
        } catch (e) {
            return [];
        }
    }

    // Lit l'ordre des graphiques de manière indépendante
    readonly property var chartsOrderIds: {
        try {
            let parsed = JSON.parse(Plasmoid.configuration.chartsOrder || "[]");
            return Array.isArray(parsed) ? parsed : [];
        } catch (e) {
            return [];
        }
    }

    // Source unique de vérité : DetailsCatalog.js (partagée avec
    // ConfigData.qml::detailsMaxCount). Sécurité indépendante : même si le
    // clamp côté page de config n'a pas (encore) réécrit cfg_detailsOrder
    // (ex. désactivation de Condition sans réouvrir la page Data, config
    // modifiée manuellement, etc.), la vue compacte n'affichera jamais plus
    // de ce nombre d'éléments.
    readonly property int compactDetailsMaxCount: Catalog.getCompactDetailsMaxCount()

    readonly property bool anyDetailEnabled: detailsOrderIds.length > 0
    // Si la personne a tout décoché, cette propriété est fausse et bloque les clics
    readonly property bool anyChartEnabled: chartsOrderIds.length > 0

    readonly property bool showBottomDetails: !!(anyDetailEnabled && root.showConditionExpanded)

    property int selectedDayIndex: -1
    property int activeChart: 0

    readonly property var hourlyData: (weatherData && weatherData.weatherData && weatherData.weatherData.hourly) ? weatherData.weatherData.hourly : null
    readonly property bool hasHourlyData: !!hourlyData
    readonly property var dailyData: (weatherData && weatherData.weatherData && weatherData.weatherData.daily) ? weatherData.weatherData.daily : null

    readonly property int currentDayIndex: {
        if (!dailyData) return 0;
        let today = new Date();
        let todayStr = today.getFullYear() + "-" +
        String(today.getMonth() + 1).padStart(2, "0") + "-" +
        String(today.getDate()).padStart(2, "0");
        let times = dailyData.time;
        for (let i = 0; i < times.length; i++) {
            if (times[i] === todayStr) return i;
        }
        return 0;
    }

    // Génération simplifiée et propre des courbes
    readonly property var chartDefs: {
        let defs = [];
        for (let i = 0; i < chartsOrderIds.length; i++) {
            let cat = Catalog.findDetail(chartsOrderIds[i]);
            if (!cat) continue;

            let targetField = cat.hourlyField;
            if (!hourlyData || !hourlyData[targetField]) continue;
            defs.push({
                field: targetField,
                label: cat.labelKey,
                tabLabel: cat.tabLabelKey,
                unit: cat.unitFn(temperatureUnit),
                      color: cat.color,
                      chartType: cat.chartType
            });
        }
        return defs;
    }

    function hourlySlice(fieldName) {
        if (!hourlyData || !hourlyData[fieldName] || selectedDayIndex < 0) return [];
        let start = selectedDayIndex * 24;
        return hourlyData[fieldName].slice(start, start + 24);
    }

    function openDayDetail(dayIndex) {
        if (hasHourlyData && anyChartEnabled) {
            activeChart = 0;
            selectedDayIndex = dayIndex;
        }
    }

    function closeDayDetail() {
        selectedDayIndex = -1;
    }

    function resetScroll() {
        forecastSection.positionViewAtBeginning();
        closeDayDetail();
    }

    // Largeur "confortable" d'une colonne jour (icône + textes), calquée sur
    // la taille actuelle où 3 colonnes tiennent dans fixedWidth.
    readonly property real dayColumnWidth: fixedWidth / 3

    // Nombre de jours disponibles dans les données (respecte forecastStartDay)
    readonly property int availableDayCount: (dailyData && dailyData.time) ? Math.max(0, dailyData.time.length - root.forecastStartDay) : 0

    // Nombre de colonnes à afficher simultanément : au minimum 3 (comportement
    // actuel dans le popup du panneau), et plus si le widget est élargi sur le
    // bureau — sans jamais dépasser le nombre de jours réellement disponibles.
    readonly property int visibleDayCount: {
        if (availableDayCount <= 0) return 3;
        let fit = Math.max(3, Math.floor(forecastSection.width / dayColumnWidth));
        return Math.min(fit, availableDayCount);
    }

    // Vrai uniquement quand le widget est posé directement sur le bureau
    // (mode "Bureau"). Dans la popup du panneau, on garde une taille fixe.
    readonly property bool isDesktopMode: Plasmoid.formFactor === PlasmaCore.Types.Planar

    readonly property int fixedWidth: Kirigami.Units.gridUnit * 15

    // Largeur minimale d'une colonne de détail pour que le libellé et la
    // valeur ne se chevauchent jamais (ex: "Wind Speed" / "12 km/h").
    readonly property real detailMinColumnWidth: Kirigami.Units.gridUnit * 3.2
    readonly property int detailsCount: (showBottomDetails && detailsRow.visibleDetails) ? detailsRow.visibleDetails.length : 0
    readonly property real detailsRequiredWidth: detailsCount > 0 ? (detailsCount * detailMinColumnWidth) + Kirigami.Units.gridUnit + (detailsCount * Kirigami.Units.smallSpacing * 2) : 0

    // Largeur réelle du contenu : ne descend jamais sous fixedWidth, mais
    // grandit automatiquement si les détails sélectionnés ont besoin de plus
    // de place, aussi bien en popup panneau qu'en taille par défaut sur le
    // bureau.
    readonly property real contentWidth: Math.max(fixedWidth, detailsRequiredWidth)

    readonly property int calculatedHeight: {
        let base = Kirigami.Units.gridUnit * 12.5;
        return (showBottomDetails) ? base : (base - Kirigami.Units.gridUnit * 2.5);
    }

    // En mode bureau, on suit la taille imposée par l'utilisateur (poignées
    // de redimensionnement) au lieu d'imposer une taille fixe.
    width: isDesktopMode && parent ? parent.width : contentWidth
    height: isDesktopMode && parent ? parent.height : calculatedHeight

    Layout.minimumWidth: contentWidth
    Layout.minimumHeight: calculatedHeight
    Layout.preferredWidth: contentWidth
    Layout.preferredHeight: calculatedHeight
    // En mode panneau/popup, la largeur suit contentWidth (peut grandir avec
    // le nombre de détails) ; en mode bureau, on autorise un agrandissement
    // libre au-delà de ce minimum.
    Layout.maximumWidth: isDesktopMode ? Kirigami.Units.gridUnit * 60 : contentWidth
    Layout.maximumHeight: isDesktopMode ? Kirigami.Units.gridUnit * 40 : calculatedHeight

    Item {
        id: backgroundClipWrapper
        anchors { fill: parent; margins: Plasmoid.configuration.showAnimations ? -8 : 0 }
        z: -1

        layer.enabled: true
        layer.smooth: true
        layer.effect: OpacityMask {
            maskSource: backgroundMaskShape
        }

        Rectangle {
            id: backgroundMaskShape
            anchors.fill: parent
            radius: root.borderRadius
            color: "white"
            visible: false
        }

        Rectangle {
            id: backgroundContainer
            anchors.fill: parent
            color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, root.backgroundOpacity)
            radius: root.borderRadius
            clip: true

            layer.enabled: !!Plasmoid.configuration.showAnimations
            layer.smooth: true

            Item {
                id: animationsLayers
                anchors.fill: parent
                visible: !!(Plasmoid.configuration.showAnimations && weatherData && weatherData.weatherData && weatherData.currentTemperature !== "--")

                readonly property bool dayDetailActive: rootItem.selectedDayIndex !== -1

                readonly property int weatherCode: {
                    if (dayDetailActive) {
                        if (dayLineChart && dayLineChart.hoverIndex !== -1 && rootItem.hasHourlyData) {
                            let codeSlice = rootItem.hourlySlice("weather_code");
                            let hc = codeSlice[animationsLayers.viewedHour];
                            if (hc !== undefined && hc !== null) return parseInt(hc);
                        }
                        if (rootItem.selectedDayIndex === rootItem.currentDayIndex) {
                            return weatherData && weatherData.weatherCode ? parseInt(weatherData.weatherCode) : 0;
                        }
                        if (rootItem.dailyData && rootItem.dailyData.weather_code) {
                            let code = rootItem.dailyData.weather_code[rootItem.selectedDayIndex];
                            return (code !== undefined && code !== null) ? parseInt(code) : 0;
                        }
                        return 0;
                    }
                    return weatherData && weatherData.weatherCode ? parseInt(weatherData.weatherCode) : 0;
                }

                readonly property int viewedMinutes: {
                    if (dayDetailActive && dayLineChart && dayLineChart.hoverIndex !== -1) {
                        return Math.round(dayLineChart.hoverIndex * 60);
                    }
                    let now = new Date();
                    return now.getHours() * 60 + now.getMinutes();
                }
                readonly property int viewedHour: Math.floor(viewedMinutes / 60)

                function minutesFromIso(iso) {
                    if (!iso) return null;
                    let t = iso.split("T")[1];
                    if (!t) return null;
                    let p = t.split(":");
                    return parseInt(p[0]) * 60 + parseInt(p[1]);
                }

                function isDayAt(dayIdx, minutesOfDay) {
                    let sunrise = (rootItem.dailyData && rootItem.dailyData.sunrise) ? minutesFromIso(rootItem.dailyData.sunrise[dayIdx]) : null;
                    let sunset  = (rootItem.dailyData && rootItem.dailyData.sunset)  ? minutesFromIso(rootItem.dailyData.sunset[dayIdx])  : null;
                    if (sunrise === null || sunset === null) {
                        let h = Math.floor(minutesOfDay / 60);
                        return (h >= 7 && h <= 20);
                    }
                    return minutesOfDay >= sunrise && minutesOfDay < sunset;
                }

                readonly property real windValue: {
                    if (dayDetailActive && rootItem.hasHourlyData) {
                        let windSlice = rootItem.hourlySlice("wind_speed_10m");
                        let v = windSlice[animationsLayers.viewedHour];
                        return (v !== undefined) ? parseFloat(v) : 0;
                    }
                    return weatherData && weatherData.windSpeed && weatherData.windSpeed !== "--" ? parseFloat(weatherData.windSpeed) : 0;
                }

                readonly property bool isDay: {
                    if (!dayDetailActive) {
                        if (weatherData && weatherData.weatherData && weatherData.weatherData.current) {
                            return weatherData.weatherData.current.is_day === 1;
                        }
                        return isDayAt(rootItem.currentDayIndex, viewedMinutes);
                    }
                    return isDayAt(rootItem.selectedDayIndex, viewedMinutes);
                }

                Loader { anchors.fill: parent; active: !!(Plasmoid.configuration.showAnimations && animationsLayers.visible); source: "animations/Sun.qml"; opacity: animationsLayers.isDay ? 1.0 : 0.0; visible: opacity > 0.01; Behavior on opacity { NumberAnimation { duration: 1100; easing.type: Easing.InOutSine } } }
                Loader { anchors.fill: parent; active: !!(Plasmoid.configuration.showAnimations && animationsLayers.visible); source: "animations/Night.qml"; opacity: animationsLayers.isDay ? 0.0 : 1.0; visible: opacity > 0.01; Behavior on opacity { NumberAnimation { duration: 1100; easing.type: Easing.InOutSine } } }

                readonly property bool showCloud:   weatherCode >= 3 && weatherCode !== 45 && weatherCode !== 48
                readonly property bool showStorm:   weatherCode >= 95
                readonly property bool showSnow:    (weatherCode >= 71 && weatherCode <= 77) || weatherCode === 85 || weatherCode === 86
                readonly property bool showRain:    (weatherCode >= 61 && weatherCode <= 67) || (weatherCode >= 80 && weatherCode <= 82)
                readonly property bool showDrizzle: weatherCode >= 51 && weatherCode <= 57
                readonly property bool showMist:    weatherCode === 45 || weatherCode === 48

                readonly property bool showRainbow: animationsLayers.isDay && (weatherCode === 80 || weatherCode === 81)

                Loader { anchors.fill: parent; active: !!(Plasmoid.configuration.showAnimations && animationsLayers.visible); source: "animations/Cloud.qml"; opacity: animationsLayers.showCloud ? 1.0 : 0.0; visible: opacity > 0.01; Behavior on opacity { NumberAnimation { duration: 1100; easing.type: Easing.InOutSine } } }
                Loader { anchors.fill: parent; active: !!(Plasmoid.configuration.showAnimations && animationsLayers.visible); source: "animations/Storm.qml"; opacity: animationsLayers.showStorm ? 1.0 : 0.0; visible: opacity > 0.01; Behavior on opacity { NumberAnimation { duration: 1100; easing.type: Easing.InOutSine } } }
                Loader { anchors.fill: parent; active: !!(Plasmoid.configuration.showAnimations && animationsLayers.visible); source: "animations/Snow.qml"; opacity: animationsLayers.showSnow ? 1.0 : 0.0; visible: opacity > 0.01; Behavior on opacity { NumberAnimation { duration: 1100; easing.type: Easing.InOutSine } } }
                Loader { anchors.fill: parent; active: !!(Plasmoid.configuration.showAnimations && animationsLayers.visible); source: "animations/Rain.qml"; opacity: animationsLayers.showRain ? 1.0 : 0.0; visible: opacity > 0.01; Behavior on opacity { NumberAnimation { duration: 1100; easing.type: Easing.InOutSine } } }
                Loader { anchors.fill: parent; active: !!(Plasmoid.configuration.showAnimations && Plasmoid.configuration.rainbowEffect && animationsLayers.visible); source: "animations/Rainbow.qml"; opacity: animationsLayers.showRainbow ? 1.0 : 0.0; visible: opacity > 0.01; Behavior on opacity { NumberAnimation { duration: 1100; easing.type: Easing.InOutSine } } }
                Loader { anchors.fill: parent; active: !!(Plasmoid.configuration.showAnimations && animationsLayers.visible); source: "animations/Drizzle.qml"; opacity: animationsLayers.showDrizzle ? 1.0 : 0.0; visible: opacity > 0.01; Behavior on opacity { NumberAnimation { duration: 1100; easing.type: Easing.InOutSine } } }
                Loader { anchors.fill: parent; active: !!(Plasmoid.configuration.showAnimations && animationsLayers.visible); source: "animations/Mist.qml"; opacity: animationsLayers.showMist ? 1.0 : 0.0; visible: opacity > 0.01; Behavior on opacity { NumberAnimation { duration: 1100; easing.type: Easing.InOutSine } } }
                Loader { anchors.fill: parent; active: !!(Plasmoid.configuration.showAnimations && animationsLayers.visible); source: "animations/Wind.qml"; opacity: animationsLayers.windValue >= 20 ? 1.0 : 0.0; visible: opacity > 0.01; Behavior on opacity { NumberAnimation { duration: 1100; easing.type: Easing.InOutSine } } }
            }
        }
    }

    Item {
        id: infoLayout
        anchors.fill: parent

        ColumnLayout {
            id: classicContent
            anchors.fill: parent
            spacing: 0

            opacity: rootItem.selectedDayIndex === -1 ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            RowLayout {
                id: headerSection
                Layout.fillWidth: true
                Layout.topMargin: -Kirigami.Units.smallSpacing
                Layout.leftMargin: Kirigami.Units.gridUnit
                Layout.rightMargin: Kirigami.Units.gridUnit
                spacing: 0

                Item { Layout.fillWidth: true; visible: !rootItem.isDesktopMode && !(conditionLabel.visible || rightSideContainer.visible) }

                Row {
                    id: tempContainer
                    spacing: 0
                    Layout.alignment: Qt.AlignVCenter

                    PlasmaComponents3.Label {
                        text: currentTempText
                        font.pixelSize: Kirigami.Units.gridUnit * 2.5
                        font.bold: true
                        leftPadding: currentTempText.length === 1 ? Kirigami.Units.gridUnit * 0.4 : 0
                        color: Kirigami.Theme.textColor
                    }
                    PlasmaComponents3.Label {
                        text: unitStr
                        font.pixelSize: Kirigami.Units.gridUnit * 1.5
                        font.bold: true
                        topPadding: Kirigami.Units.gridUnit * 0.2
                        color: Kirigami.Theme.textColor
                    }
                }

                PlasmaComponents3.Label {
                    id: conditionLabel
                    visible: !!root.showConditionExpanded
                    Layout.alignment: Qt.AlignVCenter
                    Layout.fillWidth: true
                    Layout.leftMargin: Kirigami.Units.gridUnit * 0.6

                    text: weatherData ? weatherData.weatherLongText : ""
                    font.pixelSize: text.length <= 10 ? Kirigami.Units.gridUnit * 1.3 : Kirigami.Units.gridUnit * 1.0
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2

                    horizontalAlignment: {
                        switch (rootItem.conditionAlignment) {
                            case 0: return Text.AlignLeft;
                            case 2: return Text.AlignRight;
                            default: return Text.AlignHCenter;
                        }
                    }
                    verticalAlignment: Text.AlignVCenter
                    color: Kirigami.Theme.textColor
                }

                Item {
                    Layout.fillWidth: true
                    visible: !conditionLabel.visible
                }

                ColumnLayout {
                    id: rightSideContainer
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 0
                    visible: !!(!root.showConditionExpanded && anyDetailEnabled)

                    GridLayout {
                        id: detailsGrid
                        visible: !!(!root.showConditionExpanded && anyDetailEnabled)
                        columns: 2
                        rowSpacing: Kirigami.Units.gridUnit * 0.3
                        columnSpacing: Kirigami.Units.smallSpacing
                        layoutDirection: Qt.RightToLeft
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight

                        readonly property real rightNudge: -7.5
                        Layout.rightMargin: rightNudge
                        Layout.topMargin: root.showConditionExpanded ? 0 : Kirigami.Units.gridUnit * 0.4

                        readonly property var quickStats: {
                            let ids = rootItem.detailsOrderIds.slice(0, rootItem.compactDetailsMaxCount);
                            let arr = [];
                            for (let i = 0; i < ids.length; i++) {
                                let cat = Catalog.findDetail(ids[i]);
                                if (!cat || !weatherData) continue;
                                let raw = weatherData.detailValue(ids[i]);
                                if (raw === null || raw === undefined || isNaN(raw)) continue;
                                let formatted = cat.decimals ? parseFloat(raw).toFixed(1) : Math.round(raw);
                                arr.push({
                                    label: cat.labelKey,
                                    value: formatted + weatherData.detailUnit(ids[i])
                                });
                            }
                            return arr;
                        }

                        Repeater {
                            model: detailsGrid.quickStats
                            delegate: DetailValueColumn {
                                compact: true
                                label: modelData.label
                                value: modelData.value
                            }
                        }
                    }
                }
            }

            ListView {
                id: forecastSection
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 5
                Layout.topMargin: -Kirigami.Units.gridUnit * 0.5
                spacing: 0
                orientation: ListView.Horizontal

                snapMode: ListView.SnapToItem
                boundsBehavior: Flickable.OvershootBounds
                maximumFlickVelocity: 500
                flickDeceleration: 1000
                interactive: true
                clip: true

                MouseArea {
                    id: forecastHoverMouse
                    anchors.fill: parent
                    z: 1
                    acceptedButtons: Qt.NoButton
                    hoverEnabled: true

                    cursorShape: (hoveredIcon && rootItem.hasHourlyData && rootItem.anyChartEnabled) ? Qt.PointingHandCursor : Qt.ArrowCursor
                    property bool hoveredIcon: false
                    property var hoveredIconRef: null

                    onPositionChanged: function(mouse) {
                        let item = forecastSection.itemAt(forecastSection.contentX + mouse.x, mouse.y);
                        if (item && item.iconItem && rootItem.hasHourlyData && rootItem.anyChartEnabled) {
                            let pt = mapToItem(item.iconItem, mouse.x, mouse.y);
                            let inside = pt.x >= 0 && pt.x <= item.iconItem.width
                            && pt.y >= 0 && pt.y <= item.iconItem.height;
                            hoveredIcon = inside;
                            hoveredIconRef = inside ? item.iconItem : null;
                        } else {
                            hoveredIcon = false;
                            hoveredIconRef = null;
                        }
                    }
                    onExited: { hoveredIcon = false; hoveredIconRef = null; }

                    property int currentIndex: 0

                    property real wheelAccum: 0
                    readonly property real wheelThreshold: 120

                    onWheel: function(wheel) {
                        let delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x;
                        let itemW = forecastSection.width / rootItem.visibleDayCount;
                        let maxIndex = Math.max(0, Math.round((forecastSection.contentWidth - forecastSection.width) / itemW));
                        wheelAccum += delta;

                        while (wheelAccum <= -wheelThreshold) {
                            currentIndex = Math.min(maxIndex, currentIndex + 1);
                            wheelAccum += wheelThreshold;
                        }
                        while (wheelAccum >= wheelThreshold) {
                            currentIndex = Math.max(0, currentIndex - 1);
                            wheelAccum -= wheelThreshold;
                        }

                        let targetX = Math.max(0, Math.min(forecastSection.contentWidth - forecastSection.width, currentIndex * itemW));
                        forecastScrollAnim.to = targetX;
                        forecastScrollAnim.restart();
                        wheel.accepted = true;
                    }
                }

                NumberAnimation {
                    id: forecastScrollAnim
                    target: forecastSection
                    property: "contentX"
                    duration: 200
                    easing.type: Easing.OutCubic
                }

                readonly property bool canScrollHorizontally: forecastSection.contentWidth > forecastSection.width + 1

                Item {
                    id: leftScrollHint
                    z: 2
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: -3.5
                    anchors.leftMargin: -1
                    width: Kirigami.Units.gridUnit * 1.55
                    height: width
                    visible: forecastSection.canScrollHorizontally
                    opacity: forecastSection.contentX > 1 ? (leftHintMouse.containsMouse ? 1.0 : 0.55) : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 3
                        radius: width / 2
                        color: Kirigami.Theme.textColor
                        opacity: leftHintMouse.containsMouse ? 0.08 : 0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: parent.width * 0.5
                        height: width
                        source: "go-previous"
                        color: Kirigami.Theme.textColor
                    }

                    MouseArea {
                        id: leftHintMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: leftScrollHint.opacity > 0
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            let itemW = forecastSection.width / rootItem.visibleDayCount;
                            let target = Math.max(0, forecastSection.contentX - itemW);
                            forecastScrollAnim.to = target;
                            forecastScrollAnim.restart();
                        }
                    }
                }

                Item {
                    id: rightScrollHint
                    z: 2
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: -3.5
                    anchors.rightMargin: -1
                    width: Kirigami.Units.gridUnit * 1.55
                    height: width
                    visible: forecastSection.canScrollHorizontally
                    opacity: forecastSection.contentX < (forecastSection.contentWidth - forecastSection.width - 1) ? (rightHintMouse.containsMouse ? 1.0 : 0.55) : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 3
                        radius: width / 2
                        color: Kirigami.Theme.textColor
                        opacity: rightHintMouse.containsMouse ? 0.08 : 0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: parent.width * 0.5
                        height: width
                        source: "go-next"
                        color: Kirigami.Theme.textColor
                    }

                    MouseArea {
                        id: rightHintMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: rightScrollHint.opacity > 0
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            let itemW = forecastSection.width / rootItem.visibleDayCount;
                            let maxX = forecastSection.contentWidth - forecastSection.width;
                            let target = Math.min(maxX, forecastSection.contentX + itemW);
                            forecastScrollAnim.to = target;
                            forecastScrollAnim.restart();
                        }
                    }
                }

                model: (rootItem.dailyData && rootItem.dailyData.time) ? (rootItem.dailyData.time.length - root.forecastStartDay) : 0

                delegate: ColumnLayout {
                    width: forecastSection.width / rootItem.visibleDayCount
                    spacing: 0
                    readonly property int dayIndex: index + root.forecastStartDay
                    property alias iconItem: hitArea

                    PlasmaComponents3.Label {
                        Layout.fillWidth: true
                        text: {
                            if (rootItem.dailyData && rootItem.dailyData.time) {
                                let d = new Date(rootItem.dailyData.time[dayIndex]);
                                return root.days ? root.days[d.getDay()] : "";
                            }
                            return "";
                        }
                        horizontalAlignment: Text.AlignHCenter
                        font.capitalization: Font.Capitalize
                        font.pixelSize: Kirigami.Units.gridUnit * 0.65
                        opacity: 0.8
                        color: Kirigami.Theme.textColor
                    }

                    Item {
                        id: iconWrapper
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 2.7
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 2.7
                        Layout.alignment: Qt.AlignHCenter

                        readonly property bool isCurrentDay: dayIndex === rootItem.currentDayIndex
                        readonly property int displayedCode: {
                            if (isCurrentDay && weatherData && weatherData.weatherCode !== undefined && weatherData.weatherCode !== "--") {
                                return parseInt(weatherData.weatherCode);
                            }
                            return (rootItem.dailyData && rootItem.dailyData.weather_code) ? rootItem.dailyData.weather_code[dayIndex] : null;
                        }

                        readonly property bool isInteractive: rootItem.hasHourlyData && rootItem.anyChartEnabled

                        Rectangle {
                            anchors.centerIn: parent
                            width: Kirigami.Units.gridUnit * 3.0
                            height: width
                            radius: width / 2
                            color: Kirigami.Theme.highlightColor
                            readonly property bool isHovered: iconWrapper.isInteractive && forecastHoverMouse.hoveredIconRef === hitArea
                            opacity: isHovered ? (dayMouse.pressed ? 0.22 : 0.13) : 0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }

                        Kirigami.Icon {
                            anchors.fill: parent
                            source: (rootItem.dailyData && iconWrapper.displayedCode !== null) ? weatherData.assignIcon(iconWrapper.displayedCode) : ""
                        }

                        Item {
                            id: hitArea
                            anchors.centerIn: parent
                            width: Kirigami.Units.gridUnit * 3.4
                            height: width
                            z: 3

                            MouseArea {
                                id: dayMouse
                                anchors.fill: parent
                                hoverEnabled: iconWrapper.isInteractive
                                enabled: iconWrapper.isInteractive
                                cursorShape: iconWrapper.isInteractive ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onClicked: rootItem.openDayDetail(dayIndex)

                                PlasmaComponents3.ToolTip {
                                    visible: dayMouse.containsMouse
                                    delay: 500
                                    text: i18n("Click for hourly details")
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 4
                        PlasmaComponents3.Label {
                            text: rootItem.dailyData ? Math.round(rootItem.dailyData.temperature_2m_max[dayIndex]) + "°" : ""
                            font.bold: true
                            font.pixelSize: Kirigami.Units.gridUnit * 0.75
                            color: Kirigami.Theme.textColor
                        }
                        PlasmaComponents3.Label {
                            text: rootItem.dailyData ? Math.round(rootItem.dailyData.temperature_2m_min[dayIndex]) + "°" : ""
                            opacity: 0.6
                            font.pixelSize: Kirigami.Units.gridUnit * 0.75
                            color: Kirigami.Theme.textColor
                        }
                    }
                }
            }

            RowLayout {
                id: detailsRow
                visible: !!showBottomDetails
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2.2
                Layout.leftMargin: Kirigami.Units.gridUnit * 0.5
                Layout.rightMargin: Kirigami.Units.gridUnit * 0.5
                spacing: Kirigami.Units.smallSpacing

                readonly property var visibleDetails: {
                    let ids = rootItem.detailsOrderIds;
                    let arr = [];
                    for (let i = 0; i < ids.length; i++) {
                        let cat = Catalog.findDetail(ids[i]);
                        if (!cat || !weatherData) continue;
                        let raw = weatherData.detailValue(ids[i]);
                        if (raw === null || raw === undefined || isNaN(raw)) continue;
                        let formatted = cat.decimals ? parseFloat(raw).toFixed(1) : Math.round(raw);
                        arr.push({
                            label: cat.bottomRowLabelKey,
                            value: formatted + weatherData.detailUnit(ids[i])
                        });
                    }
                    return arr;
                }

                Repeater {
                    model: detailsRow.visibleDetails
                    delegate: RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing
                        Rectangle {
                            visible: index > 0
                            Layout.preferredWidth: 1
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 1.2
                            color: Kirigami.Theme.textColor
                            opacity: 0.15
                            Layout.alignment: Qt.AlignVCenter
                        }
                        DetailValueColumn {
                            label: modelData.label
                            value: modelData.value
                        }
                    }
                }
            }
        }

        // ============================================================
        // === VUE DÉTAIL ===
        // ============================================================
        ColumnLayout {
            id: dayDetailView
            anchors.fill: parent
            spacing: 0

            opacity: rootItem.selectedDayIndex !== -1 ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            readonly property string dayLabelFull: {
                if (!rootItem.dailyData || rootItem.selectedDayIndex < 0) return "";
                let d = new Date(rootItem.dailyData.time[rootItem.selectedDayIndex]);
                let locale = Qt.locale();
                return d.toLocaleString(locale, "dddd");
            }

            readonly property var activeDef: (rootItem.chartDefs.length > 0)
            ? rootItem.chartDefs[Math.min(rootItem.activeChart, rootItem.chartDefs.length - 1)]
            : { field: "", label: "", unit: "", color: Kirigami.Theme.textColor, chartType: 0 }
            readonly property var activeValues: rootItem.hourlySlice(activeDef.field)
            readonly property string activeUnit: activeDef.unit
            readonly property string activeLabel: activeDef.label
            readonly property color activeColor: activeDef.color

            RowLayout {
                id: navigationHeader
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
                Layout.leftMargin: Kirigami.Units.smallSpacing
                Layout.rightMargin: Kirigami.Units.smallSpacing
                spacing: 0

                Item {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 1.6
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 1.6

                    Rectangle {
                        anchors.centerIn: parent
                        width: parent.width
                        height: parent.height
                        radius: width / 2
                        color: Kirigami.Theme.textColor
                        opacity: backMouse.pressed ? 0.15 : (backMouse.containsMouse ? 0.08 : 0.0)
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: Kirigami.Units.gridUnit * 1.0
                        height: Kirigami.Units.gridUnit * 1.0
                        source: "go-previous"
                        opacity: backMouse.pressed ? 0.6 : (backMouse.containsMouse ? 1.0 : 0.75)
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                    MouseArea {
                        id: backMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: rootItem.closeDayDetail()
                    }
                }

                PlasmaComponents3.Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    font.bold: true
                    font.capitalization: Font.Capitalize
                    text: dayDetailView.dayLabelFull
                    color: Kirigami.Theme.textColor
                }

                Item {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 1.6
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 1.6
                }
            }

            Components.LineChart {
                id: dayLineChart
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: Kirigami.Units.smallSpacing
                Layout.rightMargin: Kirigami.Units.smallSpacing
                Layout.bottomMargin: Kirigami.Units.smallSpacing

                label:       dayDetailView.activeLabel
                unit:        dayDetailView.activeUnit
                values:      dayDetailView.activeValues
                lineColor:   dayDetailView.activeColor
                isToday:     rootItem.selectedDayIndex === rootItem.currentDayIndex
                viewActive:  rootItem.selectedDayIndex !== -1

                preciseTemp: root.yAxisDecimals
                chartType:   dayDetailView.activeDef.chartType
                yAxisReadingEnabled: root.interactiveYAxis
                hoverDecimals: root.hoverDecimals
                xAxisPrecision: root.xAxisPrecision
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.smallSpacing
                Layout.rightMargin: Kirigami.Units.smallSpacing
                Layout.bottomMargin: Kirigami.Units.smallSpacing
                spacing: Kirigami.Units.smallSpacing

                component ChartTab : Rectangle {
                    property string tabLabel: ""
                    property int tabIndex: 0
                    property color tabColor: Kirigami.Theme.highlightColor

                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 1.4
                    radius: Kirigami.Units.smallSpacing

                    readonly property bool isActive: rootItem.activeChart === tabIndex
                    color: isActive
                    ? Qt.rgba(tabColor.r, tabColor.g, tabColor.b, 0.20)
                    : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.06)
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Rectangle {
                        visible: parent.isActive
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 3
                        height: 2
                        radius: 1
                        color: parent.tabColor
                    }

                    PlasmaComponents3.Label {
                        anchors.centerIn: parent
                        text: parent.tabLabel
                        font.pixelSize: Kirigami.Units.gridUnit * 0.52
                        font.bold: parent.isActive
                        color: parent.isActive ? parent.tabColor : Kirigami.Theme.textColor
                        opacity: parent.isActive ? 1.0 : 0.55
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                    TapHandler {
                        onTapped: rootItem.activeChart = parent.tabIndex
                    }
                }

                Repeater {
                    model: rootItem.chartDefs
                    delegate: ChartTab {
                        tabLabel: modelData.tabLabel
                        tabIndex: index
                        tabColor: modelData.color
                    }
                }
            }
        }
    }

    // Composant unique remplaçant les anciens CompactGridItem / DetailColumn
    // (quasi identiques à l'exception des tailles de police et de la
    // largeur). `compact: true` retrouve exactement le rendu utilisé dans le
    // header condensé ; `compact: false` (par défaut) retrouve le rendu de
    // la rangée de détails de la vue étendue.
    component DetailValueColumn : ColumnLayout {
        property string label: ""
        property string value: ""
        property bool compact: false

        spacing: 1
        Layout.fillWidth: !compact
        Layout.preferredWidth: compact ? Kirigami.Units.gridUnit * 2.2 : rootItem.detailMinColumnWidth

        readonly property real labelSize: compact ? Kirigami.Units.gridUnit * 0.50 : Kirigami.Units.gridUnit * 0.52
        readonly property real labelOpacity: compact ? 0.55 : 0.60
        readonly property real numSize: compact ? Kirigami.Units.gridUnit * 0.68 : Kirigami.Units.gridUnit * 0.72
        readonly property real degreeSuperSize: compact ? Kirigami.Units.gridUnit * 0.45 : Kirigami.Units.gridUnit * 0.48
        readonly property real degreeUnitSize: compact ? Kirigami.Units.gridUnit * 0.52 : Kirigami.Units.gridUnit * 0.55
        readonly property real percentSize: compact ? Kirigami.Units.gridUnit * 0.48 : Kirigami.Units.gridUnit * 0.54
        readonly property real speedSize: compact ? Kirigami.Units.gridUnit * 0.50 : Kirigami.Units.gridUnit * 0.53
        readonly property real degreeSuperLeftPadding: compact ? 1.2 : 0
        readonly property real degreeUnitLeftPadding: compact ? -0.5 : 0.5
        readonly property real speedBaselineOffset: compact ? -0.5 : -0.2

        PlasmaComponents3.Label {
            text: parent.label
            font.pixelSize: parent.labelSize
            opacity: parent.labelOpacity
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            color: Kirigami.Theme.textColor
        }
        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 0
            readonly property var _split: {
                let v = parent.value;
                let m = v.match(/^(-?\d+(?:\.\d+)?)\s*(.+)$/);
                return m ? { num: m[1], unit: m[2] } : { num: v, unit: "" };
            }
            readonly property string _unitType: {
                let u = _split.unit;
                if (u === "°C" || u === "°F") return "degree";
                if (u === "%") return "percent";
                return "speed";
            }
            PlasmaComponents3.Label {
                id: numLabel
                text: parent._split.num
                font.pixelSize: parent.parent.numSize
                font.bold: true
                color: Kirigami.Theme.textColor
            }
            PlasmaComponents3.Label {
                visible: parent._unitType === "degree"
                text: parent._split.unit.charAt(0)
                font.pixelSize: parent.parent.degreeSuperSize
                font.bold: true
                leftPadding: parent.parent.degreeSuperLeftPadding
                anchors.top: numLabel.top
                anchors.topMargin: 1
                color: Kirigami.Theme.textColor
            }
            PlasmaComponents3.Label {
                visible: parent._unitType === "degree"
                text: parent._split.unit.substring(1)
                font.pixelSize: parent.parent.degreeUnitSize
                font.bold: true
                leftPadding: parent.parent.degreeUnitLeftPadding
                anchors.top: numLabel.top
                anchors.topMargin: parent.parent.compact ? 2.25 : 2
                color: Kirigami.Theme.textColor
            }
            PlasmaComponents3.Label {
                visible: parent._unitType === "percent"
                text: parent._split.unit
                font.pixelSize: parent.parent.percentSize
                font.bold: true
                leftPadding: parent.parent.compact ? 3 : 2
                anchors.verticalCenter: numLabel.verticalCenter
                color: Kirigami.Theme.textColor
            }
            PlasmaComponents3.Label {
                visible: parent._unitType === "speed"
                text: parent._split.unit
                font.pixelSize: parent.parent.speedSize
                font.bold: true
                leftPadding: 2
                anchors.baseline: numLabel.baseline
                anchors.baselineOffset: parent.parent.speedBaselineOffset
                color: Kirigami.Theme.textColor
            }
        }
    }
}
