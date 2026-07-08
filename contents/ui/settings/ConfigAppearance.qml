import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../js/DefaultsCatalog.js" as Defaults
import "."

Item {
    id: appearancePage

    implicitWidth: Kirigami.Units.gridUnit * 46
    implicitHeight: Kirigami.Units.gridUnit * 36

    Layout.minimumWidth: Kirigami.Units.gridUnit * 32
    Layout.minimumHeight: Kirigami.Units.gridUnit * 22

    readonly property real contentMaxWidth: Kirigami.Units.gridUnit * 44
    readonly property real inputWidth: Kirigami.Units.gridUnit * 12
    readonly property real spinBoxHeight: Kirigami.Units.gridUnit * 1.8

    // SUPPRESSION des propriétés partagées cross-cards (sharedLeftLabelWidth, etc.)
    // pour éviter l'alignement fantôme avec les traductions longues.

    property alias cfg_showTemperaturePanel:  showTemperaturePanelCheck.checked
    property alias cfg_showConditionPanel:    showConditionPanelCheck.checked
    property alias cfg_reverseOrder:          reverseCheck.checked
    property alias cfg_temperatureFontSize:   temperatureFontSizeSpin.realValue
    property alias cfg_temperaturePanelBold:  temperaturePanelBoldCheck.checked
    property alias cfg_conditionFontSize:     conditionFontSizeSpin.realValue
    property alias cfg_conditionPanelBold:    conditionPanelBoldCheck.checked
    property alias cfg_preciseTemp:           preciseTempCheck.checked
    property alias cfg_showConditionExpanded: showConditionExpandedCheck.checked
    property alias cfg_conditionAlignment:    conditionAlignmentCombo.currentIndex
    property alias cfg_showAnimations:        showAnimationsCheck.checked
    property alias cfg_hoverDecimals:         hoverDecimalsCheck.checked
    property alias cfg_xAxisPrecision:        xAxisPrecisionCheck.checked
    property alias cfg_yAxisDecimals:         yAxisDecimalsCheck.checked
    property alias cfg_interactiveYAxis:      interactiveYAxisCheck.checked
    property alias cfg_borderRadius:          borderRadiusSpin.value
    property alias cfg_backgroundOpacity:     backgroundOpacitySpin.realValue

    // --- Alias muets : évite les "does not have a property called cfg_x" ---
    // (KDE tente d'initialiser TOUTES les clés de main.xml sur CHAQUE page de config)
    property var cfg_useCoordinatesIp: undefined
    property var cfg_latitudeC: undefined
    property var cfg_longitudeC: undefined
    property var cfg_temperatureUnit: undefined
    property var cfg_updateInterval: undefined
    property var cfg_forecastStartDay: undefined
    property var cfg_refreshTrigger: undefined
    property var cfg_weatherProvider: undefined
    property var cfg_apiKeyWeatherApi: undefined
    property var cfg_apiKeyTomorrow: undefined
    property var cfg_apiKeyOpenWeatherMap: undefined
    property var cfg_apiKeyVisualCrossing: undefined
    property var cfg_apiKeyPirateWeather: undefined
    property var cfg_providerMaxForecastDays: undefined
    property var cfg_detailsOrder: undefined
    property var cfg_chartsOrder: undefined
    property var cfg_forecastDayCount: undefined
    property var cfg_hasRated: undefined
    property var cfg_hasStarred: undefined
    property var cfg_shootingStarEffect: undefined
    property var cfg_rainbowEffect: undefined

    // Contreparties "Default"
    property var cfg_useCoordinatesIpDefault: undefined
    property var cfg_latitudeCDefault: undefined
    property var cfg_longitudeCDefault: undefined
    property var cfg_showConditionPanelDefault: undefined
    property var cfg_showConditionExpandedDefault: undefined
    property var cfg_conditionAlignmentDefault: undefined
    property var cfg_reverseOrderDefault: undefined
    property var cfg_temperatureUnitDefault: undefined
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
    property var cfg_hasRatedDefault: undefined
    property var cfg_hasStarredDefault: undefined
    property var cfg_shootingStarEffectDefault: undefined
    property var cfg_rainbowEffectDefault: undefined
    property string title: ""

    function restoreDefaults() {
        let d = Defaults.APPEARANCE;
        showTemperaturePanelCheck.checked = d.showTemperaturePanel;
        showConditionPanelCheck.checked = d.showConditionPanel;
        reverseCheck.checked = d.reverseOrder;
        temperatureFontSizeSpin.realValue = d.temperatureFontSize;
        temperaturePanelBoldCheck.checked = d.temperaturePanelBold;
        conditionFontSizeSpin.realValue = d.conditionFontSize;
        conditionPanelBoldCheck.checked = d.conditionPanelBold;
        preciseTempCheck.checked = d.preciseTemp;
        showConditionExpandedCheck.checked = d.showConditionExpanded;
        conditionAlignmentCombo.currentIndex = (d.conditionAlignment !== undefined) ? d.conditionAlignment : 1;
        showAnimationsCheck.checked = d.showAnimations;
        hoverDecimalsCheck.checked = d.hoverDecimals;
        xAxisPrecisionCheck.checked = d.xAxisPrecision;
        yAxisDecimalsCheck.checked = d.yAxisDecimals;
        interactiveYAxisCheck.checked = d.interactiveYAxis;
        borderRadiusSpin.value = d.borderRadius;
        backgroundOpacitySpin.realValue = d.backgroundOpacity;
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            id: contentColumn
            // Math.max(contentMaxWidth, implicitWidth): normally implicitWidth
            // (the true minimum needed by the widest card/row below, now that
            // SettingsCard propagates it — see SettingsCard.qml) stays under
            // contentMaxWidth, so this is a no-op and nothing changes for
            // languages that already fit (English, French, ...). It only
            // kicks in when a translation (e.g. Italian "Grassetto" vs
            // "Bold") makes some row's natural width exceed the usual cap —
            // in that case the column grows just enough to fit it, still
            // capped by the actual available scroll width so it can never
            // overflow the window itself.
            readonly property real effectiveWidth: Math.min(scrollView.availableWidth - Kirigami.Units.gridUnit * 2, Math.max(appearancePage.contentMaxWidth, contentColumn.implicitWidth))
            width: effectiveWidth
            x: Math.max(Kirigami.Units.gridUnit, (scrollView.availableWidth - effectiveWidth) / 2)
            spacing: Kirigami.Units.largeSpacing

            Item { Layout.preferredHeight: Kirigami.Units.gridUnit * 0.5 }

            SectionHeader { text: i18n("Panel Bar"); isFirst: true }

            SettingsCard {
                id: panelBarCard
                Item {
                    Layout.fillWidth: true;
                    implicitHeight: topGroup.implicitHeight
                    SettingGroup {
                        id: topGroup;
                        anchors.centerIn: parent; width: Math.min(implicitWidth, parent.width - Kirigami.Units.largeSpacing)
                        SettingRow {
                            label: i18n("Show:")
                            contentSpacing: Kirigami.Units.largeSpacing * 1.5
                            CheckBox { id: showTemperaturePanelCheck; text: i18n("Temperature") }
                            CheckBox { id: showConditionPanelCheck; text: i18n("Condition") }
                            CheckBox { id: reverseCheck; text: i18n("Reverse order") }
                        }
                    }
                }
                Kirigami.Separator { Layout.fillWidth: true; opacity: 0.35 }
                SplitSettingsRow {
                    leftItem: SettingGroup {
                        id: fontLeftGroup
                        // Suppression des liaisons externalLabelWidth
                        SettingRow {
                            label: i18n("Temperature size:");
                            enabled: showTemperaturePanelCheck.checked
                            SpinBox {
                                id: temperatureFontSizeSpin
                                Keys.onReturnPressed: (event) => { event.accepted = true; appearancePage.forceActiveFocus(); }; Keys.onEnterPressed: (event) => { event.accepted = true; appearancePage.forceActiveFocus(); }
                                Layout.preferredWidth: appearancePage.inputWidth * 0.4;
                                Layout.preferredHeight: appearancePage.spinBoxHeight
                                property real realValue: 11.0;
                                value: Math.round(realValue * 10); onValueModified: realValue = value / 10
                                editable: true;
                                from: 10; to: 300; stepSize: 5
                                textFromValue: (value, locale) => Number(value / 10).toLocaleString(locale, 'f', 1);
                                valueFromText: (text, locale) => Math.round(Number.fromLocaleString(locale, text) * 10)
                                Component.onCompleted: { if (contentItem && typeof contentItem.horizontalAlignment !== "undefined") contentItem.horizontalAlignment = Text.AlignHCenter }
                                Connections {
                                    target: temperatureFontSizeSpin.contentItem;
                                    ignoreUnknownSignals: true
                                    function onTextEdited() {
                                        let parsed = temperatureFontSizeSpin.valueFromText(temperatureFontSizeSpin.contentItem.text, temperatureFontSizeSpin.locale);
                                        if (!isNaN(parsed)) { let clamped = Math.max(temperatureFontSizeSpin.from, Math.min(temperatureFontSizeSpin.to, parsed)); temperatureFontSizeSpin.realValue = clamped / 10; }
                                    }
                                }
                            }
                            CheckBox { id: temperaturePanelBoldCheck; text: i18n("Bold") }
                        }
                        SettingRow {
                            label: i18n("Decimals:");
                            enabled: showTemperaturePanelCheck.checked
                            CheckBox { id: preciseTempCheck }
                            InfoIcon { text: i18n("Shows temperature values with one decimal place.") }
                        }
                    }
                    rightItem: SettingGroup {
                        id: fontRightGroup
                        // Suppression des liaisons externalLabelWidth
                        SettingRow {
                            label: i18n("Condition size:");
                            enabled: showConditionPanelCheck.checked
                            SpinBox {
                                id: conditionFontSizeSpin
                                Keys.onReturnPressed: (event) => { event.accepted = true; appearancePage.forceActiveFocus(); }; Keys.onEnterPressed: (event) => { event.accepted = true; appearancePage.forceActiveFocus(); }
                                Layout.preferredWidth: appearancePage.inputWidth * 0.4;
                                Layout.preferredHeight: appearancePage.spinBoxHeight
                                property real realValue: 10.0;
                                value: Math.round(realValue * 10); onValueModified: realValue = value / 10
                                editable: true;
                                from: 10; to: 250; stepSize: 5
                                textFromValue: (value, locale) => Number(value / 10).toLocaleString(locale, 'f', 1);
                                valueFromText: (text, locale) => Math.round(Number.fromLocaleString(locale, text) * 10)
                                Component.onCompleted: { if (contentItem && typeof contentItem.horizontalAlignment !== "undefined") contentItem.horizontalAlignment = Text.AlignHCenter }
                                Connections {
                                    target: conditionFontSizeSpin.contentItem;
                                    ignoreUnknownSignals: true
                                    function onTextEdited() {
                                        let parsed = conditionFontSizeSpin.valueFromText(conditionFontSizeSpin.contentItem.text, conditionFontSizeSpin.locale);
                                        if (!isNaN(parsed)) { let clamped = Math.max(conditionFontSizeSpin.from, Math.min(conditionFontSizeSpin.to, parsed)); conditionFontSizeSpin.realValue = clamped / 10; }
                                    }
                                }
                            }
                            CheckBox { id: conditionPanelBoldCheck; text: i18n("Bold") }
                        }
                    }
                }
            }

            SectionHeader { text: i18n("Expanded View") }

            SettingsCard {
                id: expandedViewCard
                SplitSettingsRow {
                    leftItem: SettingGroup {
                        id: expandedLeftGroup
                        // Suppression des liaisons externalLabelWidth
                        SettingRow {
                            id: expandedConditionRow
                            label: i18n("Condition:")
                            CheckBox { id: showConditionExpandedCheck }
                            FieldComboBox {
                                id: conditionAlignmentCombo
                                visible: showConditionExpandedCheck.checked
                                model: [i18n("Left"), i18n("Middle"), i18n("Right")]
                                currentIndex: 1
                            }
                            Item {
                                implicitWidth: conditionInfoIcon.implicitWidth
                                implicitHeight: conditionInfoIcon.implicitHeight
                                InfoIcon {
                                    id: conditionInfoIcon
                                    text: i18n("Displays the current weather description (e.g., Sunny, Rainy).")
                                }
                            }
                        }
                        SettingRow {
                            label: i18n("Animations:");
                            CheckBox { id: showAnimationsCheck }
                            InfoIcon { text: i18n("Shows weather animations (sun, clouds, rain, etc.) in the background.") }
                        }
                        SettingRow {
                            label: i18n("Hover decimals:");
                            CheckBox { id: hoverDecimalsCheck }
                            InfoIcon { text: i18n("Adds one decimal of precision when hovering over the chart, instead of changing in whole numbers.") }
                        }
                    }
                    rightItem: SettingGroup {
                        id: expandedRightGroup
                        // Suppression des liaisons externalLabelWidth
                        SettingRow {
                            label: i18n("X-axis precision:");
                            CheckBox { id: xAxisPrecisionCheck }
                            InfoIcon { text: i18n("Displays minutes alongside hours when hovering (e.g. 11:04 instead of 11h) for a more precise time.") }
                        }
                        SettingRow {
                            label: i18n("Y-axis precision:");
                            CheckBox { id: yAxisDecimalsCheck }
                            InfoIcon { text: i18n("Shows one decimal place on the Y-axis values.") }
                        }
                        SettingRow {
                            label: i18n("Interactive Y-axis:");
                            CheckBox { id: interactiveYAxisCheck }
                            InfoIcon { text: i18n("Hovering over the Y-axis draws a horizontal guideline and highlights every matching point on the chart.") }
                        }
                    }
                }
            }

            SectionHeader { text: i18n("Desktop Widget") }

            SettingsCard {
                id: desktopWidgetCard
                SplitSettingsRow {
                    leftItem: SettingGroup {
                        id: widgetLeftGroup
                        SettingRow {
                            label: i18n("Corner radius:")
                            SpinBox {
                                id: borderRadiusSpin
                                Keys.onReturnPressed: (event) => { event.accepted = true; appearancePage.forceActiveFocus(); }; Keys.onEnterPressed: (event) => { event.accepted = true; appearancePage.forceActiveFocus(); }
                                Layout.preferredWidth: appearancePage.inputWidth * 0.4;
                                Layout.preferredHeight: appearancePage.spinBoxHeight
                                from: 0; to: 40; stepSize: 1
                                Component.onCompleted: { if (contentItem && typeof contentItem.horizontalAlignment !== "undefined") contentItem.horizontalAlignment = Text.AlignHCenter }
                            }
                            InfoIcon { text: i18n("Rounds the widget's corners.") }
                        }
                    }
                    rightItem: SettingGroup {
                        id: widgetRightGroup
                        SettingRow {
                            label: i18n("Background opacity:")
                            SpinBox {
                                id: backgroundOpacitySpin
                                Keys.onReturnPressed: (event) => { event.accepted = true; appearancePage.forceActiveFocus(); }; Keys.onEnterPressed: (event) => { event.accepted = true; appearancePage.forceActiveFocus(); }
                                Layout.preferredWidth: appearancePage.inputWidth * 0.4;
                                Layout.preferredHeight: appearancePage.spinBoxHeight
                                property real realValue: 1.0;
                                value: Math.round(realValue * 100); onValueModified: realValue = value / 100
                                editable: true;
                                from: 0; to: 100; stepSize: 5
                                textFromValue: (value, locale) => value + " %";
                                valueFromText: (text, locale) => Math.round(Number.fromLocaleString(locale, text.replace(/%/g, "").trim()))
                                Component.onCompleted: { if (contentItem && typeof contentItem.horizontalAlignment !== "undefined") contentItem.horizontalAlignment = Text.AlignHCenter }
                                Connections {
                                    target: backgroundOpacitySpin.contentItem;
                                    ignoreUnknownSignals: true
                                    function onTextEdited() {
                                        let parsed = backgroundOpacitySpin.valueFromText(backgroundOpacitySpin.contentItem.text, backgroundOpacitySpin.locale);
                                        if (!isNaN(parsed)) { let clamped = Math.max(backgroundOpacitySpin.from, Math.min(backgroundOpacitySpin.to, parsed)); backgroundOpacitySpin.realValue = clamped / 100; }
                                    }
                                }
                            }
                            InfoIcon { text: i18n("Sets the widget's background transparency. This also works in the panel, though the result is limited by your taskbar's own behavior.") }
                        }
                    }
                }
            }

            ResetSection { message: i18n("Are you sure you want to reset all appearance settings to their default values? This action cannot be undone."); onConfirmed: appearancePage.restoreDefaults() }
            Item { Layout.preferredHeight: Kirigami.Units.gridUnit * 0.5 }
        }
    }
}
