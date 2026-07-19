import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../js/ProviderRegistry.js" as Registry
import "../js/DetailsCatalog.js" as Catalog
import "../js/DefaultsCatalog.js" as Defaults
import "."

Item {
    id: dataPage

    implicitWidth: Kirigami.Units.gridUnit * 50
    implicitHeight: Kirigami.Units.gridUnit * 38

    Layout.minimumWidth: Kirigami.Units.gridUnit * 34
    Layout.minimumHeight: Kirigami.Units.gridUnit * 24

    readonly property real contentMaxWidth: Kirigami.Units.gridUnit * 44
    readonly property real inputWidth: Kirigami.Units.gridUnit * 12
    readonly property real spinBoxHeight: Kirigami.Units.gridUnit * 1.8

    property alias cfg_detailsOrder: detailsOrderHidden.text
    property alias cfg_chartsOrder: chartsOrderHidden.text
    property alias cfg_combinedCharts: combinedChartsHidden.text
    property alias cfg_forecastStartDay: startDaySpin.value
    property alias cfg_forecastDayCount: dayCountSpin.value
    property alias cfg_forecastVisibleDayCount: visibleDayCountSpin.value

    // --- Alias muets : évite les "does not have a property called cfg_x" ---
    property var cfg_useCoordinatesIp: undefined
    property var cfg_latitudeC: undefined
    property var cfg_longitudeC: undefined
    property var cfg_showConditionPanel: undefined
    property var cfg_showLocationExpanded: undefined
    property var cfg_conditionAlignment: undefined
    property var cfg_forecastHoverZoneSize: undefined
    property var cfg_reverseOrder: undefined
    property var cfg_temperatureUnit: undefined
    property var cfg_windSpeedUnit: undefined
    property var cfg_temperatureFontSize: undefined
    property var cfg_conditionFontSize: undefined
    property var cfg_showTemperaturePanel: undefined
    property var cfg_preciseTemp: undefined
    property var cfg_yAxisDecimals: undefined
    property var cfg_updateInterval: undefined
    property var cfg_temperaturePanelBold: undefined
    property var cfg_conditionPanelBold: undefined
    property var cfg_showAnimations: undefined
    property var cfg_refreshTrigger: undefined
    property var cfg_borderRadius: undefined
    property var cfg_backgroundOpacity: undefined
    property var cfg_interactiveYAxis: undefined
    property var cfg_hoverDecimals: undefined
    property var cfg_xAxisPrecision: undefined
    property var cfg_apiKeyWeatherApi: undefined
    property var cfg_apiKeyTomorrow: undefined
    property var cfg_apiKeyOpenWeatherMap: undefined
    property var cfg_apiKeyVisualCrossing: undefined
    property var cfg_apiKeyPirateWeather: undefined
    property var cfg_providerMaxForecastDays: undefined
    property var cfg_hasRated: undefined
    property var cfg_hasStarred: undefined
    property var cfg_shootingStarEffect: undefined
    property var cfg_rainbowEffect: undefined

    // Contreparties "Default"
    property var cfg_useCoordinatesIpDefault: undefined
    property var cfg_latitudeCDefault: undefined
    property var cfg_longitudeCDefault: undefined
    property var cfg_showConditionPanelDefault: undefined
    property var cfg_showLocationExpandedDefault: undefined
    property var cfg_showConditionExpandedDefault: undefined
    property var cfg_conditionAlignmentDefault: undefined
    property var cfg_forecastHoverZoneSizeDefault: undefined
    property var cfg_reverseOrderDefault: undefined
    property var cfg_temperatureUnitDefault: undefined
    property var cfg_windSpeedUnitDefault: undefined
    property var cfg_temperatureFontSizeDefault: undefined
    property var cfg_conditionFontSizeDefault: undefined
    property var cfg_showTemperaturePanelDefault: undefined
    property var cfg_preciseTempDefault: undefined
    property var cfg_yAxisDecimalsDefault: undefined
    property var cfg_updateIntervalDefault: undefined
    property var cfg_forecastStartDayDefault: undefined
    property var cfg_temperaturePanelBoldDefault: undefined
    property var cfg_conditionPanelBoldDefault: undefined
    property var cfg_showAnimationsDefault: undefined
    property var cfg_refreshTriggerDefault: undefined
    property var cfg_borderRadiusDefault: undefined
    property var cfg_backgroundOpacityDefault: undefined
    property var cfg_interactiveYAxisDefault: undefined
    property var cfg_hoverDecimalsDefault: undefined
    property var cfg_xAxisPrecisionDefault: undefined
    property var cfg_weatherProviderDefault: undefined
    property var cfg_apiKeyWeatherApiDefault: undefined
    property var cfg_apiKeyTomorrowDefault: undefined
    property var cfg_apiKeyOpenWeatherMapDefault: undefined
    property var cfg_apiKeyVisualCrossingDefault: undefined
    property var cfg_apiKeyPirateWeatherDefault: undefined
    property var cfg_providerMaxForecastDaysDefault: undefined
    property var cfg_detailsOrderDefault: undefined
    property var cfg_chartsOrderDefault: undefined
    property var cfg_forecastDayCountDefault: undefined
    property var cfg_forecastVisibleDayCountDefault: undefined
    property var cfg_combinedChartsDefault: undefined
    property var cfg_hasRatedDefault: undefined
    property var cfg_hasStarredDefault: undefined
    property var cfg_shootingStarEffectDefault: undefined
    property var cfg_rainbowEffectDefault: undefined
    property string title: ""

    property string cfg_weatherProvider: "openmeteo"

    property var detailsOrderModel: []
    property var chartsOrderModel: []
    // Paires de courbes fusionnées : [[idPrincipal, idSecondaire], ...]. idSecondaire
    // est toujours celui tracé en pointillé. N'importe quelles 2 courbes du catalogue
    // peuvent être choisies ; une paire n'a d'effet que si ses 2 courbes sont aussi
    // cochées dans "Chart Tabs" (voir activeCombinedCharts / canPairCharts ci-dessous).
    property var combinedChartsModel: []
    property bool pageReady: false
    property bool suppressDaysMessage: false

    readonly property string providerId: cfg_weatherProvider

    function getProviderMaxDays(pId) {
        if (pId === "tomorrowio") return 5;
        if (pId === "pirateweather") return 7;
        if (pId === "openweathermap") return 8;
        if (pId === "metnorway") return 9;
        if (pId === "weatherapi") return 14;
        if (pId === "visualcrossing") return 15;
        return 16;
    }

    readonly property int currentMaxApiDays: getProviderMaxDays(providerId)

    readonly property int catalogMaxCount: Catalog.getCatalog().filter(function (item) { return item.selectable !== false; }).length

    // Vrai seulement quand idA et idB sont tous les deux cochés dans "Chart Tabs" et
    // distincts : c'est la seule situation où fusionner ces 2 courbes a un sens.
    function canPairCharts(idA, idB) {
        return !!idA && !!idB && idA !== idB &&
        dataPage.chartsOrderModel.indexOf(idA) !== -1 &&
        dataPage.chartsOrderModel.indexOf(idB) !== -1;
    }

    // Options disponibles pour les sélecteurs "Add fusion" : toutes les courbes
    // actuellement cochées dans Chart Tabs, sauf celles à exclure (typiquement l'id
    // déjà choisi dans l'autre sélecteur, pour ne pas pouvoir fusionner un id avec lui-même).
    function fusionOptionsModel(excludeIds) {
        let ex = excludeIds || [];
        return dataPage.chartsOrderModel
        .filter(function (id) { return ex.indexOf(id) === -1; })
        .map(function (id) { return { text: dataPage.catalogItem(id).longLabelKey, value: id }; });
    }

    // Ajoute (ou remplace) une fusion idA+idB. Une courbe ne pouvant appartenir qu'à
    // une seule fusion à la fois, toute paire existante impliquant idA ou idB est
    // retirée avant d'ajouter la nouvelle.
    function addCombinedPair(idA, idB) {
        if (!dataPage.canPairCharts(idA, idB)) return;
        let model = dataPage.combinedChartsModel.filter(function (p) {
            return !(Array.isArray(p) && (p[0] === idA || p[1] === idA || p[0] === idB || p[1] === idB));
        });
        model.push([idA, idB]);
        dataPage.combinedChartsModel = model;
        combinedChartsHidden.text = JSON.stringify(model);
    }

    function removeCombinedPair(idA, idB) {
        let model = dataPage.combinedChartsModel.filter(function (p) {
            return !(Array.isArray(p) && p[0] === idA && p[1] === idB);
        });
        dataPage.combinedChartsModel = model;
        combinedChartsHidden.text = JSON.stringify(model);
    }

    // Inverse l'ordre de la paire, ce qui change laquelle des deux courbes est en pointillé.
    function swapCombinedPair(idA, idB) {
        let model = dataPage.combinedChartsModel.map(function (p) {
            if (Array.isArray(p) && p[0] === idA && p[1] === idB) return [idB, idA];
            return p;
        });
        dataPage.combinedChartsModel = model;
        combinedChartsHidden.text = JSON.stringify(model);
    }

    property alias cfg_showConditionExpanded: conditionExpandedHolder.value
    Item { id: conditionExpandedHolder; property bool value: true }

    readonly property bool conditionPanelEnabled: cfg_showConditionExpanded
    readonly property int detailsMaxCount: conditionPanelEnabled ? catalogMaxCount : Math.min(Catalog.getCompactDetailsMaxCount(), catalogMaxCount)

    ListModel { id: detailsDisplayModel }
    ListModel { id: chartsDisplayModel }

    function restoreDefaults() {
        detailsOrderHidden.text = JSON.stringify(Defaults.DATA.detailsOrder);
        chartsOrderHidden.text = JSON.stringify(Defaults.DATA.chartsOrder);
        combinedChartsHidden.text = JSON.stringify(Defaults.DATA.combinedCharts);
        startDaySpin.value = Defaults.DATA.forecastStartDay;
        dayCountSpin.value = Defaults.DATA.forecastDayCount;
        visibleDayCountSpin.value = Defaults.DATA.forecastVisibleDayCount;
        dataPage.adjustToProvider();
    }

    function populateDisplayModel(listModel, orderModel) {
        let ids = displayOrder(orderModel);
        listModel.clear();
        for (let i = 0; i < ids.length; i++) {
            listModel.append({ metricId: ids[i] });
        }
    }

    component MetricList: Column {
        id: listRoot
        Layout.fillWidth: true
        spacing: 0
        property var displayModel: null
        property var orderModel: []
        property int maxCount: 9999
        property var toggleFn: function (id, supported) {}
        property var moveFn: function (index, delta) {}
        property var catalogItemFn: function (id) { return { id: id, longLabelKey: id }; }
        property string providerId: ""
        move: Transition { NumberAnimation { properties: "y"; duration: 240; easing.type: Easing.OutCubic } }

        readonly property real rowMinWidth: Kirigami.Units.gridUnit * 2
        + Kirigami.Units.gridUnit * 6
        + Kirigami.Units.gridUnit * 1.5
        + Kirigami.Units.gridUnit * 1.7 * 2
        + Kirigami.Units.smallSpacing * 4
        Layout.minimumWidth: rowMinWidth

        Repeater {
            model: listRoot.displayModel
            delegate: Column {
                id: rowWrap; width: listRoot.width; spacing: 0
                property string metricId: model.metricId
                property var catItem: listRoot.catalogItemFn(metricId)
                property bool supported: Registry.isDetailSupported(listRoot.providerId, metricId)
                property int selIndex: listRoot.orderModel.indexOf(metricId)
                property bool selected: selIndex !== -1
                property bool atLimit: !selected && listRoot.orderModel.length >= listRoot.maxCount

                RowLayout {
                    width: rowWrap.width; height: Kirigami.Units.gridUnit * 1.9; spacing: Kirigami.Units.smallSpacing
                    CheckBox { checked: rowWrap.selected; enabled: rowWrap.supported && (rowWrap.selected || !rowWrap.atLimit); onToggled: listRoot.toggleFn(rowWrap.metricId, rowWrap.supported) }
                    Label { Layout.fillWidth: true; Layout.minimumWidth: Kirigami.Units.gridUnit * 6; text: rowWrap.catItem.longLabelKey; elide: Text.ElideRight; opacity: rowWrap.supported ? (rowWrap.selected ? 1.0 : 0.75) : 0.35 }
                    Label { text: i18n("Unsupported"); visible: !rowWrap.supported; font.italic: true; font.pointSize: Kirigami.Theme.smallFont.pointSize; opacity: 0.5 }
                    Rectangle {
                        visible: rowWrap.selected; Layout.preferredWidth: Kirigami.Units.gridUnit * 1.5; Layout.preferredHeight: Kirigami.Units.gridUnit * 1.5; radius: width / 2; color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.18)
                        Label { anchors.centerIn: parent; text: rowWrap.selIndex + 1; font.bold: true; font.pointSize: Kirigami.Theme.smallFont.pointSize; color: Kirigami.Theme.highlightColor }
                    }
                    ToolButton { icon.name: "go-up"; display: AbstractButton.IconOnly; implicitWidth: Kirigami.Units.gridUnit * 1.7; implicitHeight: implicitWidth; enabled: rowWrap.selected && rowWrap.selIndex > 0; onClicked: listRoot.moveFn(rowWrap.selIndex, -1); ToolTip.text: i18n("Move up"); ToolTip.visible: hovered; ToolTip.delay: Kirigami.Units.toolTipDelay }
                    ToolButton { icon.name: "go-down"; display: AbstractButton.IconOnly; implicitWidth: Kirigami.Units.gridUnit * 1.7; implicitHeight: implicitWidth; enabled: rowWrap.selected && rowWrap.selIndex < listRoot.orderModel.length - 1; onClicked: listRoot.moveFn(rowWrap.selIndex, 1); ToolTip.text: i18n("Move down"); ToolTip.visible: hovered; ToolTip.delay: Kirigami.Units.toolTipDelay }
                }
                Kirigami.Separator { width: rowWrap.width; opacity: 0.4; visible: index < listRoot.displayModel.count - 1 }
            }
        }
    }

    component MetricCard: ColumnLayout {
        id: card
        Layout.fillWidth: true; Layout.minimumWidth: metricsCard.Layout.minimumWidth; Layout.alignment: Qt.AlignTop; spacing: Kirigami.Units.smallSpacing
        property string title: ""; property string infoText: ""; property var displayModel: null; property var orderModel: []; property int maxCount: 9999
        property var toggleFn: function (id, supported) {}; property var moveFn: function (index, delta) {}; property var catalogItemFn: function (id) { return { id: id, longLabelKey: id }; }; property string providerId: ""
        property bool emptyStateEnabled: false; property string emptyStateIcon: "office-chart-line"; property string emptyStateText: ""

        RowLayout {
            Layout.fillWidth: true; spacing: Kirigami.Units.smallSpacing
            Label { text: card.title; opacity: 0.85; elide: Text.ElideRight }
            InfoIcon { text: card.infoText }
            Item { Layout.fillWidth: true; Layout.minimumWidth: 0 }
            Label { text: card.orderModel.length + i18n(" / ") + card.maxCount; opacity: 0.55; font.pointSize: Kirigami.Theme.smallFont.pointSize; Layout.rightMargin: Kirigami.Units.largeSpacing }
        }

        SettingsCard {
            id: metricsCard
            MetricList { displayModel: card.displayModel; orderModel: card.orderModel; maxCount: card.maxCount; toggleFn: card.toggleFn; moveFn: card.moveFn; catalogItemFn: card.catalogItemFn; providerId: card.providerId }
            RowLayout {
                Layout.fillWidth: true; Layout.topMargin: Kirigami.Units.smallSpacing; visible: card.emptyStateEnabled && card.orderModel.length === 0; spacing: Kirigami.Units.smallSpacing
                Item { Layout.fillWidth: true }
                Kirigami.Icon { source: card.emptyStateIcon; Layout.preferredWidth: Kirigami.Units.iconSizes.small; Layout.preferredHeight: Kirigami.Units.iconSizes.small; opacity: 0.3 }
                Label { text: card.emptyStateText; opacity: 0.45; font.italic: true; font.pointSize: Kirigami.Theme.smallFont.pointSize }
                Item { Layout.fillWidth: true }
            }
        }
    }

    TextField {
        id: detailsOrderHidden; visible: false; text: "[]"
        onTextChanged: { try { let parsed = JSON.parse(text); if (Array.isArray(parsed) && JSON.stringify(parsed) !== JSON.stringify(dataPage.detailsOrderModel)) { dataPage.detailsOrderModel = parsed; dataPage.populateDisplayModel(detailsDisplayModel, parsed); } } catch (e) {} }
    }

    TextField {
        id: chartsOrderHidden; visible: false; text: "[]"
        onTextChanged: { try { let parsed = JSON.parse(text); if (Array.isArray(parsed) && JSON.stringify(parsed) !== JSON.stringify(dataPage.chartsOrderModel)) { dataPage.chartsOrderModel = parsed; dataPage.populateDisplayModel(chartsDisplayModel, parsed); } } catch (e) {} }
    }

    TextField {
        id: combinedChartsHidden; visible: false; text: "[]"
        onTextChanged: { try { let parsed = JSON.parse(text); if (Array.isArray(parsed) && JSON.stringify(parsed) !== JSON.stringify(dataPage.combinedChartsModel)) { dataPage.combinedChartsModel = parsed; } } catch (e) {} }
    }

    function toggleDetail(id, supported) {
        if (!supported) return;
        let beforeIds = displayOrder(detailsOrderModel); let oldIndex = beforeIds.indexOf(id);
        let model = detailsOrderModel.slice(); let idx = model.indexOf(id);
        if (idx !== -1) { model.splice(idx, 1); } else { if (model.length >= dataPage.detailsMaxCount) return; model.push(id); }
        detailsOrderModel = model; detailsOrderHidden.text = JSON.stringify(model);
        let afterIds = displayOrder(model); let newIndex = afterIds.indexOf(id);
        if (oldIndex !== -1 && newIndex !== -1 && oldIndex !== newIndex) { detailsDisplayModel.move(oldIndex, newIndex, 1); }
    }

    function toggleChart(id, supported) {
        if (!supported) return;
        let beforeIds = displayOrder(chartsOrderModel); let oldIndex = beforeIds.indexOf(id);
        let model = chartsOrderModel.slice(); let idx = model.indexOf(id);
        if (idx !== -1) { model.splice(idx, 1); } else { if (model.length >= dataPage.catalogMaxCount) return; model.push(id); }
        chartsOrderModel = model; chartsOrderHidden.text = JSON.stringify(model);
        let afterIds = displayOrder(model); let newIndex = afterIds.indexOf(id);
        if (oldIndex !== -1 && newIndex !== -1 && oldIndex !== newIndex) { chartsDisplayModel.move(oldIndex, newIndex, 1); }
    }

    function moveDetail(index, delta) {
        let model = detailsOrderModel.slice(); let target = index + delta;
        if (target < 0 || target >= model.length) return;
        let tmp = model[index]; model[index] = model[target]; model[target] = tmp;
        detailsOrderModel = model; detailsOrderHidden.text = JSON.stringify(model); detailsDisplayModel.move(index, target, 1);
    }

    function moveChart(index, delta) {
        let model = chartsOrderModel.slice(); let target = index + delta;
        if (target < 0 || target >= model.length) return;
        let tmp = model[index]; model[index] = model[target]; model[target] = tmp;
        chartsOrderModel = model; chartsOrderHidden.text = JSON.stringify(model); chartsDisplayModel.move(index, target, 1);
    }

    function displayOrder(orderModel) {
        let catalog = Catalog.getCatalog().filter(function (item) { return item.selectable !== false; });
        let ids = catalog.map(function (item) { return item.id; });
        let rest = ids.filter(function (id) { return orderModel.indexOf(id) === -1; });
        return orderModel.concat(rest);
    }

    function catalogItem(id) { return Catalog.findDetail(id) || { id: id, longLabelKey: id }; }

    function adjustToProvider() {
        let resultDetails = Registry.adjustDetailsForProvider(detailsOrderModel, providerId);
        if (resultDetails.changed) {
            let newJson = JSON.stringify(resultDetails.order);
            if (detailsOrderHidden.text !== newJson) { detailsOrderModel = resultDetails.order; detailsOrderHidden.text = newJson; }
        }

        let resultCharts = Registry.adjustDetailsForProvider(chartsOrderModel, providerId);
        if (resultCharts.changed) {
            let newJson = JSON.stringify(resultCharts.order);
            if (chartsOrderHidden.text !== newJson) { chartsOrderModel = resultCharts.order; chartsOrderHidden.text = newJson; }
        }

        populateDisplayModel(detailsDisplayModel, detailsOrderModel);
        populateDisplayModel(chartsDisplayModel, chartsOrderModel);
        if (pageReady && (resultDetails.changed || resultCharts.changed)) { autoSwitchMessage.visible = true; }
        else if (pageReady) { autoSwitchMessage.visible = false; }
    }

    function showDaysAdjustedMessage(newCount) {
        offsetClampMessage.type = Kirigami.MessageType.Information;
        offsetClampMessage.text = i18n("Days shown reduced to %1 to fit the new start day.", newCount);
        offsetClampMessage.visible = true;
        hideOffsetMessageTimer.restart();
    }

    function showMinDaysMessage(minValue) {
        offsetClampMessage.type = Kirigami.MessageType.Information;
        offsetClampMessage.text = i18n("Days shown cannot go below the minimum forecast length of %1.", minValue);
        offsetClampMessage.visible = true;
        hideOffsetMessageTimer.restart();
    }

    onProviderIdChanged: adjustToProvider()

    onDetailsMaxCountChanged: {
        if (detailsOrderModel.length > detailsMaxCount) {
            let trimmed = detailsOrderModel.slice(0, detailsMaxCount);
            detailsOrderModel = trimmed; detailsOrderHidden.text = JSON.stringify(trimmed);
            populateDisplayModel(detailsDisplayModel, trimmed);
        }
    }
    Component.onCompleted: Qt.callLater(function () { dataPage.adjustToProvider(); dataPage.pageReady = true; })

    Timer { id: hideOffsetMessageTimer; interval: 3500; onTriggered: offsetClampMessage.visible = false }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            id: contentColumn
            readonly property real effectiveWidth: Math.min(scrollView.availableWidth - Kirigami.Units.gridUnit * 2, Math.max(dataPage.contentMaxWidth, contentColumn.implicitWidth))
            width: effectiveWidth
            x: Math.max(Kirigami.Units.gridUnit, (scrollView.availableWidth - effectiveWidth) / 2)
            spacing: Kirigami.Units.largeSpacing

            Item { Layout.preferredHeight: Kirigami.Units.gridUnit * 0.5 }

            SectionHeader { text: i18n("Forecast Range"); isFirst: true }

            SettingsCard {
                id: forecastCard

                SplitSettingsRow {
                    leftItem: SettingGroup {
                        id: leftGroup
                        SettingRow {
                            label: i18n("Start day offset:")
                            SpinBox {
                                id: startDaySpin
                                editable: true
                                Keys.onReturnPressed: (event) => { event.accepted = true; dataPage.forceActiveFocus(); }; Keys.onEnterPressed: (event) => { event.accepted = true; dataPage.forceActiveFocus(); }
                                Layout.preferredWidth: dataPage.inputWidth * 0.4; Layout.preferredHeight: dataPage.spinBoxHeight
                                from: 0
                                to: dataPage.pageReady ? Math.max(0, dataPage.currentMaxApiDays - 3) : 999
                                stepSize: 1
                                Component.onCompleted: { if (contentItem && typeof contentItem.horizontalAlignment !== "undefined") { contentItem.horizontalAlignment = Text.AlignHCenter; } }
                                Connections {
                                    target: startDaySpin.contentItem; ignoreUnknownSignals: true
                                    function onTextEdited() {
                                        let parsed = parseInt(startDaySpin.contentItem.text);
                                        if (!isNaN(parsed)) {
                                            let clamped = Math.max(startDaySpin.from, Math.min(startDaySpin.to, parsed));
                                            if (parsed !== clamped) dataPage.suppressDaysMessage = true;
                                            if (startDaySpin.value !== clamped) startDaySpin.value = clamped;
                                        }
                                    }
                                }
                                onToChanged: { if (pageReady && value > to) { dataPage.suppressDaysMessage = true; value = to; } }
                            }
                            InfoIcon { text: i18n("Delays the forecast start by a specific number of days.") }
                        }
                    }
                    rightItem: SettingGroup {
                        id: rightGroup
                        SettingRow {
                            label: i18n("Days to display:")
                            SpinBox {
                                id: dayCountSpin
                                editable: true
                                Keys.onReturnPressed: (event) => { event.accepted = true; dataPage.forceActiveFocus(); }; Keys.onEnterPressed: (event) => { event.accepted = true; dataPage.forceActiveFocus(); }
                                Layout.preferredWidth: dataPage.inputWidth * 0.4; Layout.preferredHeight: dataPage.spinBoxHeight
                                from: 3
                                to: dataPage.pageReady ? Math.max(3, dataPage.currentMaxApiDays - startDaySpin.value) : 999
                                stepSize: 1
                                Component.onCompleted: { if (contentItem && typeof contentItem.horizontalAlignment !== "undefined") { contentItem.horizontalAlignment = Text.AlignHCenter; } }
                                Connections {
                                    target: dayCountSpin.contentItem; ignoreUnknownSignals: true
                                    function onTextEdited() {
                                        let parsed = parseInt(dayCountSpin.contentItem.text);
                                        if (!isNaN(parsed)) {
                                            let clamped = Math.max(dayCountSpin.from, Math.min(dayCountSpin.to, parsed));
                                            if (dayCountSpin.value !== clamped) dayCountSpin.value = clamped;
                                        }
                                    }
                                }
                                onToChanged: {
                                    if (pageReady && value > to) {
                                        value = to;
                                        if (!dataPage.suppressDaysMessage) { dataPage.showDaysAdjustedMessage(value); }
                                    }
                                    dataPage.suppressDaysMessage = false;
                                }
                                onValueModified: { if (value <= from) dataPage.showMinDaysMessage(from); }
                            }
                            InfoIcon { text: i18n("Number of days to display in the forecast view.") }
                        }
                        SettingRow {
                            label: i18n("Visible at once:")
                            SpinBox {
                                id: visibleDayCountSpin
                                editable: true
                                Keys.onReturnPressed: (event) => { event.accepted = true; dataPage.forceActiveFocus(); }; Keys.onEnterPressed: (event) => { event.accepted = true; dataPage.forceActiveFocus(); }
                                Layout.preferredWidth: dataPage.inputWidth * 0.4; Layout.preferredHeight: dataPage.spinBoxHeight
                                // 0 = Auto : recalculé dynamiquement dans le widget (largeur réelle +
                                // nombre de détails sélectionnés), voir FullRepresentation.qml::autoVisibleDayCount.
                                from: 0
                                // Ne peut jamais dépasser le nombre de jours réellement affichés
                                // (dayCountSpin), ni un maximum de 7 colonnes (au-delà, les colonnes
                                // deviennent trop étroites pour rester lisibles).
                                to: dataPage.pageReady ? Math.max(1, Math.min(7, dayCountSpin.value)) : 7
                                stepSize: 1
                                textFromValue: function (value) { return value === 0 ? i18n("Auto") : value.toString(); }
                                valueFromText: function (text) {
                                    let parsed = parseInt(text);
                                    return isNaN(parsed) ? 0 : parsed;
                                }
                                Component.onCompleted: { if (contentItem && typeof contentItem.horizontalAlignment !== "undefined") { contentItem.horizontalAlignment = Text.AlignHCenter; } }
                                Connections {
                                    target: visibleDayCountSpin.contentItem; ignoreUnknownSignals: true
                                    function onTextEdited() {
                                        let raw = visibleDayCountSpin.contentItem.text;
                                        if (raw.trim().length === 0) return;
                                        let parsed = parseInt(raw);
                                        if (!isNaN(parsed)) {
                                            let clamped = Math.max(visibleDayCountSpin.from, Math.min(visibleDayCountSpin.to, parsed));
                                            if (visibleDayCountSpin.value !== clamped) visibleDayCountSpin.value = clamped;
                                        }
                                    }
                                }
                                onToChanged: { if (pageReady && value > to) value = to; }
                            }
                            InfoIcon { text: i18n("How many forecast days show at once before scrolling. Icons keep a readable size, so fewer columns appear if space is tight. Auto adjusts this to the widget's width and how many details are selected.") }
                        }
                    }
                }
                Kirigami.InlineMessage { id: offsetClampMessage; Layout.fillWidth: true; visible: false; Layout.topMargin: Kirigami.Units.smallSpacing }
            }

            SectionHeader { text: i18n("Metrics") }

            Kirigami.InlineMessage { id: autoSwitchMessage; Layout.fillWidth: true; visible: false; type: Kirigami.MessageType.Information; text: i18n("Some previously selected metrics were not supported by the current provider and were adjusted automatically.") }

            GridLayout {
                id: metricsGrid
                Layout.fillWidth: true
                columns: scrollView.availableWidth < Kirigami.Units.gridUnit * 38 ? 1 : 2
                columnSpacing: Kirigami.Units.largeSpacing
                rowSpacing: Kirigami.Units.largeSpacing

                MetricCard {
                    Layout.fillWidth: true
                    // FIX: Force mathématiquement la distribution à 50/50 absolue
                    Layout.preferredWidth: metricsGrid.columns === 1 ? metricsGrid.width : (metricsGrid.width - Kirigami.Units.largeSpacing) / 2
                    Layout.alignment: Qt.AlignTop
                    title: i18n("Text Details");
                    infoText: dataPage.conditionPanelEnabled ? i18n("Weather details shown in the expanded view, in this order.") : i18n("Weather details shown in the expanded view, in this order. Since Condition is disabled in Appearance, up to 4 details can be selected here.")
                    displayModel: detailsDisplayModel;
                    orderModel: dataPage.detailsOrderModel; maxCount: dataPage.detailsMaxCount; toggleFn: dataPage.toggleDetail; moveFn: dataPage.moveDetail; catalogItemFn: dataPage.catalogItem;
                    providerId: dataPage.providerId
                }

                MetricCard {
                    Layout.fillWidth: true
                    // FIX: Force mathématiquement la distribution à 50/50 absolue
                    Layout.preferredWidth: metricsGrid.columns === 1 ? metricsGrid.width : (metricsGrid.width - Kirigami.Units.largeSpacing) / 2
                    Layout.alignment: Qt.AlignTop
                    title: i18n("Chart Tabs");
                    infoText: i18n("Charts available to swipe through. If none are selected, charts are disabled.")
                    displayModel: chartsDisplayModel;
                    orderModel: dataPage.chartsOrderModel; maxCount: dataPage.catalogMaxCount; toggleFn: dataPage.toggleChart; moveFn: dataPage.moveChart; catalogItemFn: dataPage.catalogItem; providerId: dataPage.providerId; emptyStateEnabled: true;
                    emptyStateText: i18n("No charts selected. The chart view is disabled.")
                }
            }

            // Fusion de courbes : combine n'importe quelles 2 courbes cochées ci-dessus
            // sur un même graphique à 2 axes Y, la seconde étant tracée en pointillé.
            // Une paire reste mémorisée même si l'une de ses courbes est décochée
            // (elle redevient simplement inactive), pour ne pas perdre le réglage.
            ColumnLayout {
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
                spacing: Kirigami.Units.smallSpacing

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing
                    Label { text: i18n("Chart Fusion"); opacity: 0.85 }
                    InfoIcon { text: i18n("Overlay two chart tabs on a single graph with two Y axes. The second curve of a pair is always drawn dashed.") }
                    Item { Layout.fillWidth: true }
                }

                SettingsCard {
                    id: fusionCard
                    Layout.fillWidth: true

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        visible: dataPage.combinedChartsModel.length > 0

                        Repeater {
                            model: dataPage.combinedChartsModel
                            delegate: ColumnLayout {
                                id: pairRow
                                Layout.fillWidth: true
                                spacing: 0
                                readonly property var pair: modelData
                                readonly property bool pairActive: Array.isArray(pair) && pair.length === 2 && dataPage.canPairCharts(pair[0], pair[1])

                                RowLayout {
                                    Layout.fillWidth: true
                                    height: Kirigami.Units.gridUnit * 1.9
                                    spacing: Kirigami.Units.smallSpacing

                                    Label {
                                        Layout.fillWidth: true
                                        textFormat: Text.StyledText
                                        text: dataPage.catalogItem(pairRow.pair[0]).longLabelKey
                                        + " + <i>" + dataPage.catalogItem(pairRow.pair[1]).longLabelKey + "</i> "
                                        + "<i>" + i18n("(dashed)") + "</i>"
                                        elide: Text.ElideRight
                                        opacity: pairRow.pairActive ? 1.0 : 0.45
                                    }
                                    Label {
                                        visible: !pairRow.pairActive
                                        text: i18n("inactive")
                                        font.italic: true
                                        opacity: 0.6
                                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                                    }
                                    ToolButton {
                                        // Glyphe de double flèche plutôt qu'une icône du thème système
                                        // (ex: "view-refresh", une flèche circulaire qui évoque plutôt
                                        // "recharger" qu'"inverser") : garanti identique sur toutes les
                                        // distributions/thèmes d'icônes, sans dépendance externe.
                                        text: "⇄"
                                        display: AbstractButton.TextOnly
                                        implicitWidth: Kirigami.Units.gridUnit * 1.7; implicitHeight: implicitWidth
                                        onClicked: dataPage.swapCombinedPair(pairRow.pair[0], pairRow.pair[1])
                                        ToolTip.text: i18n("Swap which curve is dashed"); ToolTip.visible: hovered; ToolTip.delay: Kirigami.Units.toolTipDelay
                                    }
                                    ToolButton {
                                        icon.name: "edit-delete"
                                        display: AbstractButton.IconOnly
                                        implicitWidth: Kirigami.Units.gridUnit * 1.7; implicitHeight: implicitWidth
                                        onClicked: dataPage.removeCombinedPair(pairRow.pair[0], pairRow.pair[1])
                                        ToolTip.text: i18n("Remove this fusion"); ToolTip.visible: hovered; ToolTip.delay: Kirigami.Units.toolTipDelay
                                    }
                                }
                                Kirigami.Separator { Layout.fillWidth: true; opacity: 0.4 }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: Kirigami.Units.smallSpacing
                        // N'affiche ce message que si l'utilisateur a déjà de quoi créer
                        // une fusion (2+ onglets cochés) mais ne l'a pas encore fait ;
                        // sinon le message "Select at least 2 chart tabs..." plus bas
                        // explique déjà la situation, et les deux ensemble faisaient
                        // doublon.
                        visible: dataPage.combinedChartsModel.length === 0 && dataPage.chartsOrderModel.length >= 2
                        spacing: Kirigami.Units.smallSpacing
                        Item { Layout.fillWidth: true }
                        Label { text: i18n("No chart fusions configured."); opacity: 0.45; font.italic: true; font.pointSize: Kirigami.Theme.smallFont.pointSize }
                        Item { Layout.fillWidth: true }
                    }

                    // Ligne d'ajout : 2 sélecteurs (la 2e liste exclut l'id choisi dans la 1re,
                    // pour ne pas pouvoir fusionner une courbe avec elle-même) + bouton Add.
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: Kirigami.Units.smallSpacing
                        visible: dataPage.chartsOrderModel.length >= 2
                        spacing: Kirigami.Units.smallSpacing

                        ComboBox {
                            id: fusionFirstCombo
                            Layout.fillWidth: true
                            textRole: "text"
                            valueRole: "value"
                            model: dataPage.fusionOptionsModel([])
                        }
                        Label { text: "+"; opacity: 0.6 }
                        ComboBox {
                            id: fusionSecondCombo
                            Layout.fillWidth: true
                            textRole: "text"
                            valueRole: "value"
                            model: dataPage.fusionOptionsModel([fusionFirstCombo.currentValue])
                        }
                        ToolButton {
                            text: i18n("Add")
                            icon.name: "list-add"
                            enabled: dataPage.canPairCharts(fusionFirstCombo.currentValue, fusionSecondCombo.currentValue)
                            onClicked: dataPage.addCombinedPair(fusionFirstCombo.currentValue, fusionSecondCombo.currentValue)
                        }
                    }

                    Label {
                        Layout.fillWidth: true
                        visible: dataPage.chartsOrderModel.length < 2
                        text: i18n("Select at least 2 chart tabs above to create a fusion.")
                        wrapMode: Text.WordWrap
                        opacity: 0.5
                        font.italic: true
                        font.pointSize: Kirigami.Theme.smallFont.pointSize
                    }
                }
            }

            ResetSection { message: i18n("Are you sure you want to reset all data metrics and forecast ranges to their default values? This action cannot be undone."); onConfirmed: dataPage.restoreDefaults() }
            Item { Layout.preferredHeight: Kirigami.Units.gridUnit * 0.5 }
        }
    }
}
