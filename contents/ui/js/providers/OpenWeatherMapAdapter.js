// OpenWeatherMapAdapter.js
//
// Utilise l'API "One Call API 3.0" d'OpenWeatherMap.
// https://api.openweathermap.org/data/3.0/onecall
// Gratuit jusqu'à 1 000 appels/jour (souscription "One Call by Call", carte
// bancaire requise à l'inscription mais pas de prélèvement sous le seuil).

.import "../HttpCacheService.js" as Http

var id = "openweathermap";
var name = "OpenWeatherMap";
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
    maxForecastDays: 8, // One Call 3.0 : 8 jours de prévision journalière, 48h horaire
    safeMinInterval: 2, // 1 000 appels/jour -> environ 1 appel/1.44 min ; 2 min reste large
    supportsPlanDetection: true
};

// OpenWeatherMap utilise les "Condition codes" (id du tableau "weather").
// https://openweathermap.org/weather-conditions
var CODE_TO_WMO = {
    200: 95, 201: 95, 202: 96, 210: 95, 211: 95, 212: 96, 221: 96, 230: 95, 231: 95, 232: 96,
    300: 51, 301: 53, 302: 55, 310: 51, 311: 53, 312: 55, 313: 80, 314: 82, 321: 53,
    500: 61, 501: 63, 502: 65, 503: 65, 504: 65, 511: 67,
    520: 80, 521: 81, 522: 82, 531: 82,
    600: 71, 601: 73, 602: 75, 611: 67, 612: 67, 613: 67, 615: 73, 616: 73, 620: 85, 621: 86, 622: 86,
    701: 45, 711: 45, 721: 45, 731: 45, 741: 45, 751: 45, 761: 45, 762: 45, 771: 95, 781: 99,
    800: 0, 801: 1, 802: 2, 803: 3, 804: 3
};

function codeToWmo(code) {
    return (CODE_TO_WMO[code] !== undefined) ? CODE_TO_WMO[code] : 3;
}

function msToKmh(ms) {
    return (ms === undefined || ms === null) ? null : ms * 3.6;
}

function utcSecondsToLocalIso(unixSeconds, tzOffsetSeconds) {
    if (unixSeconds === undefined || unixSeconds === null) return null;
    let local = new Date((unixSeconds + (tzOffsetSeconds || 0)) * 1000);
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
    let units = isFahrenheit ? "imperial" : "metric";
    let days = Math.min(params.days || 7, capabilities.maxForecastDays);

    let url = "https://api.openweathermap.org/data/3.0/onecall" +
    "?lat=" + params.lat + "&lon=" + params.lon +
    "&units=" + units + "&exclude=minutely,alerts" +
    "&appid=" + encodeURIComponent(params.apiKey);

    Http.get(url, { timeoutMs: 8000, cacheTtlMs: 20000 }, function (err, raw, status) {
        if (err || !raw || !raw.current || !raw.daily) {
            callback(err || new Error("empty-response"), null, null, status);
            return;
        }

        let tzOffset = raw.timezone_offset || 0;

        let hourlyRaw = (raw.hourly || []).slice(0, days * 24);
        let dailyRaw = (raw.daily || []).slice(0, days);

        let hourly = {
            temperature_2m: [], relative_humidity_2m: [], apparent_temperature: [],
            uv_index: [], precipitation_probability: [], cloud_cover: [],
            wind_speed_10m: [], weather_code: []
        };
        for (let h = 0; h < hourlyRaw.length; h++) {
            let hr = hourlyRaw[h];
            hourly.temperature_2m.push(hr.temp);
            hourly.relative_humidity_2m.push(hr.humidity);
            hourly.apparent_temperature.push(hr.feels_like);
            hourly.uv_index.push(hr.uvi);
            hourly.precipitation_probability.push((hr.pop !== undefined) ? Math.round(hr.pop * 100) : null);
            hourly.cloud_cover.push(hr.clouds);
            hourly.wind_speed_10m.push(isFahrenheit ? hr.wind_speed : msToKmh(hr.wind_speed));
            hourly.weather_code.push(codeToWmo(hr.weather && hr.weather[0] ? hr.weather[0].id : null));
        }

        let daily = {
            time: [],
            temperature_2m_max: [], temperature_2m_min: [], weather_code: [],
            precipitation_probability_max: [], uv_index_max: [], sunrise: [], sunset: []
        };
        for (let d = 0; d < dailyRaw.length; d++) {
            let dy = dailyRaw[d];
            daily.time.push(utcSecondsToLocalIso(dy.dt, tzOffset).slice(0, 10));
            daily.temperature_2m_max.push(dy.temp ? dy.temp.max : null);
            daily.temperature_2m_min.push(dy.temp ? dy.temp.min : null);
            daily.weather_code.push(codeToWmo(dy.weather && dy.weather[0] ? dy.weather[0].id : null));
            daily.precipitation_probability_max.push((dy.pop !== undefined) ? Math.round(dy.pop * 100) : null);
            daily.uv_index_max.push(dy.uvi);
            daily.sunrise.push(utcSecondsToLocalIso(dy.sunrise, tzOffset));
            daily.sunset.push(utcSecondsToLocalIso(dy.sunset, tzOffset));
        }

        let cur = raw.current;
        let current = {
            temperature_2m: cur.temp,
             apparent_temperature: cur.feels_like,
             relative_humidity_2m: cur.humidity,
             wind_speed_10m: isFahrenheit ? cur.wind_speed : msToKmh(cur.wind_speed),
             uv_index: cur.uvi,
             cloud_cover: cur.clouds,
             weather_code: codeToWmo(cur.weather && cur.weather[0] ? cur.weather[0].id : null),
             is_day: (cur.sunrise && cur.sunset && cur.dt >= cur.sunrise && cur.dt <= cur.sunset) ? 1 : 0
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
    let url = "https://api.openweathermap.org/data/3.0/onecall" +
    "?lat=" + lat + "&lon=" + lon + "&exclude=minutely,alerts,hourly" +
    "&appid=" + encodeURIComponent(apiKey);

    Http.get(url, { timeoutMs: 8000 }, function (err, raw, status) {
        if (status === 401 || (raw && raw.cod === 401)) {
            callback({ tier: "invalid", maxForecastDays: 0, message: raw && raw.message ? raw.message : "Invalid API key or unauthorized." });
            return;
        }
        if (err || !raw || !raw.daily) {
            callback({ tier: "unknown", maxForecastDays: capabilities.maxForecastDays, message: "Network error, cannot verify key." });
            return;
        }

        callback({
            tier: "valid",
            maxForecastDays: raw.daily.length || capabilities.maxForecastDays,
            message: "API key successfully validated."
        });
    });
}
