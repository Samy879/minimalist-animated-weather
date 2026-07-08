// HttpCacheService.js
//
// Service HTTP/Cache centralisé utilisé par tous les adaptateurs provider.
// Objectifs :
//   - Une seule implémentation XHR (timeout, headers, parsing JSON, erreurs)
//     au lieu d'une copie par fichier *.js comme avant.
//   - Un très court cache mémoire (par URL) pour éviter un double appel réseau
//     si le popup est refermé/réouvert juste après un refresh (le widget reste
//     chargé en mémoire tout le temps de la session Plasma, donc ce cache vit
//     d'un cycle de rafraîchissement à l'autre).
//
// Le cache est désactivé par défaut (cacheTtlMs absent ou 0) : chaque
// adaptateur météo doit explicitement passer `cacheTtlMs` (20000 par
// convention) pour en bénéficier sur son appel `fetch()`. Volontairement
// TRÈS court : on ne veut pas "inventer" une fraîcheur de donnée, juste
// absorber les rafales d'appels (ex: ouverture rapide du popup, changement
// d'unité qui retrigger updateWeather()). Les appels de validation de clé
// (detectPlan) ne doivent PAS passer cacheTtlMs : ils doivent toujours
// revalider en direct.
//
// IMPORTANT : les URLs des adaptateurs ne doivent plus contenir de
// paramètre anti-cache (ex. ancien "&_t=" + Date.now()) — la clé de cache
// ici est l'URL complète, donc un tel paramètre rendrait le cache inopérant
// en garantissant une URL différente à chaque appel.

var _cache = {}; // url -> { ts, data }

function _now() {
    return new Date().getTime();
}

/**
 * Effectue une requête GET avec gestion de timeout/erreurs uniforme.
 *
 * @param {string} url
 * @param {object} options { headers: {}, timeoutMs: 7000, cacheTtlMs: 0 }
 * @param {function} callback (error, data|null, rawStatus)
 */
function get(url, options, callback) {
    options = options || {};
    let cacheTtlMs = options.cacheTtlMs || 0;

    if (cacheTtlMs > 0 && _cache[url] && (_now() - _cache[url].ts) < cacheTtlMs) {
        callback(null, _cache[url].data, 200);
        return;
    }

    let req = new XMLHttpRequest();
    req.open("GET", url, true);
    req.timeout = options.timeoutMs || 7000;

    let headers = options.headers || {};
    for (let key in headers) {
        if (headers.hasOwnProperty(key)) {
            req.setRequestHeader(key, headers[key]);
        }
    }

    req.onreadystatechange = function () {
        if (req.readyState === 4) {
            if (req.status >= 200 && req.status < 300) {
                try {
                    let parsed = JSON.parse(req.responseText);
                    if (cacheTtlMs > 0) {
                        _cache[url] = { ts: _now(), data: parsed };
                    }
                    callback(null, parsed, req.status);
                } catch (e) {
                    console.error("--- [HttpCacheService] Erreur parsing JSON: " + e + " (" + url + ")");
                    callback(e, null, req.status);
                }
            } else {
                console.error("--- [HttpCacheService] Erreur HTTP " + req.status + " (" + url + ")");
                callback(new Error("HTTP " + req.status), null, req.status);
            }
        }
    };

    req.onerror = function () {
        console.error("--- [HttpCacheService] Erreur réseau (" + url + ")");
        callback(new Error("network-error"), null, 0);
    };

    req.ontimeout = function () {
        console.error("--- [HttpCacheService] Timeout (" + url + ")");
        callback(new Error("timeout"), null, 0);
    };

    req.send();
}

function clearCache() {
    _cache = {};
}
