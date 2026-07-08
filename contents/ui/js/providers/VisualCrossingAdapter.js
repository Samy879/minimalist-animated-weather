// VisualCrossingAdapter.js
//
// Utilise la "Timeline Weather API" de Visual Crossing.
// https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline
// Gratuit jusqu'à 1 000 "records" par jour, sans carte bancaire. Le coût en
// records dépend du nombre de jours demandés (~1 record/jour avec hourly+daily),
// donc l'intervalle de sécurité est calé comme MET Norway pour rester large.

.import "../HttpCacheService.js" as Http

var id = "visualcrossing";
var name = "Visual Crossing";
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
    maxForecastDays: 15,
    safeMinInterval: 10, // Quota en "records" (pas en appels bruts) -> on reste prudent
    supportsPlanDetection: true
};

// Visual Crossing renvoie un "icon" texte (jeu d'icônes fixe icons2), pas de
// code numérique. On mappe vers WMO comme pour les autres providers.
var ICON_TO_WMO = {
    "clear-day": 0, "clear-night": 0,
    "partly-cloudy-day": 2, "partly-cloudy-night": 2,
    "cloudy": 3,
    "wind": 3,
    "fog": 45,
    "rain": 61,
    "showers-day": 80, "showers-night": 80,
    "snow": 71,
    "snow-showers-day": 85, "snow-showers-night": 85,
    "sleet": 67,
    "hail": 96,
    "thunder": 95, "thunder-rain": 95,
    "thunder-showers-day": 95, "thunder-showers-night": 95
};

function iconToWmo(icon) {
    return (icon && ICON_TO_WMO[icon] !== undefined) ? ICON_TO_WMO[icon] : 3;
}

function isDayFromSunTimes(nowDate, sunriseStr, sunsetStr) {
    if (!sunriseStr || !sunsetStr) return 1;
    let sunrise = new Date(sunriseStr);
    let sunset = new Date(sunsetStr);
    if (isNaN(sunrise.getTime()) || isNaN(sunset.getTime())) return 1;
    return (nowDate >= sunrise && nowDate <= sunset) ? 1 : 0;
}

function fetch(params, callback) {
    if (!params.apiKey) {
        callback(new Error("missing-api-key"), null, null);
        return;
    }
    let isFahrenheit = (params.tempUnit === "1" || params.tempUnit === 1);
    let unitGroup = isFahrenheit ? "us" : "metric";
    let days = Math.min(params.days || 7, capabilities.maxForecastDays);

    let url = "https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline/" +
    params.lat + "," + params.lon +
    "?unitGroup=" + unitGroup +
    "&include=current,hours,days" +
    "&elements=datetime,datetimeEpoch,temp,feelslike,humidity,windspeed,uvindex,precipprob,cloudcover,icon,tempmax,tempmin,sunrise,sunset" +
    "&key=" + encodeURIComponent(params.apiKey) +
    "&contentType=json";

    Http.get(url, { timeoutMs: 8000, cacheTtlMs: 20000 }, function (err, raw, status) {
        if (err || !raw || !raw.days) {
            callback(err || new Error("empty-response"), null, null, status);
            return;
        }

        let daysRaw = raw.days.slice(0, days);

        let hourly = {
            temperature_2m: [], relative_humidity_2m: [], apparent_temperature: [],
            uv_index: [], precipitation_probability: [], cloud_cover: [],
            wind_speed_10m: [], weather_code: []
        };
        let daily = {
            time: [],
            temperature_2m_max: [], temperature_2m_min: [], weather_code: [],
            precipitation_probability_max: [], uv_index_max: [], sunrise: [], sunset: []
        };

        for (let d = 0; d < daysRaw.length; d++) {
            let dy = daysRaw[d];

            daily.time.push(dy.datetime);
            daily.temperature_2m_max.push(dy.tempmax);
            daily.temperature_2m_min.push(dy.tempmin);
            daily.weather_code.push(iconToWmo(dy.icon));
            daily.precipitation_probability_max.push(dy.precipprob);
            daily.uv_index_max.push(dy.uvindex);
            daily.sunrise.push(dy.sunrise || null);
            daily.sunset.push(dy.sunset || null);

            let hours = dy.hours || [];
            for (let h = 0; h < hours.length; h++) {
                let hr = hours[h];
                hourly.temperature_2m.push(hr.temp);
                hourly.relative_humidity_2m.push(hr.humidity);
                hourly.apparent_temperature.push(hr.feelslike);
                hourly.uv_index.push(hr.uvindex);
                hourly.precipitation_probability.push(hr.precipprob);
                hourly.cloud_cover.push(hr.cloudcover);
                hourly.wind_speed_10m.push(hr.windspeed);
                hourly.weather_code.push(iconToWmo(hr.icon));
            }
        }

        let cur = raw.currentConditions || {};
        let now = new Date();
        let current = {
            temperature_2m: cur.temp,
             apparent_temperature: cur.feelslike,
             relative_humidity_2m: cur.humidity,
             wind_speed_10m: cur.windspeed,
             uv_index: cur.uvindex,
             cloud_cover: cur.cloudcover,
             weather_code: iconToWmo(cur.icon),
             is_day: isDayFromSunTimes(now, cur.sunrise || daily.sunrise[0], cur.sunset || daily.sunset[0])
        };

        callback(null, { current: current, hourly: hourly, daily: daily }, {
            provider: id,
            forecastDaysServed: daysRaw.length,
                planTier: "valid"
        });
    });
}

function detectPlan(apiKey, lat, lon, callback) {
    if (!apiKey) {
        callback({ tier: "unknown", maxForecastDays: capabilities.maxForecastDays, message: "" });
        return;
    }
    let url = "https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline/" +
    lat + "," + lon + "?unitGroup=metric&include=days&key=" + encodeURIComponent(apiKey) +
    "&contentType=json";

    Http.get(url, { timeoutMs: 8000 }, function (err, raw, status) {
        if (status === 401 || status === 403) {
            callback({ tier: "invalid", maxForecastDays: 0, message: "Invalid API key or unauthorized." });
            return;
        }
        if (err || !raw || !raw.days) {
            callback({ tier: "unknown", maxForecastDays: capabilities.maxForecastDays, message: "Network error, cannot verify key." });
            return;
        }

        callback({
            tier: "valid",
            maxForecastDays: raw.days.length || capabilities.maxForecastDays,
            message: "API key successfully validated."
        });
    });
}
