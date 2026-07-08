import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "../js/ProviderRegistry.js" as Registry
import "../js/DefaultsCatalog.js" as Defaults
import "../js/GeoCoordinates.js" as GeoCoordinates
import "../js/GetCity.js" as GetCity
import "."

Item {
    id: sourcePage

    implicitWidth: Kirigami.Units.gridUnit * 46
    implicitHeight: Kirigami.Units.gridUnit * 34
    Layout.minimumWidth: Kirigami.Units.gridUnit * 32
    Layout.minimumHeight: Kirigami.Units.gridUnit * 20

    readonly property real contentMaxWidth: Kirigami.Units.gridUnit * 38
    readonly property real inputWidth: Kirigami.Units.gridUnit * 12
    readonly property real spinBoxHeight: Kirigami.Units.gridUnit * 1.8
    readonly property real numericFieldWidth: inputWidth * 0.4
    readonly property real coordinateFieldWidth: inputWidth * 0.34
    readonly property real providerFieldWidth: inputWidth * 0.78

    property alias cfg_useCoordinatesIp: locationModeHolder.useIp
    Item {
        id: locationModeHolder
        property bool useIp: true
        onUseIpChanged: {
            if (!useIp) {
                sourcePage.blankIfUnset(latitudeField);
                sourcePage.blankIfUnset(longitudeField);
            }
        }
    }
    property string detectedCity: ""
    property bool detectingCity: false
    property bool detectCityError: false
    property alias cfg_latitudeC: latitudeField.text
    property alias cfg_longitudeC: longitudeField.text
    property alias cfg_temperatureUnit: temperatureCombo.currentIndex
    property alias cfg_updateInterval: intervalSpin.value
    property alias cfg_weatherProvider: providerCombo.providerId
    property alias cfg_apiKeyWeatherApi: weatherApiKeyField.text
    property alias cfg_apiKeyTomorrow: tomorrowApiKeyField.text
    property alias cfg_apiKeyOpenWeatherMap: openWeatherMapKeyField.text
    property alias cfg_apiKeyVisualCrossing: visualCrossingKeyField.text
    property alias cfg_apiKeyPirateWeather: pirateWeatherKeyField.text
    // --- Alias muets : évite les "does not have a property called cfg_x" ---
    // (KDE tente d'initialiser TOUTES les clés de main.xml sur CHAQUE page de config)
    // Propriétés cfg_ non utilisées par cette page :
    property var cfg_showConditionPanel: undefined
    property var cfg_showConditionExpanded: undefined
    property var cfg_conditionAlignment: undefined
    property var cfg_reverseOrder: undefined
    property var cfg_temperatureFontSize: undefined
    property var cfg_conditionFontSize: undefined
    property var cfg_showTemperaturePanel: undefined
    property var cfg_preciseTemp: undefined
    property var cfg_yAxisDecimals: undefined
    property var cfg_forecastStartDay: undefined
    property var cfg_temperaturePanelBold: undefined
    property var cfg_conditionPanelBold: undefined
    property var cfg_showAnimations: undefined
    property var cfg_borderRadius: undefined
    property var cfg_backgroundOpacity: undefined
    property var cfg_interactiveYAxis: undefined
    property var cfg_hoverDecimals: undefined
    property var cfg_xAxisPrecision: undefined
    property var cfg_providerMaxForecastDays: undefined
    property var cfg_detailsOrder: undefined
    property var cfg_chartsOrder: undefined
    property var cfg_forecastDayCount: undefined
    property var cfg_hasRated: undefined
    property var cfg_hasStarred: undefined
    property var cfg_shootingStarEffect: undefined
    property var cfg_rainbowEffect: undefined
    // Contreparties "Default" (générées par KConfigXT), jamais utilisées par nos pages :
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

    property int cfg_refreshTrigger: 0

    property bool validatingKey: false
    property bool pageReady: false
    property bool keyRevealed: false
    property int validationToken: 0
    property var validatedKeyCache: ({})

    readonly property var activeCacheEntry: {
        let key = currentApiKey();
        if (!key) return null;
        let entry = validatedKeyCache[providerCombo.providerId];
        return (entry && entry.key === key) ? entry : null;
    }
    readonly property string keyStatus: activeCacheEntry ? activeCacheEntry.status : ""
    readonly property string keyStatusLabel: activeCacheEntry ? activeCacheEntry.label : ""
    readonly property string keyStatusMessage: activeCacheEntry ? activeCacheEntry.message : ""

    function rememberKeyResult(providerId, key, status, label, message) {
        let next = Object.assign({}, sourcePage.validatedKeyCache);
        next[providerId] = { key: key, status: status, label: label, message: message };
        sourcePage.validatedKeyCache = next;
    }

    function forgetKeyResult(providerId) {
        if (!(providerId in sourcePage.validatedKeyCache)) return;
        let next = Object.assign({}, sourcePage.validatedKeyCache);
        delete next[providerId];
        sourcePage.validatedKeyCache = next;
    }

    function currentApiKeyFor(providerId) {
        if (providerId === "weatherapi") return weatherApiKeyField.text;
        if (providerId === "tomorrowio") return tomorrowApiKeyField.text;
        if (providerId === "openweathermap") return openWeatherMapKeyField.text;
        if (providerId === "visualcrossing") return visualCrossingKeyField.text;
        if (providerId === "pirateweather") return pirateWeatherKeyField.text;
        return "";
    }

    function currentApiKey() {
        return currentApiKeyFor(providerCombo.providerId);
    }

    function eyeIconDataUrl(open, color) {
        var svg = open
        ? '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"><path d="M4.5 12c2.2-3.4 4.9-4.9 7.5-4.9s5.3 1.5 7.5 4.9c-2.2 3.4-4.9 4.9-7.5 4.9S6.7 15.4 4.5 12z" stroke="' + color + '" stroke-width="1.2" stroke-linejoin="round" stroke-linecap="round"/><circle cx="12" cy="12" r="2.3" stroke="' + color + '" stroke-width="1.2"/><circle cx="12" cy="12" r="0.8" fill="' + color + '"/></svg>'
        : '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none"><path d="M4.5 12.6c2.2-2.9 4.9-4.4 7.5-4.4s5.3 1.5 7.5 4.4" stroke="' + color + '" stroke-width="1.2" stroke-linecap="round" stroke-linejoin="round"/><path d="M9 15l-.6 1.2M12 15.6v1.4M15 15l.6 1.2" stroke="' + color + '" stroke-width="1.2" stroke-linecap="round"/></svg>';
        return "data:image/svg+xml;utf8," + encodeURIComponent(svg);
    }

    function refreshDetectedCity() {
        if (locationModeHolder.useIp) {
            sourcePage.detectingCity = true;
            sourcePage.detectCityError = false;
            GeoCoordinates.getCoordinates(function (coords) {
                if (!coords) {
                    sourcePage.detectingCity = false;
                    sourcePage.detectCityError = true;
                    sourcePage.detectedCity = "";
                    return;
                }
                sourcePage.resolveCityFromCoords(coords.lat, coords.lon);
            });
            return;
        }

        let lat = latitudeField.text.trim();
        let lon = longitudeField.text.trim();
        let hasMeaningfulCoords = lat !== "" && lon !== "" && !(lat === "0" && lon === "0");
        if (!hasMeaningfulCoords) {
            sourcePage.detectingCity = false;
            sourcePage.detectCityError = false;
            sourcePage.detectedCity = "";
            return;
        }
        sourcePage.detectingCity = true;
        sourcePage.detectCityError = false;
        sourcePage.resolveCityFromCoords(lat, lon);
    }

    function resolveCityFromCoords(lat, lon) {
        let languageCode = Qt.locale().name.split("_")[0];
        GetCity.getCityName(lat, lon, languageCode, function (city) {
            sourcePage.detectingCity = false;
            if (!city || city === "Unknown") {
                sourcePage.detectCityError = true;
                sourcePage.detectedCity = "";
            } else {
                sourcePage.detectCityError = false;
                sourcePage.detectedCity = city;
            }
        });
    }

    function scheduleCoordinatesLookup() {
        if (locationModeHolder.useIp) return;
        coordinatesLookupDebounce.restart();
    }

    // Remplace automatiquement les virgules par des points pendant la saisie
    // (permet de taper "48,8566" et d'obtenir "48.8566" sans erreur de parsing).
    function sanitizeDecimalInput(field) {
        if (field.text.indexOf(",") === -1) return;
        let cursor = field.cursorPosition;
        field.text = field.text.replace(/,/g, ".");
        field.cursorPosition = Math.min(cursor, field.text.length);
    }

    // "0" est utilisé comme valeur sentinelle pour "coordonnée jamais renseignée".
    // On la vide visuellement pour laisser apparaître le placeholder (Latitude/Longitude)
    // au lieu d'afficher un "0" qui ressemble à une vraie valeur saisie.
    function blankIfUnset(field) {
        if (field.text.trim() === "0") field.text = "";
    }

    property var cachedIpCoords: null

    // Récupère la position via IP une seule fois et la met en cache, pour servir
    // de repli à probeCoords() sans dépendre d'un appel synchrone à GeoCoordinates
    // (qui est asynchrone). Ne touche à aucune propriété cfg_* : purement local.
    //
    // NB : ce cache sert AUSSI à alimenter directement la détection de ville en
    // mode Automatique (voir onCompleted), pour éviter un second appel réseau
    // redondant à GeoCoordinates.getCoordinates() via refreshDetectedCity().
    function primeIpCoordsCache() {
        sourcePage.detectingCity = locationModeHolder.useIp;
        sourcePage.detectCityError = false;
        GeoCoordinates.getCoordinates(function (coords) {
            if (coords) {
                sourcePage.cachedIpCoords = coords;
                if (locationModeHolder.useIp) {
                    sourcePage.resolveCityFromCoords(coords.lat, coords.lon);
                }
            } else if (locationModeHolder.useIp) {
                sourcePage.detectingCity = false;
                sourcePage.detectCityError = true;
                sourcePage.detectedCity = "";
            }
        });
    }

    // Coordonnées utilisées pour la validation de clé API : celles saisies
    // manuellement si présentes, sinon la position détectée par IP, sinon
    // Paris en tout dernier recours (si la géoloc IP n'a pas encore répondu
    // ou a échoué).
    function probeCoords() {
        let hasLat = latitudeField.text && latitudeField.text !== "0";
        let hasLon = longitudeField.text && longitudeField.text !== "0";
        if (hasLat && hasLon) {
            return { lat: latitudeField.text, lon: longitudeField.text };
        }
        if (sourcePage.cachedIpCoords) {
            return { lat: sourcePage.cachedIpCoords.lat, lon: sourcePage.cachedIpCoords.lon };
        }
        return { lat: "48.8566", lon: "2.3522" };
    }

    function safeIntervalFor(providerId) {
        let caps = Registry.getCapabilities(providerId);
        return (caps && caps.safeMinInterval) || 1;
    }

    function scheduleKeyValidation() {
        sourcePage.validationToken++;
        keyValidationDebounce.restart();
    }

    function runKeyValidation() {
        let providerId = providerCombo.providerId;
        let key = currentApiKeyFor(providerId);
        let caps = Registry.getCapabilities(providerId) || {};
        let token = ++sourcePage.validationToken;
        if (!key) {
            validatingKey = false;
            forgetKeyResult(providerId);
            return;
        }

        if (!caps.supportsPlanDetection) {
            validatingKey = false;
            rememberKeyResult(providerId, key, "saved", i18n("Saved"), i18n("This provider doesn't support key verification. The key has been saved as entered."));
            return;
        }

        validatingKey = true;
        Registry.detectPlan(providerId, key, probeCoords().lat, probeCoords().lon, function (result) {
            if (token !== sourcePage.validationToken) return;
            if (providerCombo.providerId !== providerId) return;
            if (currentApiKeyFor(providerId) !== key) return;

            validatingKey = false;
            if (result.tier === "invalid") {
                rememberKeyResult(providerId, key, "invalid", i18n("Invalid"), result.message || i18n("Invalid API key."));
                return;
            }

            rememberKeyResult(providerId, key, "ok", i18n("Valid"), i18n("API key validated."));
            // On autorise l'écriture de la configuration globale si une validation réussit manuellement
            applyProviderLimits(caps, result.maxForecastDays, true);
        });
    }

    function checkIntervalWarning() {
        let safe = safeIntervalFor(providerCombo.providerId);
        if (intervalSpin.value < safe) {
            intervalMessage.text = i18n("Refreshing too often may exhaust your API limits. Minimum recommended is %1 min.", safe);
            intervalMessage.visible = true;
            hideIntervalMessageTimer.restart();
        } else {
            intervalMessage.visible = false;
        }
    }

    // Le verrou du bouton Apply Fantôme est géré par saveToConfig
    function applyProviderLimits(caps, detectedMaxDays, saveToConfig = true) {
        let maxDays = detectedMaxDays || caps.maxForecastDays || 7;

        if (saveToConfig && sourcePage.pageReady) {
            if (typeof plasmoid !== "undefined" && plasmoid.configuration) {
                if (plasmoid.configuration.providerMaxForecastDays !== maxDays) {
                    plasmoid.configuration.providerMaxForecastDays = maxDays;
                }
            }
        }
        checkIntervalWarning();
    }

    function onProviderSwitched(providerId, saveToConfig = true) {
        keyValidationDebounce.stop();
        sourcePage.validationToken++;
        validatingKey = false;
        keyRevealed = false;

        let key = currentApiKeyFor(providerId);
        let cached = sourcePage.validatedKeyCache[providerId];
        if (key && !(cached && cached.key === key)) {
            runKeyValidation();
        } else if (cached && cached.key === key) {
            rememberKeyResult(providerId, cached.key, cached.status, cached.label, cached.message);
        }

        let caps = Registry.getCapabilities(providerId) || {};
        applyProviderLimits(caps, caps.maxForecastDays, saveToConfig);
    }

    function restoreDefaults() {
        let d = Defaults.GENERAL;
        locationModeHolder.useIp = d.useCoordinatesIp;
        latitudeField.text = d.latitudeC;
        longitudeField.text = d.longitudeC;
        sourcePage.blankIfUnset(latitudeField);
        sourcePage.blankIfUnset(longitudeField);
        sourcePage.refreshDetectedCity();
        temperatureCombo.currentIndex = d.temperatureUnit;
        intervalSpin.value = d.updateInterval;

        providerCombo.providerId = d.weatherProvider;
        providerCombo.currentIndex = Math.max(0, providerCombo.providerIds.indexOf(d.weatherProvider));

        weatherApiKeyField.text = d.apiKeyWeatherApi;
        tomorrowApiKeyField.text = d.apiKeyTomorrow;
        openWeatherMapKeyField.text = d.apiKeyOpenWeatherMap;
        visualCrossingKeyField.text = d.apiKeyVisualCrossing;
        pirateWeatherKeyField.text = d.apiKeyPirateWeather;
        if (sourcePage.pageReady) {
            sourcePage.onProviderSwitched(providerCombo.providerId, true);
        }
    }

    Timer { id: keyValidationDebounce; interval: 700; repeat: false; onTriggered: sourcePage.runKeyValidation() }
    Timer { id: hideIntervalMessageTimer; interval: 5000; onTriggered: intervalMessage.visible = false }
    Timer { id: coordinatesLookupDebounce; interval: 700; repeat: false; onTriggered: sourcePage.refreshDetectedCity() }

    Component.onCompleted: Qt.callLater(function () {
        sourcePage.pageReady = true;
        // Initialisation : on lit les limites mais on refuse formellement de les inscrire dans la config (bouton Apply fantôme tué !)
        sourcePage.onProviderSwitched(providerCombo.providerId, false);
        // NB : on ne fait PLUS de blankIfUnset() ici. latitudeField.text est un alias
        // direct vers cfg_latitudeC : le muter au chargement de la page (même pour un
        // simple "0" -> "") modifie réellement la config et déclenche le prompt
        // "voulez-vous sauvegarder ?" alors que l'utilisateur n'a rien fait. Le blanking
        // reste géré uniquement dans onUseIpChanged (vraie action utilisateur) et
        // restoreDefaults() (action explicite).
        //
        // En mode Automatique, primeIpCoordsCache() se charge à la fois de peupler
        // le cache ET de résoudre la ville détectée (un seul appel à GeoCoordinates,
        // au lieu de deux appels réseau parallèles auparavant). En mode Manuel, on
        // garde refreshDetectedCity() pour résoudre la ville à partir des coordonnées
        // saisies, tandis que primeIpCoordsCache() se contente d'alimenter le cache
        // de repli utilisé par probeCoords() pour la validation de clé API.
        sourcePage.primeIpCoordsCache();
        if (!locationModeHolder.useIp) {
            sourcePage.refreshDetectedCity();
        }
    })

    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            id: contentColumn
            // Math.max(contentMaxWidth, implicitWidth): normally implicitWidth
            // (the true minimum needed by the widest card/row below, once
            // SettingsCard propagates it) stays under contentMaxWidth, so
            // this is a no-op and nothing changes for languages that already
            // fit. It only kicks in when a translation makes some row's
            // natural width exceed the usual cap — in that case the column
            // grows just enough to fit it, still capped by the actual
            // available scroll width so it can never overflow the window.
            readonly property real effectiveWidth: Math.min(scrollView.availableWidth - Kirigami.Units.gridUnit * 2, Math.max(sourcePage.contentMaxWidth, contentColumn.implicitWidth))
            width: effectiveWidth
            x: Math.max(Kirigami.Units.gridUnit, (scrollView.availableWidth - effectiveWidth) / 2)
            spacing: Kirigami.Units.largeSpacing

            Item { Layout.preferredHeight: Kirigami.Units.gridUnit * 0.5 }

            SectionHeader { text: i18n("Location Settings"); isFirst: true }

            SettingsCard {
                id: locationCard
                RowLayout {
                    Layout.fillWidth: true
                    Item { Layout.fillWidth: true }
                    SettingGroup {
                        id: locationGroup
                        Layout.fillWidth: false
                        // Fixe la largeur du groupe à celle du mode Manuel (le plus large), en
                        // permanence, plutôt que de la laisser dépendre des lignes visibles.
                        // Sans ça, Qt Quick Layouts exclut la ligne "Coordinates:" du calcul de
                        // largeur du ColumnLayout quand elle est invisible (mode Automatique), ce
                        // qui rétrécit le groupe et décale tout le bloc "Location:" horizontalement
                        // (le groupe est recentré via les Item{fillWidth:true} ci-dessous).
                        // effectiveLabelWidth est déjà stable (RowWidthSync compte toutes les
                        // lignes, visibles ou non) ; seule la largeur du groupe lui-même bougeait.
                        Layout.preferredWidth: locationGroup.effectiveLabelWidth + Kirigami.Units.largeSpacing
                        + (sourcePage.coordinateFieldWidth * 2 + Kirigami.Units.smallSpacing)
                        // --- Ligne 1 : mode de détection (toujours visible) ---
                        // SettingRow autonome. L'alignement horizontal avec la ligne "Coordonnées"
                        // est garanti par locationGroup.Layout.preferredWidth ci-dessus (fixe, peu
                        // importe le mode) combiné à la colonne de labels partagée de SettingGroup.
                        SettingRow {
                            label: i18n("Location:")
                            Item {
                                id: locationModeContainer
                                // Se dimensionne sur le contenu réel du combo (voir
                                // FieldComboBox.qml) plutôt qu'une fraction fixe de
                                // inputWidth, pour ne pas tronquer "Automatic/Manual"
                                // une fois traduits dans une langue plus verbeuse.
                                Layout.preferredWidth: locationModeCombo.implicitWidth
                                Layout.preferredHeight: sourcePage.spinBoxHeight

                                FieldComboBox {
                                    id: locationModeCombo
                                    anchors.fill: parent
                                    model: [i18n("Automatic"), i18n("Manual")]
                                    currentIndex: locationModeHolder.useIp ? 0 : 1
                                    onActivated: (index) => {
                                        let useIp = (index === 0);
                                        if (locationModeHolder.useIp !== useIp) {
                                            locationModeHolder.useIp = useIp;
                                        }
                                        sourcePage.refreshDetectedCity();
                                    }
                                }

                                BusyIndicator {
                                    anchors.left: parent.right; anchors.leftMargin: Kirigami.Units.smallSpacing; anchors.verticalCenter: parent.verticalCenter
                                    visible: locationModeHolder.useIp && sourcePage.detectingCity
                                    running: visible
                                    implicitWidth: Kirigami.Units.gridUnit; implicitHeight: Kirigami.Units.gridUnit
                                }

                                Rectangle {
                                    id: autoCityPill
                                    anchors.left: parent.right; anchors.leftMargin: Kirigami.Units.smallSpacing; anchors.verticalCenter: parent.verticalCenter
                                    visible: locationModeHolder.useIp && !sourcePage.detectingCity && (sourcePage.detectedCity.length > 0 || sourcePage.detectCityError)
                                    radius: height / 2
                                    implicitHeight: autoCityRow.implicitHeight + Kirigami.Units.smallSpacing * 1.2
                                    implicitWidth: autoCityRow.implicitWidth + Kirigami.Units.largeSpacing
                                    readonly property color tint: sourcePage.detectCityError ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.positiveTextColor
                                    color: Qt.rgba(tint.r, tint.g, tint.b, 0.15)
                                    RowLayout {
                                        id: autoCityRow
                                        anchors.centerIn: parent
                                        spacing: Kirigami.Units.smallSpacing * 0.6
                                        Kirigami.Icon { source: sourcePage.detectCityError ? "dialog-error" : "mark-location"; color: autoCityPill.tint; implicitWidth: Kirigami.Units.iconSizes.small * 0.75; implicitHeight: Kirigami.Units.iconSizes.small * 0.75 }
                                        Label { text: sourcePage.detectCityError ? i18n("Detection failed") : sourcePage.detectedCity; color: autoCityPill.tint; font.pointSize: Kirigami.Theme.smallFont.pointSize; font.bold: true }
                                    }
                                }
                            }
                        }

                        // --- Ligne 2 : coordonnées manuelles (seulement en mode "Manual") ---
                        // SettingRow avec son propre sous-titre "Coordinates:", visible uniquement
                        // en mode manuel. "Location:" ne se retrouve donc plus centré verticalement
                        // entre les deux blocs, et l'alignement horizontal suit le même mécanisme
                        // que la ligne "Location:" ci-dessus (colonne de labels de SettingGroup).
                        SettingRow {
                            id: coordinatesRow
                            label: i18n("Coordinates:")
                            // Toggle normal : la largeur du groupe est désormais fixée explicitement
                            // sur locationGroup (voir plus haut), donc cette ligne peut redevenir
                            // visible/invisible normalement sans affecter ni la largeur ni la hauteur
                            // du groupe en dehors de ce qu'elle occupe elle-même.
                            visible: !locationModeHolder.useIp

                            Item {
                                id: coordinatesContainer
                                Layout.preferredWidth: sourcePage.coordinateFieldWidth * 2 + Kirigami.Units.smallSpacing
                                Layout.preferredHeight: sourcePage.spinBoxHeight

                                RowLayout {
                                    anchors.fill: parent
                                    spacing: Kirigami.Units.smallSpacing
                                    TextField {
                                        id: latitudeField; placeholderText: i18n("Latitude"); Layout.preferredWidth: sourcePage.coordinateFieldWidth; Layout.fillHeight: true; horizontalAlignment: TextInput.AlignHCenter
                                        Keys.onReturnPressed: (event) => { event.accepted = true; sourcePage.forceActiveFocus(); }
                                        Keys.onEnterPressed: (event) => { event.accepted = true; sourcePage.forceActiveFocus(); }
                                        onTextChanged: { sourcePage.sanitizeDecimalInput(latitudeField); sourcePage.scheduleCoordinatesLookup(); }
                                    }
                                    TextField {
                                        id: longitudeField; placeholderText: i18n("Longitude"); Layout.preferredWidth: sourcePage.coordinateFieldWidth; Layout.fillHeight: true; horizontalAlignment: TextInput.AlignHCenter
                                        Keys.onReturnPressed: (event) => { event.accepted = true; sourcePage.forceActiveFocus(); }
                                        Keys.onEnterPressed: (event) => { event.accepted = true; sourcePage.forceActiveFocus(); }
                                        onTextChanged: { sourcePage.sanitizeDecimalInput(longitudeField); sourcePage.scheduleCoordinatesLookup(); }
                                    }
                                }

                                BusyIndicator {
                                    anchors.left: parent.right; anchors.leftMargin: Kirigami.Units.smallSpacing; anchors.verticalCenter: parent.verticalCenter
                                    visible: !locationModeHolder.useIp && sourcePage.detectingCity
                                    running: visible
                                    implicitWidth: Kirigami.Units.gridUnit; implicitHeight: Kirigami.Units.gridUnit
                                }

                                Rectangle {
                                    id: manualCityPill
                                    anchors.left: parent.right; anchors.leftMargin: Kirigami.Units.smallSpacing; anchors.verticalCenter: parent.verticalCenter
                                    visible: !locationModeHolder.useIp && !sourcePage.detectingCity && (sourcePage.detectedCity.length > 0 || sourcePage.detectCityError)
                                    radius: height / 2
                                    implicitHeight: manualCityRow.implicitHeight + Kirigami.Units.smallSpacing * 1.2
                                    implicitWidth: manualCityRow.implicitWidth + Kirigami.Units.largeSpacing
                                    readonly property color tint: sourcePage.detectCityError ? Kirigami.Theme.negativeTextColor : Kirigami.Theme.positiveTextColor
                                    color: Qt.rgba(tint.r, tint.g, tint.b, 0.15)
                                    RowLayout {
                                        id: manualCityRow
                                        anchors.centerIn: parent
                                        spacing: Kirigami.Units.smallSpacing * 0.6
                                        Kirigami.Icon { source: sourcePage.detectCityError ? "dialog-error" : "mark-location"; color: manualCityPill.tint; implicitWidth: Kirigami.Units.iconSizes.small * 0.75; implicitHeight: Kirigami.Units.iconSizes.small * 0.75 }
                                        Label { text: sourcePage.detectCityError ? i18n("Detection failed") : sourcePage.detectedCity; color: manualCityPill.tint; font.pointSize: Kirigami.Theme.smallFont.pointSize; font.bold: true }
                                    }
                                }
                            }
                        }
                    }
                    Item { Layout.fillWidth: true }
                }
            }

            SectionHeader { text: i18n("Weather Source") }

            SettingsCard {
                id: sourceCard
                RowLayout {
                    Layout.fillWidth: true
                    Item { Layout.fillWidth: true }
                    SettingGroup {
                        id: sourceGroup
                        Layout.fillWidth: false
                        SettingRow {
                            label: i18n("Provider:")
                            Item {
                                id: providerFieldContainer
                                Layout.preferredWidth: sourcePage.inputWidth
                                Layout.preferredHeight: sourcePage.spinBoxHeight

                                FieldComboBox {
                                    id: providerCombo
                                    width: sourcePage.providerFieldWidth; height: parent.height; anchors.left: parent.left
                                    property string providerId: "openmeteo"

                                    readonly property var providerIds: Registry.getSortedProviderIds()
                                    readonly property var providerRecommended: providerIds.map(function (id) { return /recommend/i.test(i18n(Registry.getProviderMeta(id).name)); })
                                    readonly property bool isRecommended: providerRecommended[currentIndex] === true

                                    model: providerIds.map(function (id) {
                                        let meta = Registry.getProviderMeta(id);
                                        return i18n(meta.name).replace(/\s*\(yr\)/gi, "").replace(/[\s·\-–(]*recommended\)?/gi, "").trim();
                                    })

                                    currentIndex: Math.max(0, providerIds.indexOf(providerId))

                                    onActivated: (index) => {
                                        let newId = providerIds[index];
                                        if (newId !== providerId) {
                                            providerId = newId;
                                        }
                                    }

                                    onProviderIdChanged: {
                                        if (sourcePage.pageReady) {
                                            sourcePage.onProviderSwitched(providerId, true)
                                        }
                                    }
                                }

                                RowLayout {
                                    anchors.left: providerCombo.right; anchors.leftMargin: Kirigami.Units.smallSpacing; anchors.verticalCenter: parent.verticalCenter; spacing: Kirigami.Units.smallSpacing
                                    Rectangle {
                                        visible: providerCombo.isRecommended; radius: height / 2; color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.18)
                                        implicitHeight: recommendedLabel.implicitHeight + Kirigami.Units.smallSpacing; implicitWidth: recommendedLabel.implicitWidth + Kirigami.Units.largeSpacing
                                        Label { id: recommendedLabel; anchors.centerIn: parent; text: i18n("Recommended"); font.pointSize: Kirigami.Theme.smallFont.pointSize; font.bold: true; color: Kirigami.Theme.highlightColor }
                                    }
                                    InfoIcon { visible: Registry.getProviderMeta(providerCombo.providerId).requiresKey; text: i18n("This provider requires a free API key from its website.") }
                                }
                            }
                        }

                        SettingRow {
                            label: i18n("API Key:")
                            visible: providerCombo.providerId !== "openmeteo" && providerCombo.providerId !== "metnorway"
                            Item {
                                id: apiKeyFieldContainer
                                Layout.preferredWidth: sourcePage.inputWidth
                                Layout.preferredHeight: sourcePage.spinBoxHeight
                                readonly property real eyeButtonMargin: Kirigami.Units.smallSpacing * 1.4
                                readonly property real textIconGap: 2
                                readonly property real keyFieldRightPadding: keyRevealButton.width + eyeButtonMargin + textIconGap

                                TextField { id: weatherApiKeyField; anchors.fill: parent; visible: providerCombo.providerId === "weatherapi"; echoMode: sourcePage.keyRevealed ? TextInput.Normal : TextInput.Password; placeholderText: i18n("Paste key here..."); horizontalAlignment: TextInput.AlignLeft; clip: true; rightPadding: apiKeyFieldContainer.keyFieldRightPadding; onTextChanged: sourcePage.scheduleKeyValidation(); Component.onCompleted: cursorPosition = 0; onActiveFocusChanged: if (!activeFocus) cursorPosition = 0 }
                                TextField { id: tomorrowApiKeyField; anchors.fill: parent; visible: providerCombo.providerId === "tomorrowio"; echoMode: sourcePage.keyRevealed ? TextInput.Normal : TextInput.Password; placeholderText: i18n("Paste key here..."); horizontalAlignment: TextInput.AlignLeft; clip: true; rightPadding: apiKeyFieldContainer.keyFieldRightPadding; onTextChanged: sourcePage.scheduleKeyValidation(); Component.onCompleted: cursorPosition = 0; onActiveFocusChanged: if (!activeFocus) cursorPosition = 0 }
                                TextField { id: openWeatherMapKeyField; anchors.fill: parent; visible: providerCombo.providerId === "openweathermap"; echoMode: sourcePage.keyRevealed ? TextInput.Normal : TextInput.Password; placeholderText: i18n("Paste key here..."); horizontalAlignment: TextInput.AlignLeft; clip: true; rightPadding: apiKeyFieldContainer.keyFieldRightPadding; onTextChanged: sourcePage.scheduleKeyValidation(); Component.onCompleted: cursorPosition = 0; onActiveFocusChanged: if (!activeFocus) cursorPosition = 0 }
                                TextField { id: visualCrossingKeyField; anchors.fill: parent; visible: providerCombo.providerId === "visualcrossing"; echoMode: sourcePage.keyRevealed ? TextInput.Normal : TextInput.Password; placeholderText: i18n("Paste key here..."); horizontalAlignment: TextInput.AlignLeft; clip: true; rightPadding: apiKeyFieldContainer.keyFieldRightPadding; onTextChanged: sourcePage.scheduleKeyValidation(); Component.onCompleted: cursorPosition = 0; onActiveFocusChanged: if (!activeFocus) cursorPosition = 0 }
                                TextField { id: pirateWeatherKeyField; anchors.fill: parent; visible: providerCombo.providerId === "pirateweather"; echoMode: sourcePage.keyRevealed ? TextInput.Normal : TextInput.Password; placeholderText: i18n("Paste key here..."); horizontalAlignment: TextInput.AlignLeft; clip: true; rightPadding: apiKeyFieldContainer.keyFieldRightPadding; onTextChanged: sourcePage.scheduleKeyValidation(); Component.onCompleted: cursorPosition = 0; onActiveFocusChanged: if (!activeFocus) cursorPosition = 0 }

                                ToolButton {
                                    id: keyRevealButton
                                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; anchors.rightMargin: apiKeyFieldContainer.eyeButtonMargin
                                    flat: true; display: AbstractButton.IconOnly; implicitWidth: Kirigami.Units.iconSizes.small + Kirigami.Units.smallSpacing * 1.6; implicitHeight: implicitWidth
                                    onClicked: sourcePage.keyRevealed = !sourcePage.keyRevealed
                                    background: Item {}
                                    contentItem: Image {
                                        anchors.centerIn: parent; width: Kirigami.Units.iconSizes.small; height: width; sourceSize.width: width * 3; sourceSize.height: height * 3; fillMode: Image.PreserveAspectFit; smooth: true
                                        source: sourcePage.eyeIconDataUrl(!sourcePage.keyRevealed, Kirigami.Theme.textColor.toString())
                                        opacity: keyRevealButton.pressed ? 0.55 : keyRevealButton.hovered ? 0.8 : 1.0
                                        Behavior on opacity { NumberAnimation { duration: Kirigami.Units.shortDuration } }
                                    }
                                    ToolTip.text: sourcePage.keyRevealed ? i18n("Hide API key") : i18n("Show API key"); ToolTip.visible: hovered; ToolTip.delay: Kirigami.Units.toolTipDelay
                                }

                                BusyIndicator {
                                    id: keyBusyIndicator; anchors.left: parent.right; anchors.leftMargin: Kirigami.Units.smallSpacing; anchors.verticalCenter: parent.verticalCenter
                                    running: sourcePage.validatingKey; visible: running; implicitWidth: Kirigami.Units.gridUnit; implicitHeight: Kirigami.Units.gridUnit
                                }

                                Rectangle {
                                    id: keyStatusPill; anchors.left: parent.right; anchors.leftMargin: Kirigami.Units.smallSpacing; anchors.verticalCenter: parent.verticalCenter
                                    visible: !sourcePage.validatingKey && sourcePage.keyStatusLabel.length > 0 && sourcePage.currentApiKey().length > 0
                                    radius: height / 2; implicitHeight: keyStatusRow.implicitHeight + Kirigami.Units.smallSpacing * 1.2; implicitWidth: keyStatusRow.implicitWidth + Kirigami.Units.largeSpacing
                                    readonly property color tint: sourcePage.keyStatus === "invalid" ? Kirigami.Theme.negativeTextColor : sourcePage.keyStatus === "ok" ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.neutralTextColor
                                    color: Qt.rgba(tint.r, tint.g, tint.b, 0.15)
                                    RowLayout {
                                        id: keyStatusRow; anchors.centerIn: parent; spacing: Kirigami.Units.smallSpacing * 0.6
                                        Kirigami.Icon { source: sourcePage.keyStatus === "invalid" ? "dialog-error" : sourcePage.keyStatus === "ok" ? "dialog-ok-apply" : "dialog-information"; color: keyStatusPill.tint; implicitWidth: Kirigami.Units.iconSizes.small * 0.75; implicitHeight: Kirigami.Units.iconSizes.small * 0.75 }
                                        Label { text: sourcePage.keyStatusLabel; color: keyStatusPill.tint; font.pointSize: Kirigami.Theme.smallFont.pointSize; font.bold: true }
                                    }
                                    MouseArea { id: keyStatusHover; anchors.fill: parent; hoverEnabled: true }
                                    ToolTip.text: sourcePage.keyStatusMessage; ToolTip.visible: keyStatusHover.containsMouse && sourcePage.keyStatusMessage.length > 0; ToolTip.delay: Kirigami.Units.toolTipDelay
                                }
                            }
                        }
                    }
                    Item { Layout.fillWidth: true }
                }
            }

            SectionHeader { text: i18n("Updates & Units") }

            SettingsCard {
                id: updatesCard
                RowLayout {
                    Layout.fillWidth: true
                    Item { Layout.fillWidth: true }
                    SettingGroup {
                        id: updatesGroup
                        Layout.fillWidth: false
                        SettingRow {
                            label: i18n("System units:")
                            FieldComboBox { id: temperatureCombo; model: [i18n("Metric  ·  °C, km/h"), i18n("Imperial  ·  °F, mph")] }
                        }
                        SettingRow {
                            label: i18n("Refresh every:")
                            SpinBox {
                                id: intervalSpin
                                editable: true; Keys.onReturnPressed: (event) => { event.accepted = true; sourcePage.forceActiveFocus(); }; Keys.onEnterPressed: (event) => { event.accepted = true; sourcePage.forceActiveFocus(); }
                                Layout.preferredWidth: sourcePage.numericFieldWidth; Layout.preferredHeight: sourcePage.spinBoxHeight
                                from: sourcePage.safeIntervalFor(providerCombo.providerId); to: 360; stepSize: 5
                                textFromValue: (value, locale) => value + " min"; valueFromText: (text, locale) => parseInt(text)
                                onValueModified: sourcePage.checkIntervalWarning()
                                Component.onCompleted: { if (contentItem && typeof contentItem.horizontalAlignment !== "undefined") { contentItem.horizontalAlignment = Text.AlignHCenter; } }
                                Connections {
                                    target: intervalSpin.contentItem; ignoreUnknownSignals: true
                                    function onTextEdited() {
                                        let parsed = intervalSpin.valueFromText(intervalSpin.contentItem.text, intervalSpin.locale);
                                        if (!isNaN(parsed)) {
                                            let clamped = Math.max(intervalSpin.from, Math.min(intervalSpin.to, parsed));
                                            if (intervalSpin.value !== clamped) intervalSpin.value = clamped;
                                        }
                                    }
                                }
                            }
                            Button { id: forceRefreshButton; icon.name: "view-refresh"; text: i18n("Force refresh"); onClicked: cfg_refreshTrigger++ }
                        }
                    }
                    Item { Layout.fillWidth: true }
                }
                Kirigami.InlineMessage { id: intervalMessage; Layout.fillWidth: true; visible: false; type: Kirigami.MessageType.Warning }
            }

            ResetSection { message: i18n("Are you sure you want to reset the location, source and update settings to their default values? This action cannot be undone."); onConfirmed: sourcePage.restoreDefaults() }
            Item { Layout.preferredHeight: Kirigami.Units.gridUnit * 0.5 }
        }
    }
}
