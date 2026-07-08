// MetNorwayAdapter.js

.import "../ForecastAggregator.js" as Aggregator
.import "../SolarCalc.js" as Solar
.import "../HttpCacheService.js" as Http

var id = "metnorway";
var name = "MET Norway (Yr)";
var requiresKey = false;

var capabilities = {
    details: {
        temperature: true,
        apparentTemp: true,
        humidity: true,
        windSpeed: true,
        uvIndex: true,
        rainProbability: false,
        cloudCover: true
    },
    maxForecastDays: 9,
    safeMinInterval: 10, // <-- Pour éviter d'être banni par les serveurs norvégiens
    supportsPlanDetection: false
};

var USER_AGENT = "MinimalistAnimatedWeatherPlasmoid/2.0 (contact: plasma-widget-user)";

function steadmanApparentTemp(tC, rh, windMs) {
    let e = (rh / 100) * 6.105 * Math.exp((17.27 * tC) / (237.7 + tC));
    return tC + (0.33 * e) - (0.70 * windMs) - 4.00;
}

var SYMBOL_TO_WMO = {
    clearsky: 0, fair: 1, partlycloudy: 2, cloudy: 3, fog: 45,
    lightrain: 61, rain: 63, heavyrain: 65,
    lightrainshowers: 80, rainshowers: 81, heavyrainshowers: 82,
    lightsleet: 71, sleet: 73, heavysleet: 75,
    lightsleetshowers: 80, sleetshowers: 81, heavysleetshowers: 82,
    lightsnow: 71, snow: 73, heavysnow: 75,
    lightsnowshowers: 85, snowshowers: 85, heavysnowshowers: 86,
    rainandthunder: 95, lightrainandthunder: 95, heavyrainandthunder: 96,
    rainshowersandthunder: 95, lightrainshowersandthunder: 95, heavyrainshowersandthunder: 96,
    sleetandthunder: 96, lightsleetandthunder: 95, heavysleetandthunder: 99,
    sleetshowersandthunder: 96, lightsleetshowersandthunder: 95, heavysleetshowersandthunder: 99,
    snowandthunder: 96, lightsnowandthunder: 95, heavysnowandthunder: 99,
    snowshowersandthunder: 96, lightsnowshowersandthunder: 95, heavysnowshowersandthunder: 99
};

function symbolToWmo(symbolCode) {
    if (!symbolCode) return 3;
    let base = symbolCode.replace(/_day$|_night$|_polartwilight$/, "");
    return (SYMBOL_TO_WMO[base] !== undefined) ? SYMBOL_TO_WMO[base] : 3;
}

function isSymbolDay(symbolCode) {
    if (!symbolCode) return true;
    return symbolCode.indexOf("_night") === -1;
}

function fetch(params, callback) {
    let days = Math.min(params.days || 7, capabilities.maxForecastDays);
    let isFahrenheit = (params.tempUnit === "1" || params.tempUnit === 1);

    let url = "https://api.met.no/weatherapi/locationforecast/2.0/complete" +
    "?lat=" + params.lat + "&lon=" + params.lon;

    Http.get(url, { headers: { "User-Agent": USER_AGENT }, timeoutMs: 8000, cacheTtlMs: 20000 }, function (err, raw, status) {
        if (err || !raw || !raw.properties || !raw.properties.timeseries) {
            callback(err || new Error("empty-response"), null, null);
            return;
        }

        let series = raw.properties.timeseries;
        let now = new Date();
        let dayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        let totalSlots = days * 24;

        let sparse = {
            temperature_2m: [], relative_humidity_2m: [], wind_speed_10m: [],
            uv_index: [], cloud_cover: [], weather_code: []
        };

        let currentEntry = null;
        let minDeltaToNow = Infinity;

        for (let i = 0; i < series.length; i++) {
            let entry = series[i];
            let t = new Date(entry.time);
            let hourIndex = Math.round((t - dayStart) / 3600000);
            if (hourIndex < 0 || hourIndex >= totalSlots) continue;

            let det = entry.data && entry.data.instant && entry.data.instant.details;
            if (!det) continue;

            if (det.air_temperature !== undefined) {
                sparse.temperature_2m.push({ index: hourIndex, value: isFahrenheit ? (det.air_temperature * 9 / 5 + 32) : det.air_temperature });
            }
            if (det.relative_humidity !== undefined) {
                sparse.relative_humidity_2m.push({ index: hourIndex, value: det.relative_humidity });
            }
            if (det.wind_speed !== undefined) {
                let w = det.wind_speed;
                sparse.wind_speed_10m.push({ index: hourIndex, value: isFahrenheit ? (w * 2.23694) : (w * 3.6) });
            }
            if (det.ultraviolet_index_clear_sky !== undefined) {
                sparse.uv_index.push({ index: hourIndex, value: det.ultraviolet_index_clear_sky });
            }
            if (det.cloud_area_fraction !== undefined) {
                sparse.cloud_cover.push({ index: hourIndex, value: det.cloud_area_fraction });
            }

            let summaryBlock = (entry.data.next_1_hours && entry.data.next_1_hours.summary) ||
            (entry.data.next_6_hours && entry.data.next_6_hours.summary) ||
            (entry.data.next_12_hours && entry.data.next_12_hours.summary);
            if (summaryBlock && summaryBlock.symbol_code) {
                sparse.weather_code.push({ index: hourIndex, value: symbolToWmo(summaryBlock.symbol_code) });
            }

            let delta = Math.abs(t - now);
            if (delta < minDeltaToNow) {
                minDeltaToNow = delta;
                currentEntry = { det: det, symbol: (summaryBlock && summaryBlock.symbol_code) || null };
            }
        }

        let hourly = {
            temperature_2m: Aggregator.denseInterpolate(sparse.temperature_2m, totalSlots),
             relative_humidity_2m: Aggregator.denseInterpolate(sparse.relative_humidity_2m, totalSlots),
             wind_speed_10m: Aggregator.denseInterpolate(sparse.wind_speed_10m, totalSlots),
             uv_index: Aggregator.denseInterpolate(sparse.uv_index, totalSlots),
             cloud_cover: Aggregator.denseInterpolate(sparse.cloud_cover, totalSlots),
             weather_code: Aggregator.denseInterpolate(sparse.weather_code, totalSlots).map(function (v) {
                 return v === null ? 3 : Math.round(v);
             })
        };

        hourly.apparent_temperature = [];
        for (let h = 0; h < totalSlots; h++) {
            let tC = isFahrenheit ? (hourly.temperature_2m[h] - 32) * 5 / 9 : hourly.temperature_2m[h];
            let windMs = isFahrenheit ? hourly.wind_speed_10m[h] / 2.23694 : hourly.wind_speed_10m[h] / 3.6;
            let feelsC = steadmanApparentTemp(tC, hourly.relative_humidity_2m[h] || 0, windMs || 0);
            hourly.apparent_temperature[h] = isFahrenheit ? (feelsC * 9 / 5 + 32) : feelsC;
        }

        let daily = { time: [], temperature_2m_max: [], temperature_2m_min: [], weather_code: [], sunrise: [], sunset: [] };
        for (let d = 0; d < days; d++) {
            let block = hourly.temperature_2m.slice(d * 24, d * 24 + 24).filter(function (v) { return v !== null; });
            daily.temperature_2m_max.push(block.length ? Math.max.apply(null, block) : null);
            daily.temperature_2m_min.push(block.length ? Math.min.apply(null, block) : null);

            let codeBlock = hourly.weather_code.slice(d * 24, d * 24 + 24);
            daily.weather_code.push(codeBlock[12] !== undefined ? codeBlock[12] : codeBlock[0]);

            let dDate = new Date(dayStart.getFullYear(), dayStart.getMonth(), dayStart.getDate() + d);

            let dateStr = dDate.getFullYear() + "-" + String(dDate.getMonth() + 1).padStart(2, '0') + "-" + String(dDate.getDate()).padStart(2, '0');
            daily.time.push(dateStr);

            let sun = Solar.getSunTimesIso(dDate, parseFloat(params.lat), parseFloat(params.lon));
            daily.sunrise.push(sun.sunrise);
            daily.sunset.push(sun.sunset);
        }
        daily = Aggregator.fillMissingDailyAggregates(hourly, daily, days);

        let current = currentEntry ? {
            temperature_2m: isFahrenheit ? (currentEntry.det.air_temperature * 9 / 5 + 32) : currentEntry.det.air_temperature,
             relative_humidity_2m: currentEntry.det.relative_humidity,
             wind_speed_10m: isFahrenheit ? (currentEntry.det.wind_speed * 2.23694) : (currentEntry.det.wind_speed * 3.6),
             uv_index: currentEntry.det.ultraviolet_index_clear_sky,
             cloud_cover: currentEntry.det.cloud_area_fraction,
             apparent_temperature: hourly.apparent_temperature[0],
             weather_code: currentEntry.symbol ? symbolToWmo(currentEntry.symbol) : hourly.weather_code[0],
             is_day: currentEntry.symbol ? (isSymbolDay(currentEntry.symbol) ? 1 : 0) : 1
        } : null;

        if (!current) {
            callback(new Error("no-current-entry"), null, null);
            return;
        }

        callback(null, { current: current, hourly: hourly, daily: daily }, {
            provider: id,
            forecastDaysServed: days,
                planTier: "free"
        });
    });
}

function detectPlan(apiKey, lat, lon, callback) {
    callback({ tier: "free", maxForecastDays: capabilities.maxForecastDays, message: "" });
}
