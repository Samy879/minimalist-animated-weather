// UnitConverter.js
//
// Point de conversion UNIQUE pour les unités affichées. Auparavant, chaque
// adaptateur convertissait lui-même température ET vitesse du vent à partir
// d'un seul paramètre `tempUnit` ("0" métrique / "1" impérial) — ce qui les
// couplait de force (impossible d'avoir °F + km/h, ou °C + mph). Avec 3
// options de température (°C/°F/K) et 3 options de vitesse (km/h/mph/m/s),
// dupliquer cette logique dans 7 fichiers aurait été ingérable et sujet à
// divergence (cf. philosophie "source unique de vérité" déjà appliquée à
// DetailsCatalog.js / DefaultsCatalog.js).
//
// Convention interne : TOUS les adaptateurs renvoient désormais leurs
// données dans une unité canonique fixe — Celsius pour la température,
// km/h pour le vent — quel que soit le choix de l'utilisateur. Cette
// fonction est appliquée une seule fois, après le fetch, par
// ProviderRegistry.fetchWeather(), pour convertir vers les unités
// réellement choisies (temperatureUnit / windSpeedUnit, indépendants).
//
// temperatureUnit : 0 = Celsius, 1 = Fahrenheit, 2 = Kelvin
// windSpeedUnit   : 0 = km/h,    1 = mph,        2 = m/s

function celsiusToUnit(celsius, temperatureUnit) {
    if (celsius === null || celsius === undefined || isNaN(celsius)) return celsius;
    switch (parseInt(temperatureUnit)) {
        case 1: return celsius * 9 / 5 + 32;
        case 2: return celsius + 273.15;
        default: return celsius;
    }
}

function kmhToUnit(kmh, windSpeedUnit) {
    if (kmh === null || kmh === undefined || isNaN(kmh)) return kmh;
    switch (parseInt(windSpeedUnit)) {
        case 1: return kmh / 1.609344; // mph
        case 2: return kmh / 3.6;      // m/s
        default: return kmh;           // km/h
    }
}

function _convertArray(arr, convertFn, unit) {
    if (!Array.isArray(arr)) return arr;
    return arr.map(function (v) { return convertFn(v, unit); });
}

/**
 * Convertit en place (et retourne) la structure { current, hourly, daily }
 * d'une unité canonique (°C, km/h) vers les unités choisies par
 * l'utilisateur. Ne touche à rien d'autre (humidité, UV, précipitations en
 * mm, couverture nuageuse... restent dans leur seule unité possible).
 */
function applyDisplayUnits(weatherData, temperatureUnit, windSpeedUnit) {
    if (!weatherData) return weatherData;

    if (weatherData.current) {
        let cur = weatherData.current;
        cur.temperature_2m = celsiusToUnit(cur.temperature_2m, temperatureUnit);
        cur.apparent_temperature = celsiusToUnit(cur.apparent_temperature, temperatureUnit);
        cur.wind_speed_10m = kmhToUnit(cur.wind_speed_10m, windSpeedUnit);
    }

    if (weatherData.hourly) {
        let h = weatherData.hourly;
        h.temperature_2m = _convertArray(h.temperature_2m, celsiusToUnit, temperatureUnit);
        h.apparent_temperature = _convertArray(h.apparent_temperature, celsiusToUnit, temperatureUnit);
        h.wind_speed_10m = _convertArray(h.wind_speed_10m, kmhToUnit, windSpeedUnit);
    }

    if (weatherData.daily) {
        let d = weatherData.daily;
        d.temperature_2m_max = _convertArray(d.temperature_2m_max, celsiusToUnit, temperatureUnit);
        d.temperature_2m_min = _convertArray(d.temperature_2m_min, celsiusToUnit, temperatureUnit);
    }

    return weatherData;
}

/** Libellé d'unité à afficher pour un axe/valeur de température. */
function temperatureUnitLabel(temperatureUnit) {
    switch (parseInt(temperatureUnit)) {
        case 1: return "°F";
        case 2: return "K"; // Pas de symbole degré pour le Kelvin (convention SI).
        default: return "°C";
    }
}

/** Libellé d'unité à afficher pour une valeur de vitesse du vent. */
function windSpeedUnitLabel(windSpeedUnit) {
    switch (parseInt(windSpeedUnit)) {
        case 1: return " mph";
        case 2: return " m/s";
        default: return " km/h";
    }
}
