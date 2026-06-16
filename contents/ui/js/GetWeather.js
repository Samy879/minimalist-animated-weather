// GetWeather.js
function fetchAllWeather(lat, lon, tempUnit, callback) {
    // On vérifie si Fahrenheit est sélectionné (0 = Celsius, 1 = Fahrenheit)
    let isFahrenheit = (tempUnit === "1" || tempUnit === 1);

    let unitParam = isFahrenheit ? "&temperature_unit=fahrenheit&wind_speed_unit=mph" : "";

    // (température, humidité, ressenti, UV, probabilité de pluie, code météo, heure par heure)
    let hourlyParams = "temperature_2m,relative_humidity_2m,apparent_temperature,uv_index,precipitation_probability,weather_code,wind_speed_10m";

    let url = `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}${unitParam}` +
    `&current=temperature_2m,apparent_temperature,relative_humidity_2m,is_day,weather_code,wind_speed_10m,uv_index` +
    `&hourly=${hourlyParams}` +
    `&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,sunrise,sunset` +
    `&timezone=auto&_t=${Date.now()}`;

    let req = new XMLHttpRequest();
    req.open("GET", url, true);

    // Timeout de 7 secondes
    req.timeout = 7000;

    req.onreadystatechange = function () {
        if (req.readyState === 4) {
            if (req.status === 200) {
                try {
                    callback(JSON.parse(req.responseText));
                } catch (e) {
                    console.error("Erreur parsing Météo:", e);
                    callback(null);
                }
            } else {
                console.error("Erreur API Météo (Status): " + req.status);
                callback(null);
            }
        }
    };

    req.onerror = function() {
        console.error("Erreur réseau API Météo");
        callback(null);
    };

    req.ontimeout = function() {
        console.error("Délai d'attente dépassé API Météo");
        callback(null);
    };

    req.send();
}
