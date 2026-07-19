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
    forecastStartDay: 0,
    forecastDayCount: 7
};
