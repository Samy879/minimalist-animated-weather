import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.components 3.0 as PlasmaComponents3
import "components" as Components
import org.kde.kirigami 2.20 as Kirigami

Item {
    id: rootItem

    property var weatherData

    property string temperatureUnit: root.temperatureUnit

    readonly property string unitStr: (temperatureUnit === "0" || temperatureUnit == 0) ? "°C" : "°F"
    readonly property string currentTempText: (weatherData && weatherData.temperaturaActualPopup) ? weatherData.temperaturaActualPopup : "--"
    readonly property bool anyDetailEnabled: !!(root.showApparentTemp || root.showHumidity || root.showUVIndex || root.showWind)
    readonly property bool showBottomDetails: !!(anyDetailEnabled && root.showConditionFull)

    // --- VUE DÉTAIL JOURNALIÈRE (courbes) ---
    // -1 = vue classique. >= 0 = index du jour sélectionné.
    property int selectedDayIndex: -1

    // Courbe active dans la vue détail : 0=temp, 1=humidity, 2=wind, 3=uv
    property int activeChart: 0

    readonly property var hourlyData: (weatherData && weatherData.weatherData && weatherData.weatherData.hourly) ? weatherData.weatherData.hourly : null
    readonly property bool hasHourlyData: !!hourlyData

    // Index du jour courant dans le tableau daily
    readonly property int currentDayIndex: {
        if (!weatherData || !weatherData.weatherData || !weatherData.weatherData.daily) return 0;
        let today = new Date();
        let todayStr = today.getFullYear() + "-" +
        String(today.getMonth() + 1).padStart(2, "0") + "-" +
        String(today.getDate()).padStart(2, "0");
        let times = weatherData.weatherData.daily.time;
        for (let i = 0; i < times.length; i++) {
            if (times[i] === todayStr) return i;
        }
        return 0;
    }

    function hourlySlice(fieldName) {
        if (!hourlyData || !hourlyData[fieldName] || selectedDayIndex < 0) return [];
        let start = selectedDayIndex * 24;
        return hourlyData[fieldName].slice(start, start + 24);
    }

    function openDayDetail(dayIndex) {
        if (hasHourlyData) {
            activeChart = 0; // reset à température à chaque ouverture
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

    readonly property int fixedWidth: Kirigami.Units.gridUnit * 15
    readonly property int calculatedHeight: {
        let base = Kirigami.Units.gridUnit * 12.5;
        return (showBottomDetails) ? base : (base - Kirigami.Units.gridUnit * 2.5);
    }

    width: fixedWidth
    height: calculatedHeight
    Layout.minimumWidth: fixedWidth
    Layout.maximumWidth: fixedWidth
    Layout.preferredWidth: fixedWidth
    Layout.minimumHeight: calculatedHeight
    Layout.maximumHeight: calculatedHeight
    Layout.preferredHeight: calculatedHeight

    // --- 1. LE FOND ANIMÉ ---
    Rectangle {
        id: backgroundContainer
        anchors { fill: parent; margins: -8 }
        color: Kirigami.Theme.backgroundColor
        radius: root.borderRadius
        clip: true

        layer.enabled: !!plasmoid.configuration.showAnimations
        layer.smooth: true
        z: -1

        Item {
            id: animationsLayers
            anchors.fill: parent

            visible: !!(plasmoid.configuration.showAnimations &&
            weatherData &&
            weatherData.weatherData &&
            weatherData.temperaturaActual !== "--")

            readonly property int weatherCode: weatherData && weatherData.codeweather ? parseInt(weatherData.codeweather) : 0
            readonly property real windValue: weatherData && weatherData.windSpeed && weatherData.windSpeed !== "--" ? parseFloat(weatherData.windSpeed) : 0

            readonly property bool isDay: {
                if (weatherData && weatherData.weatherData && weatherData.weatherData.current) {
                    return weatherData.weatherData.current.is_day === 1;
                }
                let currentHour = new Date().getHours();
                return (currentHour >= 7 && currentHour <= 20);
            }

            Loader {
                anchors.fill: parent
                active: !!(plasmoid.configuration.showAnimations && animationsLayers.visible)
                source: animationsLayers.isDay ? "animations/soleil.qml" : "animations/nuit.qml"
            }
            Loader {
                anchors.fill: parent
                active: {
                    if (!plasmoid.configuration.showAnimations || !animationsLayers.visible) return false;
                    let code = animationsLayers.weatherCode;
                    return code >= 3 && code !== 45 && code !== 48;
                }
                source: "animations/nuage.qml"
            }
            Loader {
                anchors.fill: parent
                active: !!(plasmoid.configuration.showAnimations && animationsLayers.visible && source !== "")
                source: {
                    let code = animationsLayers.weatherCode;
                    if (code >= 95) return "animations/orage.qml";
                    if ((code >= 71 && code <= 77) || code === 85 || code === 86) return "animations/neige.qml";
                    if ((code >= 61 && code <= 67) || (code >= 80 && code <= 82)) return "animations/pluie.qml";
                    if (code >= 51 && code <= 57) return "animations/bruine.qml";
                    if (code === 45 || code === 48) return "animations/brume.qml";
                    return "";
                }
            }
            Loader {
                anchors.fill: parent
                active: !!(plasmoid.configuration.showAnimations && animationsLayers.visible && animationsLayers.windValue >= 20)
                source: "animations/vent.qml"
            }
        }
    }

    // --- 2. LAYOUT PRINCIPAL ---
    Item {
        id: infoLayout
        anchors.fill: parent

        // ============================================================
        // === VUE CLASSIQUE ===
        // ============================================================
        ColumnLayout {
            id: classicContent
            anchors.fill: parent
            spacing: 0
            visible: rootItem.selectedDayIndex === -1

            RowLayout {
                id: headerSection
                Layout.fillWidth: true
                Layout.topMargin: -Kirigami.Units.smallSpacing
                Layout.leftMargin: Kirigami.Units.gridUnit
                Layout.rightMargin: Kirigami.Units.gridUnit
                spacing: 0

                Item { Layout.fillWidth: true; visible: !rightSideContainer.visible }

                Row {
                    id: tempContainer
                    spacing: 0
                    Layout.alignment: Qt.AlignVCenter

                    PlasmaComponents3.Label {
                        text: currentTempText
                        font.pixelSize: Kirigami.Units.gridUnit * 2.5
                        font.bold: true
                        leftPadding: currentTempText.length === 1 ? Kirigami.Units.gridUnit * 0.4 : 0
                    }
                    PlasmaComponents3.Label {
                        text: unitStr
                        font.pixelSize: Kirigami.Units.gridUnit * 1.5
                        font.bold: true
                        topPadding: Kirigami.Units.gridUnit * 0.2
                    }
                }

                Item { Layout.fillWidth: true }

                ColumnLayout {
                    id: rightSideContainer
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 0
                    visible: !!(root.showConditionFull || anyDetailEnabled)

                    PlasmaComponents3.Label {
                        visible: !!root.showConditionFull
                        Layout.fillWidth: true
                        text: weatherData ? weatherData.weatherLongtext : ""
                        font.pixelSize: text.length <= 10 ? Kirigami.Units.gridUnit * 1.3 : Kirigami.Units.gridUnit * 1.0
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: Kirigami.Units.gridUnit * 0.55
                    }

                    GridLayout {
                        id: detailsGrid
                        visible: !!(!root.showConditionFull && anyDetailEnabled)
                        columns: 2
                        rowSpacing: Kirigami.Units.gridUnit * 0.3
                        columnSpacing: Kirigami.Units.smallSpacing
                        layoutDirection: Qt.RightToLeft
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                        Layout.rightMargin: -7.5
                        Layout.topMargin: root.showConditionFull ? 0 : Kirigami.Units.gridUnit * 0.4

                        CompactGridItem {
                            visible: !!root.showWind
                            label: i18n("Wind")
                            value: (weatherData && weatherData.windSpeed !== "--") ? (weatherData.windSpeed + (unitStr === "°C" ? " km/h" : " mph")) : "--"
                        }
                        CompactGridItem {
                            visible: !!root.showUVIndex
                            label: i18n("UV")
                            value: (weatherData && weatherData.uvIndex !== "--") ? weatherData.uvIndex : "--"
                        }
                        CompactGridItem {
                            visible: !!root.showHumidity
                            label: i18n("Hum.")
                            value: (weatherData && weatherData.humidity !== "--") ? (weatherData.humidity + "%") : "--"
                        }
                        CompactGridItem {
                            visible: !!root.showApparentTemp
                            label: i18n("Feels")
                            value: (weatherData && weatherData.apparentTemp !== "--") ? (weatherData.apparentTemp + unitStr) : "--"
                        }
                    }
                }
            }

            // --- SECTION PRÉVISIONS ---
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

                model: (weatherData && weatherData.weatherData && weatherData.weatherData.daily && weatherData.weatherData.daily.time)
                ? (weatherData.weatherData.daily.time.length - root.forecastStartDay) : 0

                delegate: ColumnLayout {
                    width: forecastSection.width / 3
                    spacing: 0
                    readonly property int dayIndex: index + root.forecastStartDay

                    PlasmaComponents3.Label {
                        Layout.fillWidth: true
                        text: {
                            if (weatherData && weatherData.weatherData && weatherData.weatherData.daily && weatherData.weatherData.daily.time) {
                                let d = new Date(weatherData.weatherData.daily.time[dayIndex]);
                                return root.days ? root.days[d.getDay()] : "";
                            }
                            return "";
                        }
                        horizontalAlignment: Text.AlignHCenter
                        font.capitalization: Font.Capitalize
                        font.pixelSize: Kirigami.Units.gridUnit * 0.65
                        opacity: 0.8
                    }

                    Kirigami.Icon {
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 2.7
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 2.7
                        Layout.alignment: Qt.AlignHCenter
                        source: (weatherData && weatherData.weatherData.daily) ? weatherData.asingicon(weatherData.weatherData.daily.weather_code[dayIndex]) : ""

                        TapHandler {
                            enabled: rootItem.hasHourlyData
                            onTapped: rootItem.openDayDetail(dayIndex)
                        }
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 4
                        PlasmaComponents3.Label {
                            text: (weatherData && weatherData.weatherData.daily) ? Math.round(weatherData.weatherData.daily.temperature_2m_max[dayIndex]) + "°" : ""
                            font.bold: true
                            font.pixelSize: Kirigami.Units.gridUnit * 0.75
                        }
                        PlasmaComponents3.Label {
                            text: (weatherData && weatherData.weatherData.daily) ? Math.round(weatherData.weatherData.daily.temperature_2m_min[dayIndex]) + "°" : ""
                            opacity: 0.6
                            font.pixelSize: Kirigami.Units.gridUnit * 0.75
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
                spacing: 0

                DetailColumn {
                    visible: !!root.showApparentTemp
                    label: i18n("Apparent Temp")
                    value: (weatherData && weatherData.apparentTemp !== "--") ? (weatherData.apparentTemp + unitStr) : "--"
                }

                Rectangle {
                    visible: !!(root.showApparentTemp && (root.showHumidity || root.showUVIndex || root.showWind))
                    Layout.preferredWidth: 1; Layout.preferredHeight: Kirigami.Units.gridUnit * 1.2;
                    color: Kirigami.Theme.textColor; opacity: 0.15; Layout.alignment: Qt.AlignVCenter
                }

                DetailColumn {
                    visible: !!root.showHumidity
                    label: i18n("Humidity")
                    value: (weatherData && weatherData.humidity !== "--") ? (weatherData.humidity + "%") : "--"
                }

                Rectangle {
                    visible: !!(root.showHumidity && (root.showUVIndex || root.showWind))
                    Layout.preferredWidth: 1; Layout.preferredHeight: Kirigami.Units.gridUnit * 1.2;
                    color: Kirigami.Theme.textColor; opacity: 0.15; Layout.alignment: Qt.AlignVCenter
                }

                DetailColumn {
                    visible: !!root.showUVIndex
                    label: i18n("UV Index")
                    value: (weatherData && weatherData.uvIndex !== "--") ? weatherData.uvIndex : "--"
                }

                Rectangle {
                    visible: !!(root.showUVIndex && root.showWind)
                    Layout.preferredWidth: 1; Layout.preferredHeight: Kirigami.Units.gridUnit * 1.2;
                    color: Kirigami.Theme.textColor; opacity: 0.15; Layout.alignment: Qt.AlignVCenter
                }

                DetailColumn {
                    visible: !!root.showWind
                    label: i18n("Wind")
                    value: (weatherData && weatherData.windSpeed !== "--") ? (weatherData.windSpeed + (unitStr === "°C" ? " km/h" : " mph")) : "--"
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
            visible: rootItem.selectedDayIndex !== -1

            readonly property string dayLabelFull: {
                if (!weatherData || !weatherData.weatherData || !weatherData.weatherData.daily || rootItem.selectedDayIndex < 0) return "";
                let d = new Date(weatherData.weatherData.daily.time[rootItem.selectedDayIndex]);
                let locale = Qt.locale();
                return d.toLocaleString(locale, "dddd");
            }

            readonly property var activeValues: {
                switch (rootItem.activeChart) {
                    case 0: return rootItem.hourlySlice("temperature_2m");
                    case 1: return rootItem.hourlySlice("relative_humidity_2m");
                    case 2: return rootItem.hourlySlice("wind_speed_10m");
                    case 3: return rootItem.hourlySlice("uv_index");
                    default: return rootItem.hourlySlice("temperature_2m");
                }
            }
            readonly property string activeUnit: {
                switch (rootItem.activeChart) {
                    case 0: return unitStr;
                    case 1: return "%";
                    case 2: return (unitStr === "°C" ? " km/h" : " mph");
                    case 3: return "";
                    default: return unitStr;
                }
            }
            readonly property string activeLabel: {
                switch (rootItem.activeChart) {
                    case 0: return i18n("Temp.");
                    case 1: return i18n("Hum.");
                    case 2: return i18n("Wind");
                    case 3: return i18n("UV Index");
                    default: return i18n("Temp.");
                }
            }
            readonly property color activeColor: {
                switch (rootItem.activeChart) {
                    case 0: return Qt.rgba(0.92, 0.62, 0.15, 1.0);
                    case 1: return Qt.rgba(0.29, 0.56, 0.88, 1.0); // Nouveau bleu doux (#4A90E2) pour l'Humidité
                    case 2: return Qt.rgba(0.13, 0.57, 0.64, 1.0); // Bleu Sarcelle / Teal pour le vent
                    case 3: return Qt.rgba(0.55, 0.25, 0.90, 1.0);
                    default: return Qt.rgba(1.0, 0.38, 0.18, 1.0);
                }
            }

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
                }

                Item {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 1.6
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 1.6
                }
            }

            Components.LineChart {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: Kirigami.Units.smallSpacing
                Layout.rightMargin: Kirigami.Units.smallSpacing
                Layout.bottomMargin: Kirigami.Units.smallSpacing

                label:       dayDetailView.activeLabel
                unit:        dayDetailView.activeUnit
                values:      dayDetailView.activeValues
                lineColor:   dayDetailView.activeColor
                // currentHour est désormais géré en interne par LineChart.qml
                // via un Timer qui se rafraîchit chaque minute. Ne pas surcharger ici.

                preciseTemp: root.preciseTempChart
                chartType:   rootItem.activeChart
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
                    }

                    TapHandler {
                        onTapped: rootItem.activeChart = parent.tabIndex
                    }
                }

                ChartTab {
                    tabLabel: i18n("Temp.")
                    tabIndex: 0
                    tabColor: Qt.rgba(0.92, 0.62, 0.15, 1.0)
                }
                ChartTab {
                    tabLabel: i18n("Hum.")
                    tabIndex: 1
                    tabColor: Qt.rgba(0.29, 0.56, 0.88, 1.0) // Nouveau bleu doux (#4A90E2)
                }
                ChartTab {
                    tabLabel: i18n("Wind")
                    tabIndex: 2
                    tabColor: Qt.rgba(0.13, 0.57, 0.64, 1.0) // Bleu Sarcelle / Teal
                }
                ChartTab {
                    tabLabel: i18n("UV")
                    tabIndex: 3
                    tabColor: Qt.rgba(0.55, 0.25, 0.90, 1.0) // Violet
                }
            }
        }
    }

    component CompactGridItem : ColumnLayout {
        property string label: ""
        property string value: ""
        spacing: 0
        Layout.preferredWidth: Kirigami.Units.gridUnit * 2.2
        PlasmaComponents3.Label {
            text: parent.label
            font.pixelSize: Kirigami.Units.gridUnit * 0.5
            opacity: 0.6
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
        }
        PlasmaComponents3.Label {
            text: parent.value
            font.pixelSize: Kirigami.Units.gridUnit * 0.65
            font.bold: true
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
        }
    }

    component DetailColumn : ColumnLayout {
        property string label: ""
        property string value: ""
        Layout.fillWidth: true
        spacing: 0
        PlasmaComponents3.Label {
            text: parent.label
            font.pixelSize: Kirigami.Units.gridUnit * 0.55
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            opacity: 0.7
        }
        PlasmaComponents3.Label {
            text: parent.value
            font.pixelSize: Kirigami.Units.gridUnit * 0.70
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
