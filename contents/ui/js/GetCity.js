// Petit cache mémoire : Nominatim a des règles d'usage strictes (1 req/s,
// User-Agent obligatoire) et la ville associée à une position ne change
// jamais d'un cycle updateWeather() à l'autre tant que les coordonnées sont
// identiques. On arrondit à 3 décimales (~110m) pour absorber les micro-
// variations de géolocalisation IP sans jamais confondre deux villes
// différentes.
var _cityCache = {}; // "lat,lon,languageCode" -> nom de ville

function _cacheKey(latitude, longitude, languageCode) {
    let lat = parseFloat(latitude).toFixed(3);
    let lon = parseFloat(longitude).toFixed(3);
    return lat + "," + lon + "," + languageCode;
}

function getCityName(latitude, longitude, languageCode, callback) {
    let key = _cacheKey(latitude, longitude, languageCode);
    if (_cityCache.hasOwnProperty(key)) {
        callback(_cityCache[key]);
        return;
    }

    function fetchCity(useLanguage) {
        let url = `https://nominatim.openstreetmap.org/reverse?format=json&lat=${latitude}&lon=${longitude}`;
        if (useLanguage) {
            url += `&accept-language=${languageCode}`;
        }

        let req = new XMLHttpRequest();
        req.open("GET", url, true);

        // Timeout de 5 secondes
        req.timeout = 5000;

        // Nominatim exige un User-Agent pour éviter le blocage 403
        req.setRequestHeader("User-Agent", "ChaacWeatherPlasmoid/1.0");

        req.onreadystatechange = function () {
            if (req.readyState === 4) {
                if (req.status === 200) {
                    try {
                        let data = JSON.parse(req.responseText);
                        let address = data.address || {};
                        let city = address.city || address.town || address.village;
                        let county = address.county;
                        let state = address.state;
                        let full = city ? city : state ? state : county;

                        if (full === "Language not supported" && useLanguage) {
                            fetchCity(false);
                        } else {
                            let result = full || "Unknown";
                            if (full) _cityCache[key] = result;
                            callback(result);
                        }
                    } catch (e) {
                        console.error("Error JSON City: ", e);
                        callback("Unknown");
                    }
                } else {
                    console.error("city failed, status: " + req.status);
                    callback("Unknown");
                }
            }
        };

        req.onerror = function() { callback("Unknown"); };
        req.ontimeout = function() { callback("Unknown"); };

        req.send();
    }
    fetchCity(true);
}
