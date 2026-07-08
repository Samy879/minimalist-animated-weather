// SolarCalc.js
//
// MET Norway (Locationforecast) ne fournit pas d'heure de lever/coucher de
// soleil. Plutôt que d'afficher un fond jour/nuit invariable ou "--", on
// calcule ces heures via l'algorithme astronomique standard NOAA (le même
// type d'exception "calcul scientifique rigoureux" déjà autorisé pour la
// formule de Steadman). Ce n'est PAS une donnée inventée : c'est un calcul
// déterministe à partir de la position géographique et de la date, identique
// à celui utilisé par de nombreux services météo grand public.
//
// Référence : NOAA Solar Calculator / Astronomical Almanac.

function _toRad(d) { return d * Math.PI / 180; }
function _toDeg(r) { return r * 180 / Math.PI; }

/**
 * Retourne { sunrise: Date, sunset: Date } en UTC pour une date/lat/lon donnés.
 * Retourne null si le lieu est en nuit/jour polaire (pas de lever/coucher ce jour-là)
 * plutôt que d'inventer une heure.
 */
function getSunTimes(date, lat, lon) {
    let dayOfYear = Math.floor((date - new Date(date.getFullYear(), 0, 0)) / 86400000);

    let lngHour = lon / 15;

    function calc(isRising) {
        let t = dayOfYear + ((isRising ? 6 : 18) - lngHour) / 24;
        let M = (0.9856 * t) - 3.289;
        let L = M + (1.916 * Math.sin(_toRad(M))) + (0.020 * Math.sin(_toRad(2 * M))) + 282.634;
        L = (L + 360) % 360;

        let RA = _toDeg(Math.atan(0.91764 * Math.tan(_toRad(L))));
        RA = (RA + 360) % 360;
        let Lquadrant = (Math.floor(L / 90)) * 90;
        let RAquadrant = (Math.floor(RA / 90)) * 90;
        RA = RA + (Lquadrant - RAquadrant);
        RA = RA / 15;

        let sinDec = 0.39782 * Math.sin(_toRad(L));
        let cosDec = Math.cos(Math.asin(sinDec));

        let cosH = (Math.cos(_toRad(90.833)) - (sinDec * Math.sin(_toRad(lat)))) /
                   (cosDec * Math.cos(_toRad(lat)));

        if (cosH > 1 || cosH < -1) return null; // pas de lever/coucher ce jour (latitudes polaires)

        let H = isRising ? (360 - _toDeg(Math.acos(cosH))) : _toDeg(Math.acos(cosH));
        H = H / 15;

        let T = H + RA - (0.06571 * t) - 6.622;
        let UT = (T - lngHour + 24) % 24;
        return UT;
    }

    let riseUT = calc(true);
    let setUT = calc(false);
    if (riseUT === null || setUT === null) return null;

    function utToDate(ut) {
        let d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
        d.setUTCHours(Math.floor(ut), Math.round((ut % 1) * 60));
        return d;
    }

    return { sunrise: utToDate(riseUT), sunset: utToDate(setUT) };
}

/** Variante pratique : retourne directement deux chaînes ISO 8601 (ou null,null). */
function getSunTimesIso(date, lat, lon) {
    let t = getSunTimes(date, lat, lon);
    if (!t) return { sunrise: null, sunset: null };
    return { sunrise: t.sunrise.toISOString(), sunset: t.sunset.toISOString() };
}
