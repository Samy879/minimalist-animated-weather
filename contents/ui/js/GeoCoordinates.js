// Cascade de géolocalisation IP, sur le même principe que la cascade météo
// de ProviderRegistry.js : on essaie un premier service, et seulement en
// cas d'échec (réseau, timeout, JSON invalide, statut HTTP non-200) on
// bascule sur le suivant. Contrat de callback inchangé pour les appelants :
// callback({ lat, lon, countryCode }) ou callback(null) si tout échoue.

function _requestJson(url, headers, onSuccess, onFailure) {
    let req = new XMLHttpRequest();
    req.open("GET", url, true);
    req.timeout = 5000;

    for (let key in headers) {
        req.setRequestHeader(key, headers[key]);
    }

    req.onreadystatechange = function () {
        if (req.readyState === 4) {
            if (req.status === 200) {
                try {
                    onSuccess(JSON.parse(req.responseText));
                } catch (error) {
                    console.error("Erreur JSON Coordonnées:", error);
                    onFailure();
                }
            } else {
                console.error("Erreur API Géo (Status): " + req.status);
                onFailure();
            }
        }
    };

    req.onerror = function () {
        console.error("Erreur réseau lors de la géo-localisation");
        onFailure();
    };

    req.ontimeout = function () {
        console.error("Délai d'attente dépassé pour la géo-localisation");
        onFailure();
    };

    req.send();
}

// --- Provider 1 : FreeIPAPI (gratuit, HTTPS, sans clé) ---
function _tryFreeIpApi(callback, onFailure) {
    _requestJson(
        "https://freeipapi.com/api/json",
        { "User-Agent": "Mozilla/5.0 (Plasma Modern Weather Widget)" },
                 function (data) {
                     if (data.latitude === undefined || data.longitude === undefined) {
                         onFailure();
                         return;
                     }
                     console.log("--- [SUCCESS] Coordonnées récupérées via FreeIPAPI");
                     callback({
                         lat: data.latitude.toString(),
                              lon: data.longitude.toString(),
                              // Code pays ISO 3166-1 alpha-2 (ex: "FR"), utilisé par
                              // ProviderRegistry.getReliabilityOrder() pour une éventuelle
                              // priorité régionale de cascade. undefined si absent.
                              countryCode: data.countryCode || undefined
                     });
                 },
                 onFailure
    );
}

// --- Provider 2 (secours) : ipwho.is (gratuit, HTTPS, sans clé) ---
// Utilisé uniquement si FreeIPAPI échoue (réseau, timeout, blocage...).
function _tryIpWhoIs(callback, onFailure) {
    _requestJson(
        "https://ipwho.is/",
        {},
        function (data) {
            if (data.success === false || data.latitude === undefined || data.longitude === undefined) {
                onFailure();
                return;
            }
            console.log("--- [SUCCESS] Coordonnées récupérées via ipwho.is (secours)");
            callback({
                lat: data.latitude.toString(),
                     lon: data.longitude.toString(),
                     countryCode: data.country_code || undefined
            });
        },
        onFailure
    );
}

function getCoordinates(callback) {
    _tryFreeIpApi(callback, function () {
        console.log("--- [geoCoordinates] Échec FreeIPAPI -> tentative via ipwho.is");
        _tryIpWhoIs(callback, function () {
            console.error("--- [geoCoordinates] Échec de tous les services de géolocalisation IP");
            callback(null);
        });
    });
}
