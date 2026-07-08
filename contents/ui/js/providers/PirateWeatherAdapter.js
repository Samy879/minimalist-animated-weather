// PirateWeatherAdapter.js
//
// Utilise l'API "Forecast" de Pirate Weather (remplaçant open-source de
// Dark Sky, modèles HRRR/GFS/NBM/ECMWF combinés).
// https://docs.pirateweather.net/en/latest/API/
// Gratuit (palier permanent, pas de carte bancaire) jusqu'à environ
// 10 000-25 000 appels/mois selon le palier de soutien -> on reste prudent
// côté intervalle minimal (voir safeMinInterval ci-dessous).

.import "../HttpCacheService.js" as Http

var id = "pirateweather";
var name = "Pirate Weather";
var requiresKey = true;

var capabilities = {
    details: {
        temperature: true,
        apparentTemp: true,
        humidity: true,
        windSpeed: true,
        uvIndex: true,
        rainProbability: true,
        cloudCover: true
    },
    maxForecastDays: 7, // Bloc "daily" : 7 jours seulement (le plus court après Tomorrow.io)
    safeMinInterval: 5, // ~10 000 appels/mois au palier de base -> ~333/jour ; 5 min reste large
    supportsPlanDetection: true
};

// Jeu d'icônes par défaut de Pirate Weather (compatible Dark Sky). Pas de
// code numérique natif, donc on mappe vers WMO comme pour Visual Crossing.
var ICON_TO_WMO = {
    "clear-day": 0, "clear-night": 0,
    "partly-cloudy-day": 2, "partly-cloudy-night": 2,
    "cloudy": 3,
    "wind": 3,
    "fog": 45,
    "rain": 61,
    "sleet": 67,
    "snow": 71,
    "thunderstorm": 95,
    "hail": 96,
    "none": 3
};

function iconToWmo(icon) {
    return (icon && ICON_TO_WMO[icon] !== undefined) ? ICON_TO_WMO[icon] : 3;
}

// Pirate Weather renvoie tout en UNIX time absolu (pas de chaînes locales),
// donc is_day se calcule directement par comparaison d'epochs, sans
// conversion de fuseau horaire nécessaire (contrairement à Visual Crossing).
function isDayFromUnix(nowUnix, sunriseUnix, sunsetUnix) {
    if (!sunriseUnix || !sunsetUnix) return 1;
    return (nowUnix >= sunriseUnix && nowUnix <= sunsetUnix) ? 1 : 0;
}

// "time" (UNIX) représente déjà l'instant correspondant à minuit local /
// l'heure locale du point de donnée ; il faut juste réappliquer l'offset
// (en heures) pour lire la bonne date/heure de calendrier local.
function unixToLocalDateString(unixSeconds, offsetHours) {
    if (unixSeconds === undefined || unixSeconds === null) return null;
    let local = new Date((unixSeconds + (offsetHours || 0) * 3600) * 1000);
    let yyyy = local.getUTCFullYear();
    let mm = String(local.getUTCMonth() + 1).padStart(2, '0');
    let dd = String(local.getUTCDate()).padStart(2, '0');
    return yyyy + "-" + mm + "-" + dd;
}

function unixToLocalIso(unixSeconds, offsetHours) {
    if (unixSeconds === undefined || unixSeconds === null) return null;
    let local = new Date((unixSeconds + (offsetHours || 0) * 3600) * 1000);
    let yyyy = local.getUTCFullYear();
    let mm = String(local.getUTCMonth() + 1).padStart(2, '0');
    let dd = String(local.getUTCDate()).padStart(2, '0');
    let hh = String(local.getUTCHours()).padStart(2, '0');
    let min = String(local.getUTCMinutes()).padStart(2, '0');
    return yyyy + "-" + mm + "-" + dd + "T" + hh + ":" + min;
}

function fetch(params, callback) {
    if (!params.apiKey) {
        callback(new Error("missing-api-key"), null, null);
        return;
    }
    let isFahrenheit = (params.tempUnit === "1" || params.tempUnit === 1);
    // "ca" = °C + km/h, "us" = °F + mph : correspond exactement aux deux
    // unités utilisées par le widget, sans aucune conversion manuelle à faire.
    let unitGroup = isFahrenheit ? "us" : "ca";
    let days = Math.min(params.days || 7, capabilities.maxForecastDays);

    let url = "https://api.pirateweather.net/forecast/" + encodeURIComponent(params.apiKey) + "/" +
    params.lat + "," + params.lon +
    "?units=" + unitGroup +
    "&exclude=minutely,alerts" +
    "&extend=hourly";

    Http.get(url, { timeoutMs: 8000, cacheTtlMs: 20000 }, function (err, raw, status) {
        if (err || !raw || !raw.currently || !raw.daily) {
            callback(err || new Error("empty-response"), null, null, status);
            return;
        }

        let tzOffset = raw.offset || 0; // en heures, ex: -5

        let dailyRaw = (raw.daily.data || []).slice(0, days);
        let hourlyRaw = (raw.hourly && raw.hourly.data) ? raw.hourly.data.slice(0, days * 24) : [];

        let hourly = {
            temperature_2m: [], relative_humidity_2m: [], apparent_temperature: [],
            uv_index: [], precipitation_probability: [], cloud_cover: [],
            wind_speed_10m: [], weather_code: []
        };
        for (let h = 0; h < hourlyRaw.length; h++) {
            let hr = hourlyRaw[h];
            hourly.temperature_2m.push(hr.temperature);
            hourly.relative_humidity_2m.push((hr.humidity !== undefined && hr.humidity !== null) ? hr.humidity * 100 : null);
            hourly.apparent_temperature.push(hr.apparentTemperature);
            hourly.uv_index.push(hr.uvIndex);
            hourly.precipitation_probability.push((hr.precipProbability !== undefined) ? Math.round(hr.precipProbability * 100) : null);
            hourly.cloud_cover.push((hr.cloudCover !== undefined && hr.cloudCover !== null) ? Math.round(hr.cloudCover * 100) : null);
            hourly.wind_speed_10m.push(hr.windSpeed);
            hourly.weather_code.push(iconToWmo(hr.icon));
        }

        let daily = {
            time: [],
            temperature_2m_max: [], temperature_2m_min: [], weather_code: [],
            precipitation_probability_max: [], uv_index_max: [], sunrise: [], sunset: []
        };
        for (let d = 0; d < dailyRaw.length; d++) {
            let dy = dailyRaw[d];
            daily.time.push(unixToLocalDateString(dy.time, tzOffset));
            daily.temperature_2m_max.push((dy.temperatureMax !== undefined) ? dy.temperatureMax : dy.temperatureHigh);
            daily.temperature_2m_min.push((dy.temperatureMin !== undefined) ? dy.temperatureMin : dy.temperatureLow);
            daily.weather_code.push(iconToWmo(dy.icon));
            daily.precipitation_probability_max.push((dy.precipProbability !== undefined) ? Math.round(dy.precipProbability * 100) : null);
            daily.uv_index_max.push(dy.uvIndex);
            daily.sunrise.push(unixToLocalIso(dy.sunriseTime, tzOffset));
            daily.sunset.push(unixToLocalIso(dy.sunsetTime, tzOffset));
        }

        let cur = raw.currently;
        let current = {
            temperature_2m: cur.temperature,
             apparent_temperature: cur.apparentTemperature,
             relative_humidity_2m: (cur.humidity !== undefined && cur.humidity !== null) ? cur.humidity * 100 : null,
             wind_speed_10m: cur.windSpeed,
             uv_index: cur.uvIndex,
             cloud_cover: (cur.cloudCover !== undefined && cur.cloudCover !== null) ? Math.round(cur.cloudCover * 100) : null,
             weather_code: iconToWmo(cur.icon),
             is_day: isDayFromUnix(cur.time, dailyRaw[0] ? dailyRaw[0].sunriseTime : null, dailyRaw[0] ? dailyRaw[0].sunsetTime : null)
        };

        callback(null, { current: current, hourly: hourly, daily: daily }, {
            provider: id,
            forecastDaysServed: dailyRaw.length,
                planTier: "valid"
        });
    });
}

function detectPlan(apiKey, lat, lon, callback) {
    if (!apiKey) {
        callback({ tier: "unknown", maxForecastDays: capabilities.maxForecastDays, message: "" });
        return;
    }
    let url = "https://api.pirateweather.net/forecast/" + encodeURIComponent(apiKey) + "/" +
    lat + "," + lon + "?units=ca&exclude=minutely,hourly,alerts";

    Http.get(url, { timeoutMs: 8000 }, function (err, raw, status) {
        if (status === 401 || status === 403) {
            callback({ tier: "invalid", maxForecastDays: 0, message: "Invalid API key or unauthorized." });
            return;
        }
        if (err || !raw || !raw.daily) {
            callback({ tier: "unknown", maxForecastDays: capabilities.maxForecastDays, message: "Network error, cannot verify key." });
            return;
        }

        callback({
            tier: "valid",
            maxForecastDays: (raw.daily.data && raw.daily.data.length) || capabilities.maxForecastDays,
            message: "API key successfully validated."
        });
    });
}
