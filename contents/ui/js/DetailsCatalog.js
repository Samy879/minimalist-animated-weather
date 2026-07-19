// DetailsCatalog.js

.import "UnitConverter.js" as UnitConverter

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
// langue de l'interface. On garde toutefois une clé de langue pour
// invalider le cache dans le cas (rare mais possible sans redémarrage du
// plasmoïde) où l'utilisateur changerait la langue système en cours de
// session : mieux vaut reconstruire une fois de trop que rester figé dans
// l'ancienne langue indéfiniment.
var _catalogCache = null;
var _catalogCacheLocale = null;

function getCatalog() {
    let currentLocale = Qt.locale().name;
    if (_catalogCache && _catalogCacheLocale === currentLocale) return _catalogCache;
    _catalogCache = _buildCatalog();
    _catalogCacheLocale = currentLocale;
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
            unitFn: function (temperatureUnit) { return UnitConverter.temperatureUnitLabel(temperatureUnit); },
            chartType: 0,
            color: "#EB9E26",
            decimals: false,
            textDetailDecimals: 0
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
            unitFn: function (temperatureUnit) { return UnitConverter.temperatureUnitLabel(temperatureUnit); },
            chartType: 0,
            // Rose framboise plutôt que l'orange précédent (#E0701E), trop proche de
            // celui de "temperature" (#EB9E26) : les deux courbes se confondaient,
            // surtout une fois fusionnées par défaut sur le même graphique.
            color: "#D6336C",
            decimals: false,
            textDetailDecimals: 0
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
            decimals: false,
            textDetailDecimals: 0
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
            unitFn: function (windSpeedUnit) { return UnitConverter.windSpeedUnitLabel(windSpeedUnit); },
            chartType: 2,
            color: "#4A7FA8",
            decimals: false,
            textDetailDecimals: 0
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
            decimals: false,
            textDetailDecimals: 0
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
            // Repris directement du dégradé utilisé pour tracer cette courbe
            // (paletteFor(4), arrêt à 50%) : l'onglet reflète alors exactement ce
            // qui est réellement dessiné, au lieu d'une couleur choisie à part qui
            // pouvait diverger du rendu (ex: onglet vert / courbe bleue).
            color: "#2980B9",
            decimals: false,
            textDetailDecimals: 0,
            // Groupe d'overlay : permet de combiner cette courbe avec une autre
            // (ici "rainAmount") sur un seul graphique à 2 axes Y, si l'utilisateur
            // active ce mode dans les réglages ET sélectionne les deux charts.
            // "primary" porte l'axe Y gauche (0-100%) quand le groupe est combiné.
            overlayGroup: "rain",
            overlayRole: "primary"
        },
        {
            id: "rainAmount",
            selectable: true,
            capKey: "rainAmount",
            tabLabelKey: i18nc("Chart tab label", "Precip."),      // Chart tab
            labelKey: i18nc("Chart Y axis label", "Precip."),         // Y axis
            longLabelKey: i18nc("Settings label", "Precipitation Amount"), // Settings
            bottomRowLabelKey: i18nc("Compact widget bottom row label", "Precip."), // Bottom row (peu d'espace)
            currentField: null,
            hourlyField: "precipitation",
            dailyMaxField: "precipitation_sum",
            unitFn: function () { return " mm"; },
            chartType: 6,
            // Repris directement du dégradé utilisé pour tracer cette courbe
            // (paletteFor(6), arrêt à 50%) : reste bleu, cohérent avec le tracé
            // réel — un onglet vert alors que la courbe est bleue était l'exemple
            // même de l'incohérence à éviter.
            color: "#2E86C1",
            // Utilisé UNIQUEMENT par le graphique (secondaryDecimals dans
            // FullRepresentation.qml, pour la précision de cette courbe une fois
            // fusionnée avec "rainProbability") : une pluie fine (0.2-0.4mm) doit
            // rester visible plutôt que d'être arrondie à 0mm.
            decimals: true,
            // Text Details : pour l'instant arrondi à l'entier comme les autres
            // détails (voir formatTextDetailValue ci-dessous), volontairement
            // indépendant de "decimals" ci-dessus qui ne concerne que le
            // graphique. Passer à 1 pour afficher "0.3 mm" au lieu de "0 mm"
            // dans les Text Details le jour où on veut ce niveau de précision.
            textDetailDecimals: 0,
            // Rôle "secondary" : porte l'axe Y droit quand combiné avec "rainProbability".
            overlayGroup: "rain",
            overlayRole: "secondary"
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
            // Légèrement éclairci par rapport au gris précédent (#7F8C8D), qui
            // paraissait trop sombre pour un onglet/légende.
            color: "#929D9E",
            decimals: false,
            textDetailDecimals: 0
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

// Formate une valeur brute pour l'affichage en "Text Detail" (bloc du haut,
// rangée du bas), en fonction du nombre de décimales défini par le détail
// (cat.textDetailDecimals, par défaut 0 = entier). C'est la seule source de
// vérité pour ce formatage : WeatherData.qml::formatValue() et
// FullRepresentation.qml::buildDetailEntries() l'appellent tous les deux
// plutôt que d'arrondir chacun de leur côté, afin qu'ils ne puissent jamais
// diverger — même logique que getCompactDetailsMaxCount() ci-dessus.
//
// Indépendant de cat.decimals, qui ne pilote que la précision du graphique
// (voir secondaryDecimals dans FullRepresentation.qml / LineChart.qml).
function formatTextDetailValue(detailId, raw) {
    if (raw === null || raw === undefined || isNaN(raw)) return null;
    let def = findDetail(detailId);
    let decimals = (def && typeof def.textDetailDecimals === "number") ? def.textDetailDecimals : 0;
    return raw.toFixed(decimals);
}
