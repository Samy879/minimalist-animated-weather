// DetailsCatalog.js

// Nombre max de "Text Details" affichables dans la vue compacte du widget
// (quand "Condition" / Full View est désactivé dans Appearance). Cette
// valeur est la seule source de vérité : ConfigData.qml (page de config,
// pour plafonner la sélection) et FullRepresentation.qml (widget, pour
// tronquer défensivement l'affichage) la lisent tous les deux ici plutôt
// que de la dupliquer en dur, afin qu'ils ne puissent jamais diverger.
function getCompactDetailsMaxCount() {
    return 4;
}

// Le catalogue est construit une seule fois puis mis en cache : il est lu
// depuis des bindings QML réévalués fréquemment (à chaque changement de
// donnée météo), et reconstruire 7 objets (avec leurs appels i18nc()) à
// chaque appel n'apporte rien puisque son contenu ne dépend que de la
// langue de l'interface, laquelle ne change pas en cours de session.
var _catalogCache = null;

function getCatalog() {
    if (_catalogCache) return _catalogCache;
    _catalogCache = _buildCatalog();
    return _catalogCache;
}

function _buildCatalog() {
    return [
        {
            id: "temperature",
            selectable: true,
            capKey: "temperature",
            tabLabelKey: i18nc("Chart tab label", "Temp."),        // Chart tab
            labelKey: i18nc("Chart Y axis label", "Temp."),           // Y axis
            longLabelKey: i18nc("Settings label", "Temperature"), // Settings (espace disponible, on veut du clair)
            bottomRowLabelKey: i18nc("Compact widget bottom row label", "Temp."),  // Bottom row (peu d'espace)
            currentField: "temperature_2m",
            hourlyField: "temperature_2m",
            dailyMaxField: "temperature_2m_max",
            unitFn: function (tempUnit) { return parseInt(tempUnit) === 0 ? "°C" : "°F"; },
            chartType: 0,
            color: "#EB9E26",
            decimals: false
        },
        {
            id: "apparentTemp",
            selectable: true,
            capKey: "apparentTemp",
            tabLabelKey: i18nc("Chart tab label", "Feels"),        // Chart tab
            labelKey: i18nc("Chart Y axis label", "Feels"),           // Y axis
            longLabelKey: i18nc("Settings label", "Feels Like"),  // Settings
            bottomRowLabelKey: i18nc("Compact widget bottom row label", "Feels Like"), // Bottom row (inchangé)
            currentField: "apparent_temperature",
            hourlyField: "apparent_temperature",
            dailyMaxField: null,
            unitFn: function (tempUnit) { return parseInt(tempUnit) === 0 ? "°C" : "°F"; },
            chartType: 0,
            color: "#E0701E",
            decimals: false
        },
        {
            id: "humidity",
            selectable: true,
            capKey: "humidity",
            tabLabelKey: i18nc("Chart tab label", "Hum."),         // Chart tab
            labelKey: i18nc("Chart Y axis label", "Hum."),            // Y axis
            longLabelKey: i18nc("Settings label", "Humidity"),    // Settings
            bottomRowLabelKey: i18nc("Compact widget bottom row label", "Humidity"), // Bottom row (inchangé)
            currentField: "relative_humidity_2m",
            hourlyField: "relative_humidity_2m",
            dailyMaxField: null,
            unitFn: function () { return "%"; },
            chartType: 1,
            color: "#4A90E2",
            decimals: false
        },
        {
            id: "windSpeed",
            selectable: true,
            capKey: "windSpeed",
            tabLabelKey: i18nc("Chart tab label", "Wind"),         // Chart tab
            labelKey: i18nc("Chart Y axis label", "Wind"),            // Y axis
            longLabelKey: i18nc("Settings label", "Wind"),  // Settings
            bottomRowLabelKey: i18nc("Compact widget bottom row label", "Wind"), // Bottom row (inchangé)
            currentField: "wind_speed_10m",
            hourlyField: "wind_speed_10m",
            dailyMaxField: null,
            unitFn: function (tempUnit) { return parseInt(tempUnit) === 0 ? " km/h" : " mph"; },
            chartType: 2,
            color: "#4A7FA8",
            decimals: false
        },
        {
            id: "uvIndex",
            selectable: true,
            capKey: "uvIndex",
            tabLabelKey: i18nc("Chart tab label", "UV"),           // Chart tab
            labelKey: i18nc("Chart Y axis label", "UV Index"),        // Y axis
            longLabelKey: i18nc("Settings label", "UV Index"),    // Settings
            bottomRowLabelKey: i18nc("Compact widget bottom row label", "UV Index"), // Bottom row (inchangé)
            currentField: "uv_index",
            hourlyField: "uv_index",
            dailyMaxField: "uv_index_max",
            unitFn: function () { return ""; },
            chartType: 3,
            color: "#8B2FE6",
            decimals: false
        },
        {
            id: "rainProbability",
            selectable: true,
            capKey: "rainProbability",
            tabLabelKey: i18nc("Chart tab label", "Rain"),       // Chart tab
            labelKey: i18nc("Chart Y axis label", "Rain"),            // Y axis
            longLabelKey: i18nc("Settings label", "Rain Probability"), // Settings (espace disponible, on veut du clair)
            bottomRowLabelKey: i18nc("Compact widget bottom row label", "Rain Prob."), // Bottom row (peu d'espace)
            currentField: null,
            hourlyField: "precipitation_probability",
            dailyMaxField: "precipitation_probability_max",
            unitFn: function () { return "%"; },
            chartType: 4,
            color: "#2E86C1",
            decimals: false
        },
        {
            id: "cloudCover",
            selectable: true,
            capKey: "cloudCover",
            tabLabelKey: i18nc("Chart tab label", "Clouds"),       // Chart tab
            labelKey: i18nc("Chart Y axis label", "Clouds"),          // Y axis
            longLabelKey: i18nc("Settings label", "Cloud Cover"), // Settings
            bottomRowLabelKey: i18nc("Compact widget bottom row label", "Cloud Cover"), // Bottom row (inchangé)
            currentField: "cloud_cover",
            hourlyField: "cloud_cover",
            dailyMaxField: "cloud_cover_mean",
            unitFn: function () { return "%"; },
            chartType: 5,
            color: "#7F8C8D",
            decimals: false
        }
    ];
}

function findDetail(id) {
    let cat = getCatalog();
    for (let i = 0; i < cat.length; i++) {
        if (cat[i].id === id) return cat[i];
    }
    return null;
}

function readCurrentValue(detailId, weatherData) {
    let def = findDetail(detailId);
    if (!def || !weatherData || !weatherData.current) return null;
    if (!def.currentField) return null;
    let v = weatherData.current[def.currentField];
    return (v === undefined || v === null) ? null : v;
}

function readTodayFallback(detailId, weatherData) {
    let def = findDetail(detailId);
    if (!def || !weatherData || !weatherData.daily || !def.dailyMaxField) return null;
    let arr = weatherData.daily[def.dailyMaxField];
    if (!arr || arr.length === 0) return null;
    let v = arr[0];
    return (v === undefined || v === null) ? null : v;
}

function readHourlySeries(detailId, weatherData, dayIndex) {
    let def = findDetail(detailId);
    if (!def || !weatherData || !weatherData.hourly || !def.hourlyField) return [];
    let series = weatherData.hourly[def.hourlyField];
    if (!series || dayIndex < 0) return [];
    let start = dayIndex * 24;
    return series.slice(start, start + 24);
}
