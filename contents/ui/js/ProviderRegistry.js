// ProviderRegistry.js
//
// Point d'entrée unique pour parler à un provider météo, quel qu'il soit.
// WeatherData.qml (orchestrateur) et GeneralConfig.qml (Smart Settings)
// passent tous les deux par ce fichier — aucun des deux ne connaît les
// détails d'implémentation d'une API en particulier.
.import "providers/OpenMeteoAdapter.js" as OpenMeteo
.import "providers/MetNorwayAdapter.js" as MetNorway
.import "providers/WeatherApiAdapter.js" as WeatherApi
.import "providers/TomorrowAdapter.js" as Tomorrow
.import "providers/OpenWeatherMapAdapter.js" as OpenWeatherMap
.import "providers/VisualCrossingAdapter.js" as VisualCrossing
.import "providers/PirateWeatherAdapter.js" as PirateWeather

// Ordre de fiabilité utilisé pour la cascade automatique en cas d'échec
// (réseau, clé absente/invalide, parsing...). Classé par couverture de
// données et par robustesse, PAS par "a besoin d'une clé ou pas" : un
// provider sans clé fournie échoue de toute façon instantanément (voir
// chaque adapter, vérification synchrone avant toute requête réseau), donc
// il glisse automatiquement au suivant sans pénaliser qui n'a pas de clé.
//
//   1. openmeteo     : 7/7 détails, 16 jours, sans clé, intervalle 1 min.
//   2. weatherapi     : 7/7 détails, 14 jours, intervalle 1 min (clé requise,
//                       ~1 million d'appels/mois).
//   3. openweathermap : 7/7 détails, 8 jours, clé requise, 1 000 appels/jour
//                       (One Call API 3.0).
//   4. visualcrossing : 7/7 détails, 15 jours, clé requise, mais quota en
//                       "records" (pas en appels bruts) -> intervalle plus
//                       prudent (voir l'adapter).
//   5. pirateweather  : 7/7 détails, mais seulement 7 jours de prévision,
//                       clé requise. Palier gratuit permanent (~10 000 à
//                       25 000 appels/mois selon soutien) -> intervalle
//                       prudent (voir l'adapter), pas de carte bancaire.
//   6. metnorway      : 6/7 détails (pas de proba de pluie), 9 jours, sans
//                       clé mais intervalle 10 min (risque de ban IP si trop
//                       vite).
//   7. tomorrowio     : 7/7 détails mais seulement 5 jours et quota le plus
//                       restreint (500 appels/jour) -> dernier recours.
var RELIABILITY_ORDER = ["openmeteo", "weatherapi", "openweathermap", "visualcrossing", "pirateweather", "metnorway", "tomorrowio"];

// Priorité régionale optionnelle : permet de faire remonter certains
// providers en tête de cascade pour un pays donné (code ISO 3166-1 alpha-2,
// tel que renvoyé par geoCoordinates.js / FreeIPAPI), sans toucher à
// RELIABILITY_ORDER qui reste l'ordre "par défaut" / international.
//
// Vide pour l'instant : aucun provider actuel n'a d'avantage régional assez
// net pour justifier un bonus (OpenWeatherMap et Visual Crossing sont des
// services globaux ; Open-Meteo utilise déjà le meilleur modèle disponible
// localement de son propre côté). La mécanique reste prête si un futur
// provider à forte spécialisation géographique est ajouté : il suffit
// d'ajouter une entrée ici, ex. { "FR": ["unProviderFrancais", ...] }.
var REGIONAL_PRIORITY = {};

// Chaîne de remplacement utilisée par l'auto-switch quand un détail coché
// devient indisponible suite à un changement de provider. Générique : pas
// seulement UV<->Pluie, pour rester correct si une future API a d'autres trous.
var FALLBACK_CHAIN = {
    uvIndex: ["rainProbability", "cloudCover"],
    rainProbability: ["uvIndex", "cloudCover"],
    apparentTemp: ["temperature"],
    cloudCover: ["humidity"]
};

function _adapters() {
    return {
        openmeteo: OpenMeteo,
        metnorway: MetNorway,
        weatherapi: WeatherApi,
        tomorrowio: Tomorrow,
        openweathermap: OpenWeatherMap,
        visualcrossing: VisualCrossing,
        pirateweather: PirateWeather
    };
}

/**
 * Retourne la liste brute de tous les IDs de providers (ordre arbitraire).
 * Préférer getSortedProviderIds() pour les menus UI.
 */
function getProviderIds() {
    return ["openmeteo", "metnorway", "weatherapi", "openweathermap", "visualcrossing", "pirateweather", "tomorrowio"];
}

/**
 * Retourne les IDs triés pour l'affichage UI :
 *   1. Providers sans clé (gratuits) en tête, dans l'ordre de fiabilité.
 *   2. Puis providers avec clé, dans l'ordre de fiabilité.
 *
 * Cet ordre est à la fois pédagogique (les nouveaux utilisateurs voient
 * d'abord ce qui fonctionne sans configuration) et cohérent avec la cascade
 * (RELIABILITY_ORDER est respecté au sein de chaque groupe).
 *
 * Note : si tous les providers d'un futur ajout sont sans clé ou avec clé,
 * l'ordre relatif entre eux est automatiquement correct sans toucher à
 * cette fonction — seul RELIABILITY_ORDER doit être mis à jour.
 */
function getSortedProviderIds() {
    let free = RELIABILITY_ORDER.filter(function (id) {
        let a = _adapters()[id];
        return a && !a.requiresKey;
    });
    let paid = RELIABILITY_ORDER.filter(function (id) {
        let a = _adapters()[id];
        return a && a.requiresKey;
    });
    return free.concat(paid);
    // Résultat actuel :
    //   free : ["openmeteo", "metnorway"]
    //   paid : ["weatherapi", "openweathermap", "visualcrossing", "pirateweather", "tomorrowio"]
}

function getAdapter(providerId) {
    let a = _adapters()[providerId];
    return a || OpenMeteo;
}

function getProviderMeta(providerId) {
    let a = getAdapter(providerId);
    return { id: a.id, name: a.name, requiresKey: a.requiresKey };
}

function getCapabilities(providerId) {
    return getAdapter(providerId).capabilities;
}

function isDetailSupported(providerId, detailId) {
    let caps = getCapabilities(providerId);
    return !!(caps && caps.details && caps.details[detailId]);
}

function mergeParams(base, extra) {
    let out = {};
    for (let k in base) out[k] = base[k];
    for (let k in extra) out[k] = extra[k];
    return out;
}

/**
 * Renvoie RELIABILITY_ORDER, éventuellement réordonné pour faire remonter
 * en tête les providers listés dans REGIONAL_PRIORITY[countryCode] (s'il y
 * en a). Les providers non listés gardent leur ordre relatif d'origine.
 * Sans countryCode, ou si REGIONAL_PRIORITY est vide pour ce pays, on
 * retombe simplement sur l'ordre par défaut.
 */
function getReliabilityOrder(countryCode) {
    let base = RELIABILITY_ORDER.slice();
    let boost = countryCode && REGIONAL_PRIORITY[countryCode];
    if (!boost || boost.length === 0) return base;

    let boosted = boost.filter(function (id) { return base.indexOf(id) !== -1; });
    let rest = base.filter(function (id) { return boosted.indexOf(id) === -1; });
    return boosted.concat(rest);
}

/**
 * Renvoie la clé API à utiliser pour `providerId` lors d'une tentative de la
 * cascade. `params.apiKeys` (optionnel) est une map { weatherapi: "...",
 * tomorrowio: "..." } fournie par l'appelant : ça permet d'utiliser la VRAIE
 * clé de chaque provider rencontré pendant la cascade, et pas seulement
 * celle du provider sélectionné par l'utilisateur. Si l'appelant ne fournit
 * que l'ancien contrat (params.apiKey, sans apiKeys), cette clé n'est
 * réutilisée que pour le provider explicitement demandé.
 */
function apiKeyFor(providerId, params, requestedProviderId) {
    if (params.apiKeys && params.apiKeys[providerId] !== undefined) {
        return params.apiKeys[providerId] || "";
    }
    return (providerId === requestedProviderId) ? (params.apiKey || "") : "";
}

/**
 * Récupère la météo en essayant d'abord le provider choisi par l'utilisateur,
 * puis, en cas d'échec (réseau, clé absente/invalide, parsing...), le reste
 * de la cascade de fiabilité (RELIABILITY_ORDER, éventuellement réordonnée
 * via params.countryCode -> voir getReliabilityOrder) dans l'ordre, jusqu'à
 * ce qu'une tentative réussisse ou que tous les providers aient échoué.
 * Signale `usedFallback` dans le callback dès que le provider effectivement
 * utilisé n'est pas celui demandé, pour que l'UI puisse, si elle le
 * souhaite, l'indiquer discrètement.
 */
function fetchWeather(providerId, params, callback) {
    let cascade = getReliabilityOrder(params.countryCode);
    let order = [providerId].concat(cascade.filter(function (id) { return id !== providerId; }));

    function tryAt(i) {
        if (i >= order.length) {
            callback(new Error("all-providers-failed"), null, null, true);
            return;
        }

        let currentId = order[i];
        let adapter = getAdapter(currentId);
        let attemptParams = mergeParams(params, { apiKey: apiKeyFor(currentId, params, providerId) });

        adapter.fetch(attemptParams, function (err, data, meta) {
            if (!err && data) {
                callback(null, data, meta, currentId !== providerId);
                return;
            }

            if (currentId === providerId) {
                console.log("--- [ProviderRegistry] Échec provider '" + currentId + "' (" + err + ") -> cascade de fiabilité");
            } else {
                console.log("--- [ProviderRegistry] Échec provider '" + currentId + "' (" + err + ") -> tentative suivante de la cascade");
            }
            tryAt(i + 1);
        });
    }

    tryAt(0);
}

function detectPlan(providerId, apiKey, lat, lon, callback) {
    getAdapter(providerId).detectPlan(apiKey, lat, lon, callback);
}

/**
 * Ajuste une liste ordonnée de détails sélectionnés pour qu'elle reste valide
 * vis-à-vis des capacités du nouveau provider. Retourne :
 *   { order: [...nouvel ordre...], changed: bool, removedIds: [...], addedIds: [...] }
 *
 * Logique :
 *   1. On retire les détails non supportés par le nouveau provider.
 *   2. Pour chaque détail retiré, on essaie de le remplacer (même position)
 *      par le premier candidat de sa FALLBACK_CHAIN qui est supporté et pas
 *      déjà présent dans la liste.
 */
function adjustDetailsForProvider(currentOrder, providerId) {
    let caps = getCapabilities(providerId);
    if (!caps) return { order: currentOrder, changed: false, removedIds: [], addedIds: [] };

    let removedIds = [];
    let addedIds = [];
    let newOrder = currentOrder.slice();

    for (let i = 0; i < newOrder.length; i++) {
        let detailId = newOrder[i];
        if (isDetailSupported(providerId, detailId)) continue;

        removedIds.push(detailId);
        let replacement = null;
        let chain = FALLBACK_CHAIN[detailId] || [];
        for (let c = 0; c < chain.length; c++) {
            let candidate = chain[c];
            if (isDetailSupported(providerId, candidate) && newOrder.indexOf(candidate) === -1) {
                replacement = candidate;
                break;
            }
        }

        if (replacement) {
            newOrder[i] = replacement;
            addedIds.push(replacement);
        } else {
            newOrder.splice(i, 1);
            i--;
        }
    }

    return {
        order: newOrder,
        changed: removedIds.length > 0,
        removedIds: removedIds,
        addedIds: addedIds
    };
}
