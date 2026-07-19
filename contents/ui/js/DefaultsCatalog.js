.pragma library

// Single source of truth for factory-default values used by every
// "Restore Defaults" action across the settings pages.
//
// IMPORTANT: these values MUST stay in sync with the <default> entries
// declared in contents/config/main.xml. If you change a default there,
// change it here too (and vice versa).

var GENERAL = {
    useCoordinatesIp: true,
    latitudeC: "0",
    longitudeC: "0",
    temperatureUnit: 0,
    windSpeedUnit: 0,
    updateInterval: 15,
    weatherProvider: "openmeteo",
    apiKeyWeatherApi: "",
    apiKeyTomorrow: "",
    apiKeyOpenWeatherMap: "",
    apiKeyVisualCrossing: "",
    apiKeyPirateWeather: ""
};

var APPEARANCE = {
    showTemperaturePanel: true,
    showConditionPanel: true,
    reverseOrder: false,
    temperatureFontSize: 11.0,
    temperaturePanelBold: true,
    conditionFontSize: 10.0,
    conditionPanelBold: false,
    preciseTemp: false,
    showConditionExpanded: true,
    showLocationExpanded: true,
    // Vérifié contre contents/config/main.xml.
    conditionAlignment: 1,        // 0=Left, 1=Middle, 2=Right
    forecastHoverZoneSize: 1,     // 0=Large, 1=Medium, 2=Small
        showAnimations: true,
        hoverDecimals: true,
        xAxisPrecision: true,
        yAxisDecimals: false,
        interactiveYAxis: false,
        borderRadius: 8,
        backgroundOpacity: 1.0
};

var DATA = {
    detailsOrder: ["apparentTemp", "humidity", "windSpeed", "uvIndex"],
    chartsOrder: ["temperature", "humidity", "windSpeed", "uvIndex"],
    // Aucune fusion par défaut : c'est à l'utilisateur de choisir d'en créer
    // une via "Chart Fusion" dans Data & Charts. Paires attendues au format
    // [idPrincipal, idSecondaire], le second étant tracé en pointillé. Sans
    // effet tant que les deux courbes d'une paire ne sont pas toutes les deux
    // sélectionnées dans Chart Tabs (voir FullRepresentation.qml::chartDefs).
    combinedCharts: [],
    forecastStartDay: 0,
        forecastDayCount: 7,
            // 0 = Auto : recalculé dynamiquement dans le widget selon la largeur réelle
            // et le nombre de "Text Details" sélectionnés (voir
            // FullRepresentation.qml::autoVisibleDayCount). Toute valeur > 0 saisie par
            // l'utilisateur dans Data & Charts est traitée comme un maximum (jamais
            // dépassé, jamais de rétrécissement des icônes en dessous d'une taille
            // lisible — voir visibleCols dans FullRepresentation.qml). Rappel main.xml :
            // la valeur littérale du <default> XML doit rester alignée sur celle-ci
            // (voir commentaire en tête de fichier) ; elle vaut 0 au moment où ceci est
            // écrit.
            forecastVisibleDayCount: 0
};
