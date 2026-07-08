// TomorrowAdapter.js

.import "../HttpCacheService.js" as Http

var id = "tomorrowio";
var name = "Tomorrow";
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
    maxForecastDays: 5,
    safeMinInterval: 3, // Protection contre la limite de 500 requêtes/jour
    supportsPlanDetection: true
};

var CODE_TO_WMO = {
    1000: 0, 1100: 1, 1101: 2, 1102: 3, 1001: 3,
    2000: 45, 2100: 45,
    4000: 51, 4001: 63, 4200: 61, 4201: 65,
    5000: 73, 5001: 85, 5100: 71, 5101: 75,
    6000: 56, 6001: 67, 6200: 66, 6201: 67,
    7000: 77, 7101: 77, 7102: 77,
    8000: 95
};

function codeToWmo(code) {
    return (CODE_TO_WMO[code] !== undefined) ? CODE_TO_WMO[code] : 3;
}

function fetch(params, callback) {
    if (!params.apiKey) {
        callback(new Error("missing-api-key"), null, null);
        return;
    }
    let isFahrenheit = (params.tempUnit === "1" || params.tempUnit === 1);
    let days = Math.min(params.days || 7, capabilities.maxForecastDays);
    let units = isFahrenheit ? "imperial" : "metric";

    let url = "https://api.tomorrow.io/v4/weather/forecast" +
    "?location=" + params.lat + "," + params.lon +
    "&units=" + units + "&apikey=" + encodeURIComponent(params.apiKey);

    Http.get(url, { timeoutMs: 8000, cacheTtlMs: 20000 }, function (err, raw, status) {
        if (err || !raw || !raw.timelines) {
            callback(err || new Error("empty-response"), null, null, status);
            return;
        }

        let hourlyRaw = raw.timelines.hourly || [];
        let dailyRaw = raw.timelines.daily || [];

        let maxHourlySlots = days * 24;
        let hourlySlice = hourlyRaw.slice(0, maxHourlySlots);
        let dailySlice = dailyRaw.slice(0, days);

        let hourly = {
            temperature_2m: [], relative_humidity_2m: [], apparent_temperature: [],
            uv_index: [], precipitation_probability: [], cloud_cover: [],
            wind_speed_10m: [], weather_code: []
        };
        for (let i = 0; i < hourlySlice.length; i++) {
            let v = hourlySlice[i].values || {};
            hourly.temperature_2m.push(v.temperature);
            hourly.relative_humidity_2m.push(v.humidity);
            hourly.apparent_temperature.push(v.temperatureApparent);
            hourly.uv_index.push(v.uvIndex);
            hourly.precipitation_probability.push(v.precipitationProbability);
            hourly.cloud_cover.push(v.cloudCover);
            hourly.wind_speed_10m.push(v.windSpeed);
            hourly.weather_code.push(codeToWmo(v.weatherCode));
        }

        let daily = {
            time: [],
            temperature_2m_max: [], temperature_2m_min: [], weather_code: [],
            precipitation_probability_max: [], uv_index_max: [], sunrise: [], sunset: []
        };
        for (let d = 0; d < dailySlice.length; d++) {
            let v = dailySlice[d].values || {};

            let t = new Date(dailySlice[d].time);
            let dateStr = t.getFullYear() + "-" + String(t.getMonth() + 1).padStart(2, '0') + "-" + String(t.getDate()).padStart(2, '0');
            daily.time.push(dateStr);

            daily.temperature_2m_max.push(v.temperatureMax);
            daily.temperature_2m_min.push(v.temperatureMin);
            daily.weather_code.push(codeToWmo(v.weatherCodeMax || v.weatherCodeDay));
            daily.precipitation_probability_max.push(v.precipitationProbabilityMax);
            daily.uv_index_max.push(v.uvIndexMax);
            daily.sunrise.push(v.sunriseTime || null);
            daily.sunset.push(v.sunsetTime || null);
        }

        let curRaw = (hourlySlice[0] && hourlySlice[0].values) || {};
        let now = new Date();
        let current = {
            temperature_2m: curRaw.temperature,
             apparent_temperature: curRaw.temperatureApparent,
             relative_humidity_2m: curRaw.humidity,
             wind_speed_10m: curRaw.windSpeed,
             uv_index: curRaw.uvIndex,
             cloud_cover: curRaw.cloudCover,
             weather_code: codeToWmo(curRaw.weatherCode),
             is_day: (daily.sunrise[0] && daily.sunset[0] &&
             now >= new Date(daily.sunrise[0]) && now <= new Date(daily.sunset[0])) ? 1 : 0
        };

        callback(null, { current: current, hourly: hourly, daily: daily }, {
            provider: id,
            forecastDaysServed: dailySlice.length,
                planTier: "valid"
        });
    });
}

function detectPlan(apiKey, lat, lon, callback) {
    if (!apiKey) {
        callback({ tier: "unknown", maxForecastDays: capabilities.maxForecastDays, message: "" });
        return;
    }
    let url = "https://api.tomorrow.io/v4/weather/forecast?location=" + lat + "," + lon +
    "&apikey=" + encodeURIComponent(apiKey);

    Http.get(url, { timeoutMs: 8000 }, function (err, raw, status) {
        if (status === 401 || status === 403 || (raw && raw.code && raw.code >= 400000)) {
            callback({ tier: "invalid", maxForecastDays: 0, message: "Invalid API key or unauthorized." });
        } else if (err || !raw) {
            callback({ tier: "unknown", maxForecastDays: capabilities.maxForecastDays, message: "Network error, cannot verify key." });
        } else {
            callback({
                tier: "valid",
                maxForecastDays: capabilities.maxForecastDays,
                message: "API key successfully validated."
            });
        }
    });
}
