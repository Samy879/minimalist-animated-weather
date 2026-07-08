// WeatherDescription.js

// Note : Le paramètre 'languageCode' est conservé dans la signature de la fonction
// pour ne pas casser les anciens appels dans main.qml, mais il n'est plus utilisé
// en interne puisque i18n() se charge de la détection de la langue du système.

// Les deux dictionnaires ci-dessous ne dépendent que de la langue de
// l'interface (figée pour la session), pas du code météo lui-même : on les
// construit donc une seule fois (au lieu de reconstruire ~26 entrées
// traduites à chaque appel de weatherShortText/weatherLongText, alors que
// ces fonctions sont invoquées à chaque mise à jour météo).
var _shortDescriptions = null;
var _longDescriptions = null;

function _buildShortDescriptions() {
    return {
        0: i18n("Clear"),
        1: i18n("Clear"),
        2: i18n("Cloudy"),
        3: i18n("Cloudy"),
        45: i18n("Fog"),
        48: i18n("Fog"),
        51: i18n("Drizzle"),
        53: i18n("Drizzle"),
        55: i18n("Drizzle"),
        56: i18n("Drizzle"),
        57: i18n("Drizzle"),
        61: i18n("Rain"),
        63: i18n("Rain"),
        65: i18n("Rain"),
        66: i18n("Rain"),
        67: i18n("Rain"),
        71: i18n("Snow"),
        73: i18n("Snow"),
        75: i18n("Snow"),
        77: i18n("Hail"),
        80: i18n("Showers"),
        81: i18n("Showers"),
        82: i18n("Showers"),
        85: i18n("Showers"),
        86: i18n("Showers"),
        95: i18n("Storm"),
        96: i18n("Storm"),
        99: i18n("Storm")
    };
}

function _buildLongDescriptions() {
    return {
        0: i18n("Clear"),
        1: i18n("Mainly clear"),
        2: i18n("Partly cloudy"),
        3: i18n("Overcast"),
        45: i18n("Fog"),
        48: i18n("Depositing rime fog"),
        51: i18n("Drizzle light intensity"),
        53: i18n("Drizzle moderate intensity"),
        55: i18n("Drizzle dense intensity"),
        56: i18n("Freezing Drizzle light intensity"),
        57: i18n("Freezing Drizzle dense intensity"),
        61: i18n("Rain slight intensity"),
        63: i18n("Rain moderate intensity"),
        65: i18n("Rain heavy intensity"),
        66: i18n("Freezing Rain light intensity"),
        67: i18n("Freezing Rain heavy intensity"),
        71: i18n("Snowfall slight intensity"),
        73: i18n("Snowfall moderate intensity"),
        75: i18n("Snowfall heavy intensity"),
        77: i18n("Snow grains"),
        80: i18n("Rain showers slight"),
        81: i18n("Rain showers moderate"),
        82: i18n("Rain showers violent"),
        85: i18n("Snow showers slight"),
        86: i18n("Snow showers heavy"),
        95: i18n("Thunderstorm"),
        96: i18n("Thunderstorm with slight hail"),
        99: i18n("Thunderstorm with heavy hail")
    };
}

function weatherShortText(languageCode, code) {
    if (!_shortDescriptions) _shortDescriptions = _buildShortDescriptions();
    return _shortDescriptions[code] || i18n("Unknown");
}

function weatherLongText(languageCode, code) {
    if (!_longDescriptions) _longDescriptions = _buildLongDescriptions();
    return _longDescriptions[code] || i18n("Unknown");
}
