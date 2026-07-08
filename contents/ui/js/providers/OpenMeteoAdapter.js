// OpenMeteoAdapter.js

.import "../ForecastAggregator.js" as Aggregator
.import "../HttpCacheService.js" as Http

var id = "openmeteo";
var name = "Open-Meteo (recommended)";
var requiresKey = false;

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
    maxForecastDays: 16, // On demande le max absolu, on filtrera les jours vides au retour
    safeMinInterval: 1,  // API généreuse, 1 min (1440/jour) est sans aucun risque
    supportsPlanDetection: false
};

function fetch(params, callback) {
    let isFahrenheit = (params.tempUnit === "1" || params.tempUnit === 1);
    let unitParam = isFahrenheit ? "&temperature_unit=fahrenheit&wind_speed_unit=mph" : "";
    let requestedDays = Math.min(params.days || 7, capabilities.maxForecastDays);
    let requestDays = capabilities.maxForecastDays; // on demande toujours le max pour profiter du filtre anti-0°

    let hourlyParams = "temperature_2m,relative_humidity_2m,apparent_temperature,uv_index," +
    "precipitation_probability,cloud_cover,weather_code,wind_speed_10m";
    let dailyParams = "weather_code,temperature_2m_max,temperature_2m_min," +
    "precipitation_probability_max,uv_index_max,sunrise,sunset";

    let url = "https://api.open-meteo.com/v1/forecast" +
    "?latitude=" + params.lat + "&longitude=" + params.lon + unitParam +
    "&current=temperature_2m,apparent_temperature,relative_humidity_2m,is_day,weather_code,wind_speed_10m,uv_index,cloud_cover" +
    "&hourly=" + hourlyParams +
    "&daily=" + dailyParams +
    "&forecast_days=" + requestDays +
    "&timezone=auto";

    Http.get(url, { timeoutMs: 7000, cacheTtlMs: 20000 }, function (err, raw, status) {
        if (err || !raw || !raw.daily || !raw.daily.time) {
            callback(err || new Error("empty-response"), null, null);
            return;
        }

        // Filtre intelligent "Anti 0°" : On retire de la fin du tableau les jours
        // qui n'ont pas encore de température maximale calculée par l'API.
        let validDays = raw.daily.time.length;
        while (validDays > 0 && raw.daily.temperature_2m_max[validDays - 1] === null) {
            validDays--;
        }

        // *** FIX ***
        // On respecte aussi le nombre de jours demandé par l'utilisateur (params.days).
        // Avant ce correctif, validDays ne dépendait que des données réellement
        // renvoyées par Open-Meteo (souvent ~14), en ignorant complètement la
        // préférence "days" choisie dans la config.
        validDays = Math.min(validDays, requestedDays);

        // On coupe tous les tableaux journaliers à la taille valide exacte
        for (let key in raw.daily) {
            if (Array.isArray(raw.daily[key])) {
                raw.daily[key] = raw.daily[key].slice(0, validDays);
            }
        }

        // *** FIX ***
        // On coupe aussi les séries horaires sur la même période. Avant, le
        // tableau "hourly" n'était jamais tronqué (toujours jusqu'à 16*24
        // heures), même quand "daily" était coupé à 7 ou 14 jours.
        let validHourlySlots = validDays * 24;
        for (let key in raw.hourly) {
            if (Array.isArray(raw.hourly[key])) {
                raw.hourly[key] = raw.hourly[key].slice(0, validHourlySlots);
            }
        }

        raw.daily = Aggregator.fillMissingDailyAggregates(raw.hourly, raw.daily, validDays);

        callback(null, raw, {
            provider: id,
            forecastDaysServed: validDays, // Le widget s'ajustera sur CE chiffre précis
                planTier: "free"
        });
    });
}

function detectPlan(apiKey, lat, lon, callback) {
    // Par convention pour Open-Meteo on retourne 14 pour l'UX,
    // mais le vrai nombre sera ajusté par le fetch réel
    callback({ tier: "free", maxForecastDays: 14, message: "" });
}
