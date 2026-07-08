// WeatherApiAdapter.js

.import "../ForecastAggregator.js" as Aggregator
.import "../HttpCacheService.js" as Http

var id = "weatherapi";
var name = "WeatherAPI";
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
    maxForecastDays: 14,
    safeMinInterval: 1, // API permet 1 Million/mois -> 1 min est sans risque
    supportsPlanDetection: true
};

var CODE_TO_WMO = {
    1000: 0, 1003: 2, 1006: 3, 1009: 3,
    1030: 45, 1135: 45, 1147: 45,
    1063: 51, 1066: 71, 1069: 71, 1072: 56,
    1150: 51, 1153: 51, 1168: 56, 1171: 57,
    1180: 61, 1183: 61, 1186: 63, 1189: 63, 1192: 65, 1195: 65,
    1198: 66, 1201: 67,
    1204: 71, 1207: 73,
    1210: 71, 1213: 71, 1216: 73, 1219: 73, 1222: 75, 1225: 75,
    1114: 75, 1117: 86, 1237: 77,
    1240: 80, 1243: 81, 1246: 82,
    1249: 80, 1252: 81,
    1255: 85, 1258: 86,
    1261: 77, 1264: 77,
    1273: 95, 1276: 96, 1279: 95, 1282: 99, 1087: 95
};

function codeToWmo(code) {
    return (CODE_TO_WMO[code] !== undefined) ? CODE_TO_WMO[code] : 3;
}

function astroToLocalIso(dateStr, astroStr) {
    if (!astroStr || astroStr === "No sunrise" || astroStr === "No sunset") return null;
    let m = astroStr.match(/(\d{1,2}):(\d{2})\s*(AM|PM)/i);
    if (!m) return null;
    let h = parseInt(m[1], 10);
    let min = m[2];
    let isPM = m[3].toUpperCase() === "PM";
    if (isPM && h !== 12) h += 12;
    if (!isPM && h === 12) h = 0;
    let hh = (h < 10 ? "0" : "") + h;
    return dateStr + "T" + hh + ":" + min;
}

function fetch(params, callback) {
    if (!params.apiKey) {
        callback(new Error("missing-api-key"), null, null);
        return;
    }
    let isFahrenheit = (params.tempUnit === "1" || params.tempUnit === 1);
    let days = Math.min(params.days || 7, capabilities.maxForecastDays);

    let url = "https://api.weatherapi.com/v1/forecast.json?key=" + encodeURIComponent(params.apiKey) +
    "&q=" + params.lat + "," + params.lon +
    "&days=" + days + "&aqi=no&alerts=no";

    Http.get(url, { timeoutMs: 8000, cacheTtlMs: 20000 }, function (err, raw, status) {
        if (err || !raw || !raw.forecast || !raw.forecast.forecastday) {
            callback(err || new Error("empty-response"), null, null, status);
            return;
        }

        let fdays = raw.forecast.forecastday;
        let servedDays = fdays.length;

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

        for (let d = 0; d < fdays.length; d++) {
            let fd = fdays[d];

            daily.time.push(fd.date);

            daily.temperature_2m_max.push(isFahrenheit ? fd.day.maxtemp_f : fd.day.maxtemp_c);
            daily.temperature_2m_min.push(isFahrenheit ? fd.day.mintemp_f : fd.day.mintemp_c);
            daily.weather_code.push(codeToWmo(fd.day.condition ? fd.day.condition.code : null));
            daily.precipitation_probability_max.push(fd.day.daily_chance_of_rain);
            daily.uv_index_max.push(fd.day.uv);
            daily.sunrise.push(astroToLocalIso(fd.date, fd.astro ? fd.astro.sunrise : null));
            daily.sunset.push(astroToLocalIso(fd.date, fd.astro ? fd.astro.sunset : null));

            let hours = fd.hour || [];
            for (let h = 0; h < hours.length; h++) {
                let hr = hours[h];
                hourly.temperature_2m.push(isFahrenheit ? hr.temp_f : hr.temp_c);
                hourly.relative_humidity_2m.push(hr.humidity);
                hourly.apparent_temperature.push(isFahrenheit ? hr.feelslike_f : hr.feelslike_c);
                hourly.uv_index.push(hr.uv);
                hourly.precipitation_probability.push(hr.chance_of_rain);
                hourly.cloud_cover.push(hr.cloud);
                hourly.wind_speed_10m.push(isFahrenheit ? hr.wind_mph : hr.wind_kph);
                hourly.weather_code.push(codeToWmo(hr.condition ? hr.condition.code : null));
            }
        }

        let cur = raw.current;
        let current = {
            temperature_2m: isFahrenheit ? cur.temp_f : cur.temp_c,
             apparent_temperature: isFahrenheit ? cur.feelslike_f : cur.feelslike_c,
             relative_humidity_2m: cur.humidity,
             wind_speed_10m: isFahrenheit ? cur.wind_mph : cur.wind_kph,
             uv_index: cur.uv,
             cloud_cover: cur.cloud,
             weather_code: codeToWmo(cur.condition ? cur.condition.code : null),
             is_day: cur.is_day
        };

        callback(null, { current: current, hourly: hourly, daily: daily }, {
            provider: id,
            forecastDaysServed: servedDays,
                planTier: "valid"
        });
    });
}

function detectPlan(apiKey, lat, lon, callback) {
    if (!apiKey) {
        callback({ tier: "unknown", maxForecastDays: 3, message: "" });
        return;
    }
    // On teste le max permis
    let url = "https://api.weatherapi.com/v1/forecast.json?key=" + encodeURIComponent(apiKey) +
    "&q=" + lat + "," + lon + "&days=14&aqi=no&alerts=no";

    Http.get(url, { timeoutMs: 8000 }, function (err, raw, status) {
        if (err || !raw) {
            if (status === 401 || status === 403) {
                callback({ tier: "invalid", maxForecastDays: 0, message: "Invalid API key or unauthorized." });
            } else {
                callback({ tier: "unknown", maxForecastDays: 3, message: "Network error, cannot verify key." });
            }
            return;
        }
        if (raw.error) {
            callback({ tier: "invalid", maxForecastDays: 0, message: raw.error.message || "Invalid API key." });
            return;
        }

        let served = (raw.forecast && raw.forecast.forecastday) ? raw.forecast.forecastday.length : 3;

        callback({
            tier: "valid",
            maxForecastDays: served, // Le paramètre s'ajuste dynamiquement à la réponse
            message: "API key successfully validated."
        });
    });
}
