import QtQuick
import org.kde.plasma.plasmoid
import "../js/WeatherDescription.js" as WeatherDesc
import "../js/ProviderRegistry.js" as Registry
import "../js/DetailsCatalog.js" as Catalog
import "../js/GeoCoordinates.js" as GeoCoordinates
import "../js/GetCity.js" as GetCity

Item {
  id: root

  property var useCoordinatesIp: Plasmoid.configuration.useCoordinatesIp
  property string latitudeC: Plasmoid.configuration.latitudeC
  property string longitudeC: Plasmoid.configuration.longitudeC
  property string temperatureUnit: Plasmoid.configuration.temperatureUnit
  property int updateInterval: Plasmoid.configuration.updateInterval || 15

  property string weatherProvider: Plasmoid.configuration.weatherProvider || "openmeteo"
  property string apiKeyWeatherApi: Plasmoid.configuration.apiKeyWeatherApi || ""
  property string apiKeyTomorrow: Plasmoid.configuration.apiKeyTomorrow || ""
  property string apiKeyOpenWeatherMap: Plasmoid.configuration.apiKeyOpenWeatherMap || ""
  property string apiKeyVisualCrossing: Plasmoid.configuration.apiKeyVisualCrossing || ""
  property string apiKeyPirateWeather: Plasmoid.configuration.apiKeyPirateWeather || ""

  property int forecastStartDay: Plasmoid.configuration.forecastStartDay || 0
  property int forecastDayCount: Plasmoid.configuration.forecastDayCount || 7
  property int forecastDaysRequested: forecastStartDay + forecastDayCount

  property bool usedFallbackProvider: false
  property var lastProviderMeta: null

  property bool isBusy: false
  property bool componentReady: false

  property int refreshTrigger: Plasmoid.configuration.refreshTrigger
  onRefreshTriggerChanged: {
    console.log("--- [ACTION] Bouton Refresh appuyé (Trigger: " + refreshTrigger + ")");
    updateWeather();
  }

  property string apparentTemp: weatherData ? formatValue("apparentTemp") : "--"
  property string humidity: weatherData ? formatValue("humidity") : "--"
  property string uvIndex: weatherData ? formatValue("uvIndex") : "--"
  property string windSpeed: weatherData ? formatValue("windSpeed") : "--"
  property var weatherData: null
  property var coordsObj: null
  property string countryCode: coordsObj ? (coordsObj.countryCode || "") : ""

  property bool isAutoLoc: useCoordinatesIp === true || useCoordinatesIp === "true"
  property string latitude: isAutoLoc ? (coordsObj ? coordsObj.lat : "0") : latitudeC
  property string longitude: isAutoLoc ? (coordsObj ? coordsObj.lon : "0") : longitudeC
  property string languageCode: (Qt.locale().name).substring(0, 2)
  property string city: ""

  property int isDay: weatherData ? weatherData.current.is_day : 1
  readonly property string prefixIcon: isDay === 1 ? "" : "-night"
  property string currentTemperature: weatherData ? weatherData.current.temperature_2m.toFixed(1) : "--"
  property string currentTemperatureRounded: weatherData ? Math.round(weatherData.current.temperature_2m) : "--"
  property string weatherCode: weatherData ? weatherData.current.weather_code : 0
  property string iconWeatherCurrent: assignIcon(weatherCode, true)
  property string weatherLongText: WeatherDesc.weatherLongText(languageCode, weatherCode)
  property string weatherShortText: WeatherDesc.weatherShortText(languageCode, weatherCode)

  property string rainProbability: (weatherData && weatherData.daily && weatherData.daily.precipitation_probability_max && weatherData.daily.precipitation_probability_max.length > 0) ? weatherData.daily.precipitation_probability_max[0] : "0"
  property string textProbability: i18n("Rain probability")

  // --- NOTE SUR LES PRÉVISIONS JOUR PAR JOUR ---
  // Les anciennes propriétés à index fixe (maxweatherTomorrow, ..Day2, ..Day3)
  // ont été retirées : elles ignoraient forecastStartDay et lisaient parfois
  // un index hors des bornes réellement renvoyées par l'API (ex: seulement 3
  // jours demandés mais lecture de l'index 3 = 4e jour). Elles n'étaient de
  // toute façon plus utilisées par aucune vue : FullRepresentation.qml lit
  // désormais directement weatherData.daily[...][dayIndex], avec
  // dayIndex = index + forecastStartDay et un model borné par
  // (dailyData.time.length - forecastStartDay). C'est la seule source de
  // vérité pour l'affichage des jours de prévision — ne pas réintroduire de
  // raccourcis à index fixe ici.

  Timer {
    id: weatherTimer
    interval: Math.max(root.updateInterval, 5) * 60000
    running: true; repeat: true
    onTriggered: updateWeather()
  }

  Timer {
    id: retryTimer
    interval: 10000
    running: false; repeat: false
    onTriggered: updateWeather()
  }

  Timer {
    id: wakeUpDetector
    interval: 10000; running: true; repeat: true
    property var lastExecutionTime: new Date().getTime()
    onTriggered: {
      var currentTime = new Date().getTime();
      if (currentTime - lastExecutionTime > 30000) {
        console.log("--- [SYSTEM] Réveil du PC détecté");
        updateWeather();
      }
      lastExecutionTime = currentTime;
    }
  }

  Timer {
    id: safetyUnlockTimer
    interval: 30000
    running: false; repeat: false
    onTriggered: {
      if (root.isBusy) {
        console.log("--- [TIMEOUT] Pas de réponse réseau après 30s. Déblocage.");
        root.isBusy = false;
      }
    }
  }

  function detailValue(detailId) {
    if (!weatherData) return null;
    let v = Catalog.readCurrentValue(detailId, weatherData);
    if (v === null) v = Catalog.readTodayFallback(detailId, weatherData);
    return v;
  }

  function detailUnit(detailId) {
    let cat = Catalog.findDetail(detailId);
    return cat ? cat.unitFn(root.temperatureUnit) : "";
  }

  function detailSupported(detailId) {
    return Registry.isDetailSupported(weatherProvider, detailId);
  }

  function formatValue(detailId) {
    let v = detailValue(detailId);
    if (v === null || v === undefined || isNaN(v)) return "--";
    let cat = Catalog.findDetail(detailId);
    return (cat && cat.decimals) ? parseFloat(v).toFixed(1) : Math.round(v).toString();
  }

  function updateWeather() {
    if (isBusy) {
      console.log("--- [INFO] Mise à jour déjà en cours...");
      return;
    }
    isBusy = true;
    safetyUnlockTimer.start();
    retryTimer.stop();
    console.log("--- [1/4] Démarrage du cycle (Provider: " + weatherProvider + ", Auto-IP: " + isAutoLoc + ")");

    if (isAutoLoc || (latitude === "0" && longitude === "0")) {
      GeoCoordinates.getCoordinates(function(res) {
        if (res) {
          console.log("--- [2/4] Coordonnées récupérées : " + res.lat + ", " + res.lon);
          coordsObj = res;
          fetchData();
        } else {
          endSession(false, "Echec Géo-localisation");
        }
      });
    } else {
      console.log("--- [2/4] Utilisation des coordonnées manuelles : " + latitude + ", " + longitude);
      fetchData();
    }
  }

  function apiKeyForProvider(providerId) {
    if (providerId === "weatherapi") return apiKeyWeatherApi;
    if (providerId === "tomorrowio") return apiKeyTomorrow;
    if (providerId === "openweathermap") return apiKeyOpenWeatherMap;
    if (providerId === "visualcrossing") return apiKeyVisualCrossing;
    if (providerId === "pirateweather") return apiKeyPirateWeather;
    return "";
  }

  function fetchData() {
    console.log("--- [3/4] Requête Météo envoyée (provider: " + weatherProvider + ", jours: " + forecastDaysRequested + ")...");

    let params = {
      lat: latitude,
      lon: longitude,
      tempUnit: root.temperatureUnit,
      days: forecastDaysRequested,
      apiKey: apiKeyForProvider(weatherProvider),
      countryCode: root.countryCode,
      apiKeys: {
        weatherapi: apiKeyWeatherApi,
        tomorrowio: apiKeyTomorrow,
        openweathermap: apiKeyOpenWeatherMap,
        visualcrossing: apiKeyVisualCrossing,
        pirateweather: apiKeyPirateWeather
      }
    };

    Registry.fetchWeather(weatherProvider, params, function(err, data, meta, usedFallback) {
      usedFallbackProvider = usedFallback;
      lastProviderMeta = meta;

      if (data) {
        if (usedFallback) {
          console.log("--- [3/4] Fallback silencieux vers Open-Meteo (provider '" + weatherProvider + "' indisponible)");
        }
        console.log("--- [3/4] Données Météo reçues avec succès");
        weatherData = data;
        getCityName();
      } else {
        endSession(false, "Echec API Météo (" + err + ")");
      }
    });
  }

  function getCityName() {
    GetCity.getCityName(latitude, longitude, languageCode, function(res) {
      city = res;
      console.log("--- [4/4] Lieu détecté : " + city);
      endSession(true, "Succès");
    });
  }

  function endSession(success, message) {
    safetyUnlockTimer.stop();
    isBusy = false;
    if (success) {
      console.log("--- [FINAL] Cycle terminé avec succès !");
    } else {
      console.log("--- [ERREUR] Cycle interrompu : " + message);
      retryTimer.start();
    }
  }

  function assignIcon(code, precise) {
    let wmoCodes = {
      0: "clear", 1: "few-clouds", 2: "few-clouds", 3: "clouds",
      45: "fog", 48: "fog",
      51: "showers-scattered", 53: "showers-scattered", 55: "showers-scattered",
      56: "freezing-rain", 57: "freezing-rain",
      61: "showers", 63: "showers", 65: "showers",
      66: "freezing-rain", 67: "freezing-rain",
      71: "snow", 73: "snow", 75: "snow",
      77: "snow",
      80: "showers", 81: "showers", 82: "showers",
      85: "snow-scattered", 86: "snow-scattered",
      95: "storm", 96: "storm", 99: "storm"
    };
    let icon = "weather-" + (wmoCodes[code] || "clouds");
    return (precise === true) ? icon + prefixIcon : icon;
  }

  Component.onCompleted: {
    updateWeather();
    componentReady = true;
  }

  onTemperatureUnitChanged: if (componentReady) updateWeather()
  onUseCoordinatesIpChanged: if (componentReady) updateWeather()
  onLatitudeCChanged: if (componentReady && !isAutoLoc) updateWeather()
  onLongitudeCChanged: if (componentReady && !isAutoLoc) updateWeather()
  onWeatherProviderChanged: if (componentReady) updateWeather()
  onApiKeyWeatherApiChanged: if (componentReady && weatherProvider === "weatherapi") updateWeather()
  onApiKeyTomorrowChanged: if (componentReady && weatherProvider === "tomorrowio") updateWeather()
  onApiKeyOpenWeatherMapChanged: if (componentReady && weatherProvider === "openweathermap") updateWeather()
  onApiKeyVisualCrossingChanged: if (componentReady && weatherProvider === "visualcrossing") updateWeather()
  onApiKeyPirateWeatherChanged: if (componentReady && weatherProvider === "pirateweather") updateWeather()
  onForecastStartDayChanged: if (componentReady) updateWeather()
  onForecastDayCountChanged: if (componentReady) updateWeather()
}
