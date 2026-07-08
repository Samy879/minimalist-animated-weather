// ForecastAggregator.js
//
// Toutes les APIs ne fournissent pas les mêmes agrégats journaliers nativement
// (ex: Open-Meteo donne precipitation_probability_max par jour, mais pas
// cloud_cover_mean ; MET Norway ne donne quasiment aucun agrégat journalier).
//
// Plutôt que de dépendre du bon vouloir de chaque API pour CES agrégats
// précis, on les recalcule nous-mêmes à partir des séries horaires déjà
// normalisées (mêmes champs pour tous les adaptateurs). Ça garantit un calcul
// rigoureux et IDENTIQUE quel que soit le provider actif — conforme à la
// règle "zéro invention" : on ne fait que dériver d'une donnée déjà fournie,
// jamais inventer une valeur absente.
//
// Si la série horaire source est absente pour un jour donné, l'agrégat de ce
// jour est `null` (jamais 0 ou une moyenne bidon).

function _dayBlock(arr, dayIndex) {
    if (!arr) return null;
    let start = dayIndex * 24;
    let block = arr.slice(start, start + 24).filter(function (v) {
        return v !== null && v !== undefined && !isNaN(v);
    });
    return block.length > 0 ? block : null;
}

function maxOfDay(hourlyArr, dayIndex) {
    let block = _dayBlock(hourlyArr, dayIndex);
    if (!block) return null;
    return Math.max.apply(null, block);
}

function meanOfDay(hourlyArr, dayIndex) {
    let block = _dayBlock(hourlyArr, dayIndex);
    if (!block) return null;
    let sum = block.reduce(function (a, b) { return a + b; }, 0);
    return sum / block.length;
}

/**
 * Certaines APIs (MET Norway notamment) ne fournissent des points qu'à
 * résolution horaire pour les 2-3 premiers jours, puis passent à une
 * résolution 6h au-delà. Pour produire un tableau dense (1 valeur/heure,
 * requis par LineChart.qml) sans jamais "trouer" le graphique, on interpole
 * linéairement entre les points RÉELLEMENT fournis par l'API.
 *
 * Ceci n'est PAS une invention de donnée : c'est une simple interpolation
 * mathématique entre deux mesures connues (pratique standard de tout
 * graphique météo), jamais une extrapolation au-delà des points connus côté
 * bords (les bords sont prolongés à plat avec la valeur connue la plus proche).
 *
 * @param {Array<{index:number, value:number}>} sparsePoints triés par index croissant
 * @param {number} totalSlots taille du tableau dense à produire (ex: dayCount*24)
 */
function denseInterpolate(sparsePoints, totalSlots) {
    let out = new Array(totalSlots).fill(null);
    if (!sparsePoints || sparsePoints.length === 0) return out;

    let pts = sparsePoints.slice().sort(function (a, b) { return a.index - b.index; });

    for (let i = 0; i < pts.length - 1; i++) {
        let p0 = pts[i], p1 = pts[i + 1];
        let span = p1.index - p0.index;
        for (let idx = p0.index; idx <= p1.index && idx < totalSlots; idx++) {
            if (idx < 0) continue;
            let ratio = span === 0 ? 0 : (idx - p0.index) / span;
            out[idx] = p0.value + (p1.value - p0.value) * ratio;
        }
    }
    let first = pts[0], last = pts[pts.length - 1];
    for (let idx = 0; idx < first.index && idx < totalSlots; idx++) out[idx] = first.value;
    for (let idx = last.index; idx < totalSlots; idx++) if (idx >= 0) out[idx] = last.value;

    return out;
}

/**
 * Construit les agrégats journaliers manquants pour `dayCount` jours, à
 * partir des séries horaires déjà présentes dans `hourly`.
 * Ne touche jamais aux champs déjà fournis nativement par l'API (ex: si
 * `daily.precipitation_probability_max` existe déjà, on ne le recalcule pas).
 */
function fillMissingDailyAggregates(hourly, daily, dayCount) {
    daily = daily || {};
    if (!hourly) return daily;

    if (!daily.precipitation_probability_max && hourly.precipitation_probability) {
        daily.precipitation_probability_max = [];
        for (let i = 0; i < dayCount; i++) {
            daily.precipitation_probability_max.push(maxOfDay(hourly.precipitation_probability, i));
        }
    }
    if (!daily.uv_index_max && hourly.uv_index) {
        daily.uv_index_max = [];
        for (let i = 0; i < dayCount; i++) {
            daily.uv_index_max.push(maxOfDay(hourly.uv_index, i));
        }
    }
    if (!daily.cloud_cover_mean && hourly.cloud_cover) {
        daily.cloud_cover_mean = [];
        for (let i = 0; i < dayCount; i++) {
            daily.cloud_cover_mean.push(meanOfDay(hourly.cloud_cover, i));
        }
    }
    return daily;
}
