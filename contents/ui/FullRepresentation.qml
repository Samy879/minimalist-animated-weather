import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import "components" as Components
import "js/DetailsCatalog.js" as Catalog
import "js/UnitConverter.js" as UnitConverter
import org.kde.kirigami as Kirigami

Item {
    id: rootItem

    property var weatherData
    property int temperatureUnit: root.temperatureUnit
    property int windSpeedUnit: root.windSpeedUnit

    // 0 = gauche, 1 = milieu, 2 = droite.
    // Réglable dans Apparence > Vue étendue, s'applique aussi bien en mode panneau qu'en mode bureau
    // (voir conditionLabel dans le header).
    readonly property int conditionAlignment: Plasmoid.configuration.conditionAlignment

    // Taille de la zone de survol/clic des colonnes de prévision (déclenche le cercle bleuté + ouvre le détail horaire) :
    // 0 = Large (toute la colonne, comportement historique), 1 = Moyen (rectangle jour+icône+min/max, sans le surplus de hauteur), 2 = Petit (icône seule).
    readonly property int forecastHoverZoneSize: Plasmoid.configuration.forecastHoverZoneSize

    readonly property string unitStr: UnitConverter.temperatureUnitLabel(temperatureUnit)
    readonly property string currentTempText: (weatherData && weatherData.currentTemperatureRounded) ? weatherData.currentTemperatureRounded : "--"

    // Parse une liste d'identifiants stockée en JSON dans la config ; retourne [] si absente/invalide.
    function parseIdList(jsonString) {
        try {
            let parsed = JSON.parse(jsonString || "[]");
            return Array.isArray(parsed) ? parsed : [];
        } catch (e) {
            return [];
        }
    }

    readonly property var detailsOrderIds: parseIdList(Plasmoid.configuration.detailsOrder)
    // Lit l'ordre des graphiques de manière indépendante
    readonly property var chartsOrderIds: parseIdList(Plasmoid.configuration.chartsOrder)

    // Source unique de vérité : DetailsCatalog.js (partagée avec ConfigData.qml::detailsMaxCount).
    // Sécurité indépendante : même si le clamp côté page de config n'a pas (encore) réécrit cfg_detailsOrder
    // (ex. désactivation de Condition sans réouvrir la page Data, config modifiée manuellement, etc.),
    // la vue compacte n'affichera jamais plus de ce nombre d'éléments.
    readonly property int compactDetailsMaxCount: Catalog.getCompactDetailsMaxCount()

    readonly property bool anyDetailEnabled: detailsOrderIds.length > 0
    // Si la personne a tout décoché, cette propriété est fausse et bloque les clics
    readonly property bool anyChartEnabled: chartsOrderIds.length > 0

    readonly property bool showBottomDetails: !!(anyDetailEnabled && root.showConditionExpanded)

    property int selectedDayIndex: -1
    property int activeChart: 0

    readonly property var hourlyData: (weatherData && weatherData.weatherData && weatherData.weatherData.hourly) ? weatherData.weatherData.hourly : null
    readonly property bool hasHourlyData: !!hourlyData
    readonly property var dailyData: (weatherData && weatherData.weatherData && weatherData.weatherData.daily) ? weatherData.weatherData.daily : null

    readonly property int currentDayIndex: {
        if (!dailyData) return 0;
        let today = new Date();
        let todayStr = today.getFullYear() + "-" +
        String(today.getMonth() + 1).padStart(2, "0") + "-" +
        String(today.getDate()).padStart(2, "0");
        let times = dailyData.time;
        for (let i = 0; i < times.length; i++) {
            if (times[i] === todayStr) return i;
        }
        return 0;
    }

    // Liste de paires [idPrincipal, idSecondaire] configurées dans Data & Charts.
    // idSecondaire est toujours celui tracé en pointillé sur l'axe Y de droite ;
    // n'importe quelles 2 courbes du catalogue peuvent être choisies (voir
    // ConfigData.qml). Remplace l'ancien réglage figé "combineRainChart".
    readonly property var combinedChartsIds: parseIdList(Plasmoid.configuration.combinedCharts)

    // La température (et le ressenti) et la vitesse du vent ont chacune leur propre
    // unité configurée indépendamment (Appearance > Source > Temperature / Wind
    // speed) : ce helper choisit laquelle des deux passer à unitFn() selon le type
    // de courbe, pour ne jamais confondre les deux (ex: afficher "km/h" avec la
    // valeur de temperatureUnit par erreur).
    function unitValueForCat(cat) {
        return cat.id === "windSpeed" ? windSpeedUnit : temperatureUnit;
    }

    // Génération simplifiée et propre des courbes
    readonly property var chartDefs: {
        let defs = [];

        // N'accepte une paire que si : elle est bien formée, les deux courbes sont
        // sélectionnées dans Chart Tabs, et aucune des deux n'est déjà engagée dans
        // une autre paire retenue plus haut dans la liste (une courbe ne peut faire
        // partie que d'une seule fusion active à la fois ; la première paire valide
        // gagne, dans l'ordre où l'utilisateur les a configurées).
        let roleForId = {}; // id -> { partnerId, role: "primary" | "secondary" }
        for (let p = 0; p < combinedChartsIds.length; p++) {
            let pair = combinedChartsIds[p];
            if (!Array.isArray(pair) || pair.length !== 2) continue;
            let primaryId = pair[0], secondaryId = pair[1];
            if (!primaryId || !secondaryId || primaryId === secondaryId) continue;
            if (chartsOrderIds.indexOf(primaryId) === -1 || chartsOrderIds.indexOf(secondaryId) === -1) continue;
            if (roleForId[primaryId] || roleForId[secondaryId]) continue;
            roleForId[primaryId] = { partnerId: secondaryId, role: "primary" };
            roleForId[secondaryId] = { partnerId: primaryId, role: "secondary" };
        }

        // La position de l'onglet fusionné dans la liste suit celle de la première
        // des deux courbes (principale ou secondaire) rencontrée dans chartsOrderIds ;
        // handledPairs évite de la générer une seconde fois quand on croise l'autre membre.
        let handledPairs = {};

        for (let i = 0; i < chartsOrderIds.length; i++) {
            let id = chartsOrderIds[i];
            let roleInfo = roleForId[id];

            if (roleInfo) {
                let primaryId = roleInfo.role === "primary" ? id : roleInfo.partnerId;
                let secondaryId = roleInfo.role === "primary" ? roleInfo.partnerId : id;
                let pairKey = primaryId + "|" + secondaryId;
                if (handledPairs[pairKey]) continue;
                handledPairs[pairKey] = true;

                let primaryCat = Catalog.findDetail(primaryId);
                let secondaryCat = Catalog.findDetail(secondaryId);
                if (primaryCat && secondaryCat && hourlyData &&
                    hourlyData[primaryCat.hourlyField] && hourlyData[secondaryCat.hourlyField]) {
                    defs.push({
                        field: primaryCat.hourlyField,
                        label: primaryCat.labelKey,
                        tabLabel: primaryCat.tabLabelKey,
                        unit: primaryCat.unitFn(rootItem.unitValueForCat(primaryCat)),
                              color: primaryCat.color,
                              chartType: primaryCat.chartType,
                              secondaryField: secondaryCat.hourlyField,
                              secondaryLabel: secondaryCat.labelKey,
                              secondaryUnit: secondaryCat.unitFn(rootItem.unitValueForCat(secondaryCat)),
                              secondaryColor: secondaryCat.color,
                              secondaryDecimals: !!secondaryCat.decimals,
                              secondaryChartType: secondaryCat.chartType
                    });
                    continue;
                    }
                    // Données manquantes pour l'une des deux courbes de la paire : on
                    // retombe sur l'affichage simple de la courbe courante ci-dessous
                    // plutôt que de perdre l'onglet entièrement.
            }

            let cat = Catalog.findDetail(id);
            if (!cat) continue;
            let targetField = cat.hourlyField;
            if (!hourlyData || !hourlyData[targetField]) continue;
            defs.push({
                field: targetField,
                label: cat.labelKey,
                tabLabel: cat.tabLabelKey,
                unit: cat.unitFn(rootItem.unitValueForCat(cat)),
                      color: cat.color,
                      chartType: cat.chartType
            });
        }
        return defs;
    }

    function hourlySlice(fieldName) {
        if (!hourlyData || !hourlyData[fieldName] || selectedDayIndex < 0) return [];
        let start = selectedDayIndex * 24;
        return hourlyData[fieldName].slice(start, start + 24);
    }

    // Construit une liste { label, value } formatée à partir d'IDs de détails (Catalog).
    // Utilisée à la fois pour les stats compactes du header et la rangée de détails du bas.
    function buildDetailEntries(ids, labelField) {
        let arr = [];
        for (let i = 0; i < ids.length; i++) {
            let cat = Catalog.findDetail(ids[i]);
            if (!cat || !weatherData) continue;
            let raw = weatherData.detailValue(ids[i]);
            // Formatage centralisé dans DetailsCatalog.js (cat.textDetailDecimals),
            // partagé avec WeatherData.qml::formatValue() : voir ce fichier pour le
            // contexte complet. cat.decimals ne pilote lui que la précision du
            // graphique (secondaryDecimals ci-dessous, dans chartDefs).
            let formatted = Catalog.formatTextDetailValue(ids[i], raw);
            if (formatted === null) continue;
            arr.push({
                label: cat[labelField],
                value: formatted + weatherData.detailUnit(ids[i])
            });
        }
        return arr;
    }

    function openDayDetail(dayIndex) {
        if (hasHourlyData && anyChartEnabled) {
            activeChart = 0;
            selectedDayIndex = dayIndex;
        }
    }

    function closeDayDetail() {
        selectedDayIndex = -1;
    }

    function resetScroll() {
        if (forecastSection.positionViewAtBeginning) forecastSection.positionViewAtBeginning();
        closeDayDetail();
    }

    // Largeur "confortable" d'une colonne jour (icône + jour + min/max), sous laquelle on
    // préfère afficher moins de colonnes plutôt que de les rétrécir. Valeur reprise du réglage
    // historique (avant l'existence de "Visible at once") où 3 colonnes tenaient confortablement
    // dans fixedWidth (15 gridUnit / 3 = 5) : c'est ce ratio, éprouvé visuellement, qui sert
    // maintenant de référence pour TOUT calcul (auto ET manuel), au lieu d'une division
    // fixedWidth / visibleDayCount déconnectée de la largeur réellement disponible.
    readonly property real idealDayColumnWidth: Kirigami.Units.gridUnit * 5

    // Valeur brute de la config : 0 = Auto (voir main.xml). > 0 = maximum fixé par l'utilisateur.
    readonly property int configuredVisibleDayCount: Plasmoid.configuration.forecastVisibleDayCount

    // Mode Auto : dérive le nombre de colonnes "idéal" de la largeur que le widget a de toute
    // façon déjà besoin d'occuper (fixedWidth, ou plus si les Text Details du bas en demandent
    // plus) — sans quoi une sélection de 4 détails donnait justement "4 icônes" par coïncidence
    // de valeurs plutôt que par calcul. Se recalcule à chaque changement de détails sélectionnés
    // ou de largeur, tant que l'utilisateur n'a pas fixé un nombre précis.
    // Largeur de référence pour le calcul Auto ci-dessous. Les deux modes ont une causalité
    // opposée entre "width" et "contenu" :
    // - Popup/panneau : le widget se dimensionne LUI-MÊME à partir du contenu (voir
    //   contentWidth et "width" plus bas) ; utiliser rootItem.width ici créerait donc une
    //   dépendance circulaire (width ← contentWidth ← autoVisibleDayCount ← width...).
    //   On garde fixedWidth, une largeur de repos indépendante du contenu.
    // - Bureau : c'est l'inverse, la largeur est imposée de l'extérieur par l'utilisateur
    //   (poignées de redimensionnement, voir "width" plus bas = parent.width) : c'est donc
    //   elle, la vraie grandeur qui doit piloter le nombre de colonnes auto.
    readonly property real autoCalcReferenceWidth: isDesktopMode ? width : fixedWidth

    readonly property int autoVisibleDayCount: Math.max(1,
                                                        Math.floor(Math.max(autoCalcReferenceWidth, detailsRequiredWidth) / idealDayColumnWidth))

    // Nombre de colonnes visées : la valeur choisie par l'utilisateur si elle existe (traitée
    // comme un MAXIMUM, jamais dépassé — voir visibleCols), sinon la valeur Auto ci-dessus.
    readonly property int effectiveVisibleDayCount: configuredVisibleDayCount > 0 ? configuredVisibleDayCount : autoVisibleDayCount

    // Nombre de jours disponibles dans les données (respecte forecastStartDay)
    readonly property int availableDayCount: (dailyData && dailyData.time) ? Math.max(0, dailyData.time.length - root.forecastStartDay) : 0

    // Vrai uniquement quand le widget est posé directement sur le bureau (mode "Bureau").
    // Dans la popup du panneau, on garde une taille fixe.
    readonly property bool isDesktopMode: Plasmoid.formFactor === PlasmaCore.Types.Planar

    // Détection thème clair/sombre indépendante du nom de thème : calcule la luminance perçue de la couleur de fond de Kirigami.
    // Plus fiable que de se fier à une éventuelle propriété "darkMode" qui n'existe pas dans toutes les versions de Kirigami.
    readonly property real backgroundLuminance: {
        let c = Kirigami.Theme.backgroundColor;
        return 0.299 * c.r + 0.587 * c.g + 0.114 * c.b;
    }
    readonly property bool isDarkTheme: backgroundLuminance < 0.5

    readonly property int fixedWidth: Kirigami.Units.gridUnit * 15

    // En mode panneau, Plasma ajoute une marge de compositing invisible autour du popup, ce qui
    // fait que les animations (Sun/Cloud/Rain/etc.) semblent coupées avant les vrais bords si le
    // fond n'est pas étendu d'autant. Uniquement en mode panneau : en mode bureau le fond touche
    // déjà parfaitement les bords sans elle, et l'étirer produirait l'effet inverse.
    //
    // NOTE : idéalement cette valeur devrait être lue dynamiquement depuis le thème Plasma actif
    // (PlasmaCore.FrameSvgItem sur "dialogs/background" → margins.left/top/right/bottom), mais ce
    // type ne se résout pas dans tous les environnements Plasma 6 (dépend de la version exacte de
    // plasma-framework/qmldir installée). On garde donc une constante nommée, à ajuster ici si le
    // rendu bave visiblement sur un thème avec une ombre de popup plus large/étroite que Breeze.
    readonly property real popupBleedMargin: 8

    readonly property bool needsBackgroundBleed: Plasmoid.configuration.showAnimations && !isDesktopMode

    // En mode bureau, comme on n'étend plus le fond, celui-ci touche exactement les bords du
    // widget. Pour ne pas donner une impression de contenu "collé", on décale légèrement le
    // contenu (header, prévisions, détails, vue jour) vers l'intérieur — de la même quantité que
    // le bleed ci-dessus, pour rester visuellement cohérent entre les deux modes.
    readonly property real desktopContentInset: (isDesktopMode && Plasmoid.configuration.showAnimations) ? popupBleedMargin : 0

    // Choix esthétique (pas une compensation technique) : léger surplus d'espacement vertical
    // en mode Bureau, pour que le header et la liste des prévisions "respirent" symétriquement
    // en haut et en bas. Ajuster cette seule valeur si l'équilibre visuel doit changer.
    readonly property real desktopVerticalBreathing: 1.4

    // Espacement du header (température/condition) en mode Bureau, volontairement distinct
    // de desktopVerticalBreathing ci-dessus (qui reste partagé entre forecastSection et
    // detailsRow, en bas) : le haut paraissait trop aéré par rapport au bas. Ajuster cette
    // seule valeur si l'espace au-dessus de la température doit encore changer (0 = collé
    // au bord, en plus de desktopContentInset).
    readonly property real desktopHeaderTopBreathing: 0.5

    // OBSOLÈTE — laissé à 0. Cette propriété servait à une ancienne tentative de
    // corriger le centrage de la liste des jours en tirant forecastSection vers le
    // haut via une marge négative sur headerSection.bottomMargin. Ce mécanisme a été
    // abandonné au profit de forecastCenterOffset (décalage direct du contenu, sans
    // dépendre des marges — voir plus bas dans le fichier), qui fonctionne aussi bien
    // en Bureau qu'en Popup. Mais la valeur (montée à 1.8 gridUnit au fil des essais)
    // n'avait jamais été redescendue : combinée à headerSection.Layout.minimumHeight
    // (ajouté plus tard pour empêcher le header d'être compressé), cette marge très
    // négative faisait démarrer la boîte de forecastSection PAR-DESSUS le texte du
    // header ("29°C" chevauché par "Sam.") dès que le contenu ne laissait plus de
    // marge de manœuvre pour l'absorber. Remise à 0 : plus aucune raison de tirer le
    // header vers forecastSection, tout le travail de centrage se fait maintenant via
    // forecastCenterOffset.
    readonly property real desktopHeaderBottomTrim: 0

    // Padding de base non négociable entre le header et la liste des jours en mode
    // Bureau (voir forecastSection.Layout.topMargin plus bas dans le fichier). Contrairement
    // aux autres réglages de cette zone (desktopHeaderBottomTrim, forecastCenterOffset...),
    // celui-ci ne sert PAS à peaufiner le centrage : c'est un filet de sécurité fixe,
    // toujours ajouté en plus, pour qu'un chevauchement comme celui observé (header et
    // "Sam." qui se touchent quand la hauteur du widget varie) ne puisse plus se reproduire
    // même si un futur réglage des marges se trompe de signe.
    readonly property real desktopHeaderSafetyPadding: Kirigami.Units.gridUnit * 0.1

    // Levier DIRECT pour remonter la liste des jours (1 seule rangée visible), en
    // Popup COMME en Bureau. Contrairement à une marge externe (popupHeaderBottomTrim,
    // desktopHeaderBottomTrim...) qui agit AVANT une boîte dont le contenu est ensuite
    // recentré (effet dilué, voire nul si la boîte a une hauteur fixe comme en Popup),
    // celui-ci déplace directement le point de centrage du contenu (dayLabel + icône +
    // min/max) dans sa cellule, quel que soit le mode : 1 gridUnit ici = 1 gridUnit de
    // déplacement visuel réel. Positif = vers le haut.
    // (Corrige une confusion précédente : cette valeur n'était appliquée qu'en mode
    // Bureau (isDesktopMode), alors que le rendu réel observé était en mode Popup —
    // d'où l'absence totale d'effet malgré des valeurs multipliées par 3.)
    readonly property real forecastCenterOffset: Kirigami.Units.gridUnit * 0.3

    // Petit décalage vers le bas du contenu de detailsRow (label + valeur), actuellement
    // Qt.AlignVCenter pile au milieu de sa boîte fixe (gridUnit * 2.2). Appliqué comme
    // Layout.topMargin sur le delegate : ça mange un peu de l'espace libre au-dessus
    // sans recoller au fond de la boîte comme le ferait Qt.AlignBottom (essayé et jugé
    // trop bas, voir la note existante juste au-dessus du Repeater de detailsRow).
    readonly property real detailsRowVerticalNudge: Kirigami.Units.smallSpacing * 0.6

    // === Système de marges/espacements du mode Popup/Panneau ===
    // Avant : chaque section (headerSection, forecastSection, detailsRow) avait sa
    // propre marge ajustée séparément à l'oeil (parfois négative), sans lien entre
    // elles. Résultat : la liste des jours n'était pas équidistante entre le header
    // et les text details, la marge du bord haut (→ température) ne correspondait
    // pas à celle du bord bas (→ text detail), et les marges latérales différaient
    // entre le header (1 gridUnit) et detailsRow (0.5 gridUnit).
    // Ce bloc centralise ces 3 valeurs pour que la symétrie soit garantie PAR
    // CONSTRUCTION (mêmes constantes réutilisées des deux côtés) plutôt que par un
    // réglage manuel de chaque marge à faire correspondre par coïncidence.

    // Marge latérale unique (gauche/droite), partagée par headerSection et detailsRow.
    // Mesure sur rendu réel : avec 0.65, le centre des chiffres "25" tombait ~11px à
    // gauche du centre de "Jeu." (juste après avoir corrigé l'inverse : "25°C" complet
    // trop à droite). Ajustement à 0.8 pour se rapprocher du milieu, sans retomber dans
    // le travers d'un couplage dynamique fragile à forecastSection. Légèrement resserrée
    // à 0.75 ensuite (demande esthétique) : réduction volontairement petite (0.05) pour
    // ne pas trop redécaler "25" vers la gauche et reperdre l'alignement gagné ci-dessus.
    readonly property real popupSideMargin: Kirigami.Units.gridUnit * 0.85

    // NOTE : une tentative précédente centrait ici "28" (les chiffres seuls, sans °C)
    // au-dessus de la première colonne de prévision ("Jeu."), via un calcul dynamique
    // basé sur forecastSection.width/visibleCols. Mesuré sur rendu réel, ça fonctionnait
    // (1px d'écart) — mais UNIQUEMENT pour les chiffres seuls. Le "°C", qui suit sans
    // rien pour le contrebalancer à gauche, tirait le centre visuel du bloc "28°C" complet
    // ~20px à droite du centre de "Jeu.", recréant le même défaut d'équilibre visuel que
    // ce correctif était censé résoudre. Coupler une ligne d'info (le résumé actuel) à la
    // géométrie d'une autre ligne sans rapport structurel (la liste de prévisions) était
    // fragile et donnait, une fois le rendu observé dans son ensemble, un résultat
    // "presque aligné mais tiré à droite" plus dérangeant qu'un alignement volontairement
    // simple. Retour à un calage à gauche classique avec popupSideMargin (même marge que
    // detailsRow), comme la plupart des widgets météo bien conçus — sans dépendance à la
    // largeur ou au nombre de colonnes de forecastSection.

    // === Marges verticales du popup : valeurs FIXES et symétriques, sans compensation ===
    // ANCIEN SYSTÈME (retiré) : chaque marge valait Math.max(smallSpacing, base - compensation),
    // où "compensation" venait de la demi-différence de FontMetrics.height entre deux polices
    // (ex: le header en gridUnit*2.5 vs "Mer." en gridUnit*0.65). Problème : cette compensation
    // (~20-22px) était 5 à 10x plus grande que "base" (~2-4px), donc Math.max retombait TOUJOURS
    // sur le plancher smallSpacing pour headerSection.topMargin et forecastSection.topMargin —
    // tout le calcul de compensation ne s'exécutait jamais pour ces deux jonctions. Pire :
    // forecastSection.topMargin et .bottomMargin comparaient deux PAIRES de polices différentes,
    // donc n'étaient pas égales par construction même sans le plancher, contrairement à ce que
    // prétendaient les commentaires précédents.
    //
    // NOTE IMPORTANTE (cause dominante, distincte de ce fichier de valeurs) : forecastSection est
    // une ListView à Layout.preferredHeight FIXE (gridUnit * 6.0), et son delegate centre
    // verticalement contentColumn dans chaque cellule (anchors.verticalCenter). Avec une seule
    // rangée visible, ce centrage ajoute ~15-20px de vide symétrique au-dessus ET en dessous de
    // "Mer./Jeu./Ven.", INDÉPENDAMMENT des marges ci-dessous. C'est ce qui donnait l'essentiel de
    // l'écart visuel observé, pas les quelques px de marge. En rendant topMargin == bottomMargin
    // ci-dessous (au lieu de deux formules différentes), ce padding interne déjà symétrique n'est
    // plus déséquilibré par des marges externes inégales.

    // Marge entre le bord du popup et le premier/dernier contenu visible :
    // bord haut → température (headerSection.topMargin) ET bord bas → text detail
    // (detailsRow.bottomMargin). Les deux usages ci-dessous réutilisent CETTE MÊME
    // valeur : ne jamais les régler indépendamment, sous peine de perdre la symétrie.
    // Volontairement resserrée (0.3, pas 0.5) : à 0.5 le total ajouté à la hauteur du
    // popup (2x cette valeur, haut + bas) rendait le widget visiblement plus haut, et le
    // rendu mesuré donnait un bord haut trop aéré par rapport au reste. Encore réduite
    // à 0.25 sur demande (léger resserrement supplémentaire, haut et bas égaux car les
    // deux marges partagent cette même base : toute variation ici se répercute à
    // l'identique des deux côtés).
    readonly property real popupEdgeMargin: Kirigami.Units.gridUnit * 0.4

    // Mesure sur rendu réel : même avec popupEdgeMargin strictement identique des deux
    // côtés (headerSection.topMargin == detailsRow.bottomMargin), le bord haut mesurait
    // ~34px et le bord bas ~29px — le même phénomène ascent/descent que
    // popupHeaderBottomTrim plus bas : la boîte du header (police énorme) réserve aussi
    // un peu plus d'espace invisible AU-DESSUS de son texte que detailsRow n'en réserve
    // en dessous du sien. Petite valeur fixe, mesurée, retranchée uniquement du haut.
    // ATTENTION : popupEdgeMargin vaut maintenant exactement la même chose que ce trim
    // (0.25 chacun), donc headerSection.topMargin est déjà à son plancher (0, via
    // Math.max). Réduire encore popupEdgeMargin ne réduira PLUS le bord haut (qui restera
    // bloqué à 0) alors que le bord bas continuera de rétrécir — pour resserrer encore les
    // deux à l'identique, réduire aussi popupHeaderTopTrim en parallèle, du même montant.
    readonly property real popupHeaderTopTrim: Kirigami.Units.gridUnit * 0.3

    // Espace entre le header et la liste des jours (forecastSection.topMargin) ET
    // entre la liste des jours et les text details (forecastSection.bottomMargin) :
    // même valeur de base des deux côtés, appliquée directement (aucune compensation
    // soustraite) → égalité garantie par construction, pas par coïncidence.
    readonly property real popupSectionGap: Kirigami.Units.gridUnit * 0.35

    // Mesure sur rendu réel (2 captures successives, comparaison pixel des 4 jonctions) :
    // même avec popupSectionGap strictement identique des deux côtés de forecastSection,
    // le bas de headerSection (RowLayout dimensionné par la police énorme du "29°C",
    // gridUnit * 2.5) réserve environ 20px d'espace invisible EN PLUS sous son texte,
    // par rapport à l'espace que detailsRow réserve au-dessus du sien (police minuscule,
    // gridUnit * 0.52-0.72). Une v1 de ce correctif retranchait cette valeur de
    // forecastSection.topMargin, mais Math.max(0, ...) la plafonnait à 0 dès que
    // popupSectionGap (~6-7px) était dépassé — largement insuffisant face à un écart
    // de ~20px. La correction doit donc porter sur l'endroit où l'espace en trop existe
    // RÉELLEMENT : le bas de headerSection lui-même (jamais touché jusqu'ici, toujours à
    // 0 par défaut), pas sur la marge du voisin qui n'a pas la place de compenser.
    // Cette marge est purement interne (~50px de respiration de chaque côté, contre
    // seulement quelques px pour popupEdgeMargin en haut/bas du popup) : une petite
    // valeur négative ici ne présente donc aucun risque de rognage contre le bord réel
    // du popup, contrairement à l'ancien bug sur headerSection.topMargin.
    // Mesure sur rendu réel (capture, comparaison pixel des 2 jonctions autour de
    // forecastSection) : même avec popupHeaderBottomTrim == popupForecastBottomTrim
    // (symétrie théorique des marges), le gap header→liste mesurait 35px contre 42px
    // pour liste→détails — la liste n'était pas exactement centrée. Cause : les
    // métriques de police (ascent/descent) du header ("Partiellement nuageux", gros
    // texte, parfois 2 lignes) diffèrent de celles des valeurs de détail, donc l'égalité
    // des MARGES ne garantit pas l'égalité du rendu VISUEL. Réduite ici (0.4 → 0.25) et
    // popupForecastBottomTrim augmentée d'autant (0.4 → 0.55, voir plus bas) : un
    // ajustement à SOMME NULLE (l'espace gagné d'un côté est retiré de l'autre), pour ne
    // pas changer la hauteur totale du popup tout en rééquilibrant visuellement les deux
    // jonctions autour de la liste de jours. Valeurs choisies pour que
    // forecastSection.bottomMargin (voir popupForecastBottomTrim) tombe EXACTEMENT sur
    // son plancher Math.max(0, ...) plutôt que juste en dessous — sinon le plancher
    // absorbe silencieusement une partie de l'ajustement prévu et casse la somme nulle.
    readonly property real popupHeaderBottomTrim: Kirigami.Units.gridUnit * 0.25

    // Même logique que popupHeaderBottomTrim ci-dessus, mais côté bas : sans ce trim,
    // "liste des jours → text details" (forecastSection.bottomMargin, popupSectionGap
    // pur, sans compensation) reste visuellement plus grand que "header → liste des
    // jours" (déjà resserré par popupHeaderBottomTrim ci-dessus). Retranché uniquement
    // du bas de forecastSection (pas de detailsRow.topMargin, qui n'existe pas et n'a
    // pas besoin d'exister) pour rester cohérent avec le principe "on corrige à
    // l'endroit où l'espace en trop existe réellement". Ajuster cette seule valeur
    // pour affiner l'écart si besoin (l'augmenter resserre encore, la mettre à 0
    // revient à l'ancien comportement).
    // Unifiée avec popupHeaderBottomTrim (voir plus haut) : avant cet ajustement, le
    // "budget" de marge externe restant après soustraction du trim était différent des
    // deux côtés de forecastSection (0.55-0.4=0.15 côté header, 0.55-0.1=0.45 côté
    // detailsRow) — un écart de 0.3 gridUnit à lui seul, avant même de compter le
    // décalage interne (alignement du contenu dans les boîtes à hauteur fixe). Même
    // valeur des deux côtés maintenant → écart de marge EXTERNE nul entre les deux
    // jonctions, le reste de l'ajustement se fait via l'alignement interne du contenu.
    // Voir la note sur popupHeaderBottomTrim plus haut : ajustement à somme nulle avec
    // cette valeur (0.4 → 0.55), mesuré sur rendu réel pour corriger l'asymétrie visuelle
    // observée entre les deux jonctions de forecastSection, sans changer la hauteur
    // totale. Choisie égale à popupSectionGap (0.55) : forecastSection.bottomMargin
    // (popupSectionGap - popupForecastBottomTrim) tombe alors exactement à 0, une valeur
    // propre et prévisible plutôt que de dépendre du plancher Math.max(0, ...) pour
    // rattraper une valeur négative non voulue.
    readonly property real popupForecastBottomTrim: Kirigami.Units.gridUnit * 0.55

    // === Alignement vertical des flèches de scroll (leftScrollHint/rightScrollHint) ===
    // Les flèches doivent tomber sur le centre RÉEL de l'icône météo, pas sur le centre
    // géométrique de contentColumn (dayLabel + icône + min/max empilés) : comme dayLabel
    // (gridUnit * 0.65) et tempRow (gridUnit * 0.75, gras) n'ont pas la même hauteur de police,
    // ces deux centres ne coïncident pas. Mesuré via FontMetrics plutôt que deviné à l'oeil
    // (pixel fixe), pour rester juste quel que soit le scaling de police/DPI de l'utilisateur.
    // Dérivation : le centre de l'icône est à dayLabel.height + iconWrapper.height/2 depuis le
    // haut de contentColumn ; le centre géométrique de la boîte est à contentColumn.height/2 =
    // (dayLabel.height + iconWrapper.height + tempRow.height)/2 ; la différence se simplifie en
    // (dayLabel.height - tempRow.height)/2, le terme iconWrapper.height s'annulant.
    FontMetrics {
        id: dayLabelFontMetrics
        font.family: Kirigami.Theme.defaultFont.family
        font.pixelSize: Kirigami.Units.gridUnit * 0.65
    }
    FontMetrics {
        id: forecastTempRowFontMetrics
        font.family: Kirigami.Theme.defaultFont.family
        font.pixelSize: Kirigami.Units.gridUnit * 0.75
        font.bold: true
    }
    readonly property real forecastArrowIconOffset: (dayLabelFontMetrics.height - forecastTempRowFontMetrics.height) / 2
    - (isDesktopMode ? 0 : Kirigami.Units.smallSpacing * 1.36)

    // NOTE : l'ancien système de "compensation par FontMetrics" (qui retranchait la
    // demi-différence de hauteur de police entre deux polices à chaque jonction) a été retiré.
    // En pratique, la compensation (~20-22px, dérivée de l'énorme police du header) dépassait
    // toujours largement la marge de base (~2-4px), donc Math.max(smallSpacing, ...) retombait
    // systématiquement sur son plancher : tout ce calcul ne servait à rien pour headerSection.
    // topMargin et forecastSection.topMargin, et donnait un résultat différent (pas symétrique
    // par construction, contrairement à ce qu'affirmaient les anciens commentaires) pour
    // forecastSection.bottomMargin. Voir popupEdgeMargin / popupSectionGap ci-dessus : les
    // marges verticales du popup sont maintenant des constantes fixes appliquées identiquement
    // des deux côtés de chaque jonction, sans aucune compensation.

    // Largeur minimale d'une colonne de détail pour que le libellé et la valeur ne se chevauchent jamais (ex: "Wind Speed" / "12 km/h").
    // Légèrement resserrée (3.2 -> 3.0) pour réduire un peu la largeur du panneau : avec 4
    // colonnes de détails affichées (cas le plus courant), c'est cette valeur qui dimensionne
    // réellement le popup via detailsRequiredWidth, pas fixedWidth. Reste suffisant pour que
    // le libellé le plus long ("Feels Like") et sa valeur ne se chevauchent jamais.
    readonly property real detailMinColumnWidth: Kirigami.Units.gridUnit * 3.2
    readonly property int detailsCount: (showBottomDetails && detailsRow.visibleDetails) ? detailsRow.visibleDetails.length : 0
    readonly property real detailsRequiredWidth: detailsCount > 0 ? (detailsCount * detailMinColumnWidth) + Kirigami.Units.gridUnit + (detailsCount * Kirigami.Units.smallSpacing * 2) : 0

    // Largeur nécessaire pour afficher effectiveVisibleDayCount colonnes sans les rétrécir
    // sous idealDayColumnWidth. Utile UNIQUEMENT en popup/panneau (voir contentWidth) : c'est
    // ce qui permet au popup de s'agrandir lui-même pour accueillir le nombre de colonnes
    // choisi (voir "width" plus bas, qui vaut contentWidth dans ce mode).
    readonly property real forecastRequiredWidth: effectiveVisibleDayCount * idealDayColumnWidth

    // Largeur réelle du contenu, et plancher de redimensionnement (Layout.minimumWidth
    // ci-dessous, valable aussi en mode bureau). En popup/panneau, grandit avec
    // forecastRequiredWidth pour que le popup s'auto-dimensionne au nombre de colonnes
    // demandé. En BUREAU, forecastRequiredWidth est volontairement exclu : depuis le
    // correctif de autoCalcReferenceWidth, effectiveVisibleDayCount (et donc
    // forecastRequiredWidth) suit désormais la largeur réelle du widget en mode Auto. Si on
    // le laissait alimenter ce plancher, Layout.minimumWidth suivrait la largeur du moment
    // et l'utilisateur ne pourrait plus jamais rétrécir le widget après l'avoir agrandi (le
    // plancher grimpe avec la taille courante et ne redescend jamais). Le plancher bureau
    // reste donc fixe (fixedWidth / detailsRequiredWidth), et c'est visibleCols (plus bas,
    // via Math.floor(width / idealDayColumnWidth)) qui se charge seul d'adapter l'affichage
    // à la largeur réelle, sans jamais contraindre le redimensionnement lui-même.
    readonly property real contentWidth: Math.max(fixedWidth, detailsRequiredWidth, isDesktopMode ? 0 : forecastRequiredWidth)

    // Hauteur ajoutée par la ligne "lieu" sous la température (visible seulement si
    // cfg_showLocationExpanded + une ville détectée). En popup, on préfère absorber
    // cet ajout en réduisant d'autant forecastSection (voir Layout.preferredHeight
    // de forecastSection plus bas) plutôt que de faire grandir tout le popup —
    // seulement si l'espace restant pour forecastSection tomberait sous
    // forecastMinPopupHeight, calculatedHeight (dérivé de classicContent.implicitHeight
    // ci-dessous) grandit alors automatiquement du reliquat non absorbable.
    // FIX bug de hauteur du popup : ne JAMAIS lire `someItem.visible` pour calculer une
    // taille quand someItem est un descendant de classicContent. En Qt Quick, LIRE
    // `.visible` depuis QML renvoie la visibilité EFFECTIVE (en cascade depuis les
    // parents), pas seulement le flag local de l'item — donc dès que classicContent
    // devient invisible (opacity atteint 0, vue graphique affichée), TOUS ses
    // descendants, y compris locationRow, se mettent à répondre `.visible === false`,
    // MÊME SI leur propre binding `visible: ...` évalue à true. C'est confirmé
    // empiriquement via l'overlay de debug (headerSection.visible et
    // locationRow.parent.visible passent à false alors qu'aucun des deux n'a de
    // binding "visible:" explicite qui l'expliquerait — seule la cascade depuis
    // classicContent.visible=false explique ça). Du coup locationRowExtraHeight
    // retombait à 0 pendant la vue graphique, forecastSection regagnait de la hauteur
    // (93.6 -> 95.4), et calculatedHeight suivait : c'était la cause réelle du popup
    // qui "grandit" à l'ouverture des graphiques.
    // On recalcule donc la MÊME condition brute que locationRow.visible, indépendamment
    // de toute cascade de visibilité parent.
    readonly property bool locationRowShouldShow: !!(Plasmoid.configuration.showLocationExpanded && weatherData && weatherData.city)
    readonly property real locationRowExtraHeight: locationRowShouldShow ? Math.max(0, locationRow.implicitHeight + locationRow.Layout.topMargin) : 0
    readonly property real forecastMinPopupHeight: Kirigami.Units.gridUnit * 5.2

    readonly property int calculatedHeight: {
        if (isDesktopMode) {
            // Mode Bureau : la hauteur réelle vient de parent.height (poignées de
            // redimensionnement, voir "height" plus bas) ; cette valeur ne sert que
            // de plancher/valeur par défaut, inchangée.
            let base = Kirigami.Units.gridUnit * 12.5;
            return (showBottomDetails) ? base : (base - Kirigami.Units.gridUnit * 2.5);
        }
        // Mode Popup/Panneau : au lieu d'une constante devinée (qui laissait un vide
        // résiduel de taille variable sous detailsRow selon le nombre de jours/détails
        // affichés — d'où l'impression que le text detail "ne descendait pas assez"),
        // on dérive la hauteur directement du contenu réel de classicContent.
        // classicContent.implicitHeight est calculé "bottom-up" par le ColumnLayout à
        // partir de ses enfants (headerSection + forecastSection + detailsRow, leurs
        // marges et spacing) : il ne dépend PAS de rootItem.height, donc pas de
        // dépendance circulaire malgré classicContent.anchors.fill plus bas. Les
        // enfants invisibles (ex: detailsRow quand showBottomDetails est faux,
        // desktopClampMessage) sont automatiquement exclus par ColumnLayout, donc la
        // hauteur s'adapte d'elle-même, sans branche manuelle à maintenir.
        return Math.ceil(classicContent.implicitHeight);
    }

    // En mode bureau, on suit la taille imposée par l'utilisateur (poignées de redimensionnement) au lieu d'imposer une taille fixe.
    width: isDesktopMode && parent ? parent.width : contentWidth
    height: isDesktopMode && parent ? parent.height : calculatedHeight

    Layout.minimumWidth: contentWidth
    Layout.minimumHeight: calculatedHeight
    Layout.preferredWidth: contentWidth
    Layout.preferredHeight: calculatedHeight
    // En mode panneau/popup, la largeur suit contentWidth (peut grandir avec le nombre de détails) ;
    // en mode bureau, on autorise un agrandissement libre au-delà de ce minimum.
    Layout.maximumWidth: isDesktopMode ? Kirigami.Units.gridUnit * 60 : contentWidth
    Layout.maximumHeight: isDesktopMode ? Kirigami.Units.gridUnit * 40 : calculatedHeight

    Item {
        id: backgroundClipWrapper
        anchors { fill: parent; margins: rootItem.needsBackgroundBleed ? -rootItem.popupBleedMargin : 0 }
        z: -1

        layer.enabled: true
        layer.smooth: true
        layer.effect: OpacityMask {
            maskSource: backgroundMaskShape
        }

        Rectangle {
            id: backgroundMaskShape
            anchors.fill: parent
            radius: root.borderRadius
            color: "white"
            visible: false
        }

        Rectangle {
            id: backgroundContainer
            anchors.fill: parent
            color: Qt.rgba(Kirigami.Theme.backgroundColor.r, Kirigami.Theme.backgroundColor.g, Kirigami.Theme.backgroundColor.b, root.backgroundOpacity)
            radius: root.borderRadius
            clip: true

            layer.enabled: !!Plasmoid.configuration.showAnimations
            layer.smooth: true

            Item {
                id: animationsLayers
                anchors.fill: parent
                visible: !!(Plasmoid.configuration.showAnimations && weatherData && weatherData.weatherData && weatherData.currentTemperature !== "--")

                readonly property bool dayDetailActive: rootItem.selectedDayIndex !== -1

                readonly property int weatherCode: {
                    if (dayDetailActive) {
                        if (dayLineChart && dayLineChart.hoverIndex !== -1 && rootItem.hasHourlyData) {
                            let codeSlice = rootItem.hourlySlice("weather_code");
                            let hc = codeSlice[animationsLayers.viewedHour];
                            if (hc !== undefined && hc !== null) return parseInt(hc);
                        }
                        if (rootItem.selectedDayIndex === rootItem.currentDayIndex) {
                            return weatherData && weatherData.weatherCode ? parseInt(weatherData.weatherCode) : 0;
                        }
                        if (rootItem.dailyData && rootItem.dailyData.weather_code) {
                            let code = rootItem.dailyData.weather_code[rootItem.selectedDayIndex];
                            return (code !== undefined && code !== null) ? parseInt(code) : 0;
                        }
                        return 0;
                    }
                    return weatherData && weatherData.weatherCode ? parseInt(weatherData.weatherCode) : 0;
                }

                readonly property int viewedMinutes: {
                    if (dayDetailActive && dayLineChart && dayLineChart.hoverIndex !== -1) {
                        return Math.round(dayLineChart.hoverIndex * 60);
                    }
                    let now = new Date();
                    return now.getHours() * 60 + now.getMinutes();
                }
                readonly property int viewedHour: Math.floor(viewedMinutes / 60)

                function minutesFromIso(iso) {
                    if (!iso) return null;
                    let t = iso.split("T")[1];
                    if (!t) return null;
                    let p = t.split(":");
                    return parseInt(p[0]) * 60 + parseInt(p[1]);
                }

                function isDayAt(dayIdx, minutesOfDay) {
                    let sunrise = (rootItem.dailyData && rootItem.dailyData.sunrise) ? minutesFromIso(rootItem.dailyData.sunrise[dayIdx]) : null;
                    let sunset  = (rootItem.dailyData && rootItem.dailyData.sunset)  ? minutesFromIso(rootItem.dailyData.sunset[dayIdx])  : null;
                    if (sunrise === null || sunset === null) {
                        let h = Math.floor(minutesOfDay / 60);
                        return (h >= 7 && h <= 20);
                    }
                    return minutesOfDay >= sunrise && minutesOfDay < sunset;
                }

                readonly property real windValue: {
                    if (dayDetailActive && rootItem.hasHourlyData) {
                        let windSlice = rootItem.hourlySlice("wind_speed_10m");
                        let v = windSlice[animationsLayers.viewedHour];
                        return (v !== undefined) ? parseFloat(v) : 0;
                    }
                    return weatherData && weatherData.windSpeed && weatherData.windSpeed !== "--" ? parseFloat(weatherData.windSpeed) : 0;
                }

                readonly property bool isDay: {
                    if (!dayDetailActive) {
                        if (weatherData && weatherData.weatherData && weatherData.weatherData.current) {
                            return weatherData.weatherData.current.is_day === 1;
                        }
                        return isDayAt(rootItem.currentDayIndex, viewedMinutes);
                    }
                    return isDayAt(rootItem.selectedDayIndex, viewedMinutes);
                }

                readonly property bool showSun:     isDay
                readonly property bool showNight:   !isDay
                readonly property bool showCloud:   weatherCode >= 3 && weatherCode !== 45 && weatherCode !== 48
                readonly property bool showStorm:   weatherCode >= 95
                readonly property bool showSnow:    (weatherCode >= 71 && weatherCode <= 77) || weatherCode === 85 || weatherCode === 86
                readonly property bool showRain:    (weatherCode >= 61 && weatherCode <= 67) || (weatherCode >= 80 && weatherCode <= 82)
                readonly property bool showDrizzle: weatherCode >= 51 && weatherCode <= 57
                readonly property bool showMist:    weatherCode === 45 || weatherCode === 48
                readonly property bool showRainbow: isDay && (weatherCode === 80 || weatherCode === 81)
                readonly property bool showWind:    windValue >= 20

                // Durée du fondu enchaîné entre couches météo (jour/nuit, pluie, neige, etc.).
                readonly property int layerFadeDuration: 1100

                // Modèle STATIQUE (la référence du tableau ne change jamais) : le Repeater ne
                // recrée donc ses délégués qu'une seule fois. Seules les propriétés `opacity`/
                // `active` de chaque Loader se mettent à jour en continu via le lookup dynamique
                // `animationsLayers[modelData.boolProp]`, ce qui préserve exactement l'ordre
                // d'empilement (z) d'origine.
                readonly property var layerDefs: [
                    { source: "animations/Sun.qml",     boolProp: "showSun" },
                    { source: "animations/Night.qml",   boolProp: "showNight" },
                    { source: "animations/Cloud.qml",   boolProp: "showCloud" },
                    { source: "animations/Storm.qml",   boolProp: "showStorm" },
                    { source: "animations/Snow.qml",    boolProp: "showSnow" },
                    { source: "animations/Rain.qml",    boolProp: "showRain" },
                    { source: "animations/Rainbow.qml", boolProp: "showRainbow", requiresRainbowConfig: true },
                    { source: "animations/Drizzle.qml", boolProp: "showDrizzle" },
                    { source: "animations/Mist.qml",    boolProp: "showMist" },
                    { source: "animations/Wind.qml",    boolProp: "showWind" }
                ]

                Repeater {
                    model: animationsLayers.layerDefs
                    delegate: Loader {
                        anchors.fill: parent
                        source: modelData.source
                        active: !!(Plasmoid.configuration.showAnimations && animationsLayers.visible
                        && (!modelData.requiresRainbowConfig || Plasmoid.configuration.rainbowEffect))
                        opacity: animationsLayers[modelData.boolProp] ? 1.0 : 0.0
                        visible: opacity > 0.01
                        Behavior on opacity { NumberAnimation { duration: animationsLayers.layerFadeDuration; easing.type: Easing.InOutSine } }
                    }
                }
            }
        }
    }

    // ============================================================
    // === DEBUG (désactivé, laissé en commentaire au cas où) ===
    // Bug identifié et corrigé : voir locationRowShouldShow / locationRowExtraHeight
    // et headerSection.Layout.preferredHeight plus haut dans le fichier.
    /*
     *    Rectangle {
     *        z: 9999
     *        anchors.top: parent.top
     *        anchors.right: parent.right
     *        color: "black"
     *        opacity: 0.75
     *        width: debugCol.implicitWidth + 12
     *        height: debugCol.implicitHeight + 12
     *        visible: true
     *        Column {
     *            id: debugCol
     *            anchors.centerIn: parent
     *            Text { color: "yellow"; font.pixelSize: 10; font.bold: true; text: "BUILD: v3-anchors-fix" }
     *            Text { color: "lime"; font.pixelSize: 10; text: "rootH: " + rootItem.height }
     *            Text { color: "lime"; font.pixelSize: 10; text: "calcH: " + rootItem.calculatedHeight }
     *            Text { color: "lime"; font.pixelSize: 10; text: "classicH: " + classicContent.implicitHeight.toFixed(3) }
     *            Text { color: "lime"; font.pixelSize: 10; text: "classicVis: " + classicContent.visible }
     *            Text { color: "lime"; font.pixelSize: 10; text: "dayDetH: " + dayDetailView.implicitHeight.toFixed(3) }
     *            Text { color: "lime"; font.pixelSize: 10; text: "fcW/H: " + forecastSection.width.toFixed(1) + "/" + forecastSection.height.toFixed(1) }
     *            Text { color: "lime"; font.pixelSize: 10; text: "fcPrefH: " + forecastSection.Layout.preferredHeight.toFixed(3) }
     *            Text { color: "lime"; font.pixelSize: 10; text: "locRowExtraH: " + rootItem.locationRowExtraHeight.toFixed(3) }
     *            Text { color: "lime"; font.pixelSize: 10; text: "locRow vis/implH: " + locationRow.visible + "/" + locationRow.implicitHeight.toFixed(3) }
     *            Text { color: "yellow"; font.pixelSize: 10; text: "cfg.showLocExp: " + Plasmoid.configuration.showLocationExpanded }
     *            Text { color: "yellow"; font.pixelSize: 10; text: "weatherData city: '" + (weatherData ? weatherData.city : "NULL") + "'" }
     *            Text { color: "yellow"; font.pixelSize: 10; text: "weatherData isBusy: " + (weatherData ? weatherData.isBusy : "NULL") }
     *            Text { color: "orange"; font.pixelSize: 10; font.bold: true; text: "manualCalc: " + !!(Plasmoid.configuration.showLocationExpanded && weatherData && weatherData.city) + " vs locVis: " + locationRow.visible }
     *            Text { color: "orange"; font.pixelSize: 10; text: "locRow.parent.vis: " + locationRow.parent.visible + " headerSec.vis: " + headerSection.visible }
     *            Text { color: "yellow"; font.pixelSize: 10; text: "selDay: " + rootItem.selectedDayIndex }
     *            Text { color: "lime"; font.pixelSize: 10; text: "isDesktop: " + rootItem.isDesktopMode }
}
}
*/

    Item {
        id: infoLayout
        anchors { fill: parent; margins: rootItem.desktopContentInset }
        // classicContent et dayDetailView se superposent tous les deux (anchors.fill) et se
        // croisent via un fondu enchaîné de 180ms (opacity) — pendant ce court instant, les
        // deux sont "visible: true" en même temps. Sans clip ici, un éventuel débordement
        // transitoire de l'un des deux (même de quelques px) reste visible et peut amener le
        // dialogue popup de Plasma à ajuster sa taille dessus, avant de revenir à la normale
        // une fois la transition terminée — d'où l'impression que le popup "grandit
        // légèrement" à l'ouverture des graphiques puis "redescend" à la fermeture.
        clip: true

        ColumnLayout {
            id: classicContent
            // FIX boucle circulaire : anchors.fill (gauche+droite+haut+BAS) forçait la
            // hauteur RÉELLE de classicContent à suivre infoLayout.height, lui-même dérivé
            // de rootItem.height = calculatedHeight = classicContent.implicitHeight. En
            // théorie implicitHeight (bottom-up) est indépendant de la hauteur assignée,
            // mais en pratique un léger désync d'une frame entre rootItem.height et
            // calculatedHeight (observé : rootH=225 vs calcH=224) suffit à donner à
            // classicContent une hauteur réelle légèrement différente de son propre besoin,
            // ce qui comprime/détend forecastSection (qui a une petite marge de compression
            // entre forecastMinPopupHeight et sa preferredHeight) — et cette variation se
            // répercute dans le calcul suivant de calculatedHeight. Une vraie boucle,
            // confirmée par le debug overlay (classicH: 224.000 en vue classique vs
            // 226.000 en vue graphique, alors que rien dans classicContent ne dépend de
            // selectedDayIndex). En ancrant seulement gauche/droite/haut (pas bas), la
            // hauteur réelle de classicContent redevient purement son implicitHeight
            // naturel, sans jamais être contrainte par rootItem.height : plus de boucle.
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            // Bureau : on garde l'ancrage bas, nécessaire à forecastSection.Layout.fillHeight
            // pour s'étirer avec les poignées de redimensionnement (pas de boucle possible
            // ici, calculatedHeight en mode Bureau est une constante fixe, pas dérivée de
            // classicContent.implicitHeight). Popup : anchors.bottom délibérément absent
            // (voir note plus haut) pour casser la boucle circulaire.
            anchors.bottom: rootItem.isDesktopMode ? parent.bottom : undefined
            spacing: 0

            opacity: rootItem.selectedDayIndex === -1 ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            RowLayout {
                id: headerSection
                Layout.fillWidth: true
                // Bureau : volontairement plus réduit que forecastSection/detailsRow (voir
                // desktopHeaderTopBreathing), inchangé.
                // Popup : popupEdgeMargin, la MÊME valeur que detailsRow.bottomMargin plus
                // bas, pour une symétrie garantie entre "bord haut → température" et
                // "bord bas → text detail" — appliquée directement, sans compensation
                // (voir la note sur l'ancien système de compensation plus haut dans le fichier).
                // Popup : popupEdgeMargin moins un petit popupHeaderTopTrim (voir la note
                // plus haut dans le fichier) pour compenser l'espace invisible en plus que
                // réserve la boîte du header au-dessus de son texte. detailsRow.bottomMargin,
                // lui, reste à popupEdgeMargin pur, sans y toucher (mesuré comme déjà correct).
                Layout.topMargin: rootItem.isDesktopMode ? Kirigami.Units.smallSpacing * rootItem.desktopHeaderTopBreathing : Math.max(0, rootItem.popupEdgeMargin - rootItem.popupHeaderTopTrim)
                // Bureau ET Popup : voir desktopHeaderBottomTrim / popupHeaderBottomTrim plus
                // haut dans le fichier. headerSection n'avait jamais de bottomMargin propre
                // avant (0 par défaut des deux côtés) ; cette petite valeur négative absorbe
                // l'espace invisible en trop sous le texte du header (police énorme), pour que
                // "header → liste des jours" ne soit plus visiblement plus grand que "liste des
                // jours → text details" — l'asymétrie touchait aussi le mode Bureau, pas
                // seulement le Popup.
                Layout.bottomMargin: rootItem.isDesktopMode ? -rootItem.desktopHeaderBottomTrim : -rootItem.popupHeaderBottomTrim
                // Marges horizontales : plein gridUnit des deux côtés, comme v0. Un précédent
                // passage les avait alignées sur popupSideMargin (0.85 gridUnit) "pour la
                // cohérence" avec detailsRow, mais ça réduisait la marge droite disponible pour
                // rightSideContainer/detailsGrid (grille compacte quand la condition est
                // désactivée), qui devenait alors trop proche du bord et serrée — confirmé en
                // comparant avec le rendu v0 (référence) où la grille est correctement contenue.
                Layout.leftMargin: Kirigami.Units.gridUnit
                Layout.rightMargin: Kirigami.Units.gridUnit
                spacing: 0

                // Pourquoi les jours pouvaient s'écrire sur la température quand la HAUTEUR du
                // widget Bureau change (et pas seulement la largeur) : headerSection n'avait pas
                // de Layout.minimumHeight propre. Sans ça, quand l'espace total manque, un
                // ColumnLayout peut compresser N'IMPORTE lequel de ses enfants en dessous de sa
                // taille nécessaire — pas seulement forecastSection (qui a fillHeight et est
                // CENSÉ être le seul à céder de la place). headerSection se retrouvait alors
                // rétréci sous sa propre hauteur de contenu, et "29°C" débordait visuellement
                // dans la zone de forecastSection juste en dessous, d'où la superposition avec
                // "Sam.". Le minimumHeight ci-dessous, identique au preferredHeight, empêche ça :
                // c'est forecastSection qui doit céder de la place en premier, jamais le header.
                Layout.minimumHeight: Layout.preferredHeight

                // Pourquoi les jours pouvaient s'écrire sur la température en mode Bureau
                // étroit (colonne verticale) : conditionLabel ("Clear"/"Mainly clear") a
                // wrapMode: Text.WordWrap et peut passer sur 2 lignes quand la largeur
                // disponible se réduit. Un RowLayout classique ne recalcule pas toujours
                // sa hauteur correctement dans ce cas précis (la largeur détermine la
                // hauteur du texte, et Qt Quick Layouts peut sous-estimer la hauteur au
                // premier passage) : headerSection restait alors trop bas, et
                // forecastSection démarrait par-dessus. Cette liaison explicite force le
                // recalcul à chaque fois que la hauteur d'un des enfants change (donc aussi
                // quand conditionLabel passe de 1 à 2 lignes), garantissant que la place
                // réservée est toujours suffisante.
                Layout.preferredHeight: Math.max(tempContainer.implicitHeight, root.showConditionExpanded ? conditionLabel.implicitHeight : 0, (!root.showConditionExpanded && anyDetailEnabled) ? rightSideContainer.implicitHeight : 0)

                Item { Layout.fillWidth: true; visible: !rootItem.isDesktopMode && !(conditionLabel.visible || rightSideContainer.visible) }

                ColumnLayout {
                    id: tempContainer
                    spacing: 0
                    Layout.alignment: Qt.AlignVCenter

                    Row {
                        spacing: 0

                        PlasmaComponents3.Label {
                            id: tempValueLabel
                            text: currentTempText
                            font.pixelSize: Kirigami.Units.gridUnit * 2.5
                            font.bold: true
                            leftPadding: currentTempText.length === 1 ? Kirigami.Units.gridUnit * 0.4 : 0
                            color: Kirigami.Theme.textColor
                        }
                        PlasmaComponents3.Label {
                            text: unitStr
                            font.pixelSize: Kirigami.Units.gridUnit * 1.5
                            font.bold: true
                            topPadding: Kirigami.Units.gridUnit * 0.2
                            color: Kirigami.Theme.textColor
                        }
                    }

                    // Porté depuis la pull request mergée sur l'ancienne version (v0) : affiche
                    // le lieu détecté (icône + nom de ville) sous la température, activable via
                    // Apparence > Vue étendue > "Location Text" (cfg_showLocationExpanded).
                    Row {
                        id: locationRow
                        spacing: Kirigami.Units.smallSpacing / 2
                        visible: !!(Plasmoid.configuration.showLocationExpanded && weatherData && weatherData.city)
                        // Malentendu corrigé : "augmenter la hauteur" voulait en fait dire
                        // "remonter légèrement" — icône/texte revenus à leur taille d'origine, et
                        // marge négative (au lieu de positive) pour resserrer la ligne contre la
                        // température. locationRowExtraHeight (hauteur ajoutée par cette ligne,
                        // utilisée pour ajuster le popup et forecastSection) suit automatiquement.
                        // En mode Panel (popup), on la remonte un peu plus pour la centrer entre
                        // la température et la ligne des jours (Lun./Mar./...) en dessous. En
                        // mode Bureau on garde la valeur d'origine (l'espacement y est différent).
                        Layout.topMargin: rootItem.isDesktopMode
                        ? -Kirigami.Units.smallSpacing * 0.3
                        : -Kirigami.Units.smallSpacing * 1.1

                        Kirigami.Icon {
                            source: "mark-location"
                            width: Kirigami.Units.gridUnit * 0.8
                            height: width
                            color: Kirigami.Theme.textColor
                            opacity: 0.7
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        PlasmaComponents3.Label {
                            text: weatherData && weatherData.city ? weatherData.city : ""
                            font.pixelSize: Kirigami.Units.gridUnit * 0.7
                            color: Kirigami.Theme.textColor
                            opacity: 0.7
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // === DEBUG (désactivé, laissé en commentaire au cas où) ===
                    /*
                     *                    Text {
                     *                        Layout.preferredHeight: implicitHeight
                     *                        color: "cyan"
                     *                        font.pixelSize: 9
                     *                        font.bold: true
                     *                        text: "cfg:" + Plasmoid.configuration.showLocationExpanded
                     *                            + " wd:" + !!weatherData
                     *                            + " city:'" + (weatherData ? weatherData.city : "??") + "'"
                     *                            + " => locVis:" + locationRow.visible
                }
                */
                }

                PlasmaComponents3.Label {
                    id: conditionLabel
                    visible: !!root.showConditionExpanded
                    Layout.alignment: Qt.AlignVCenter
                    Layout.fillWidth: true
                    Layout.leftMargin: Kirigami.Units.gridUnit * 0.6

                    text: weatherData ? weatherData.weatherLongText : ""
                    font.pixelSize: text.length <= 10 ? Kirigami.Units.gridUnit * 1.3 : Kirigami.Units.gridUnit * 1.0
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2

                    horizontalAlignment: {
                        switch (rootItem.conditionAlignment) {
                            case 0: return Text.AlignLeft;
                            case 2: return Text.AlignRight;
                            default: return Text.AlignHCenter;
                        }
                    }
                    verticalAlignment: Text.AlignVCenter
                    color: Kirigami.Theme.textColor
                }

                // Avant : Item { Layout.fillWidth: true; visible: !conditionLabel.visible }.
                // Ce spacer avalait TOUT l'espace libre restant, plaquant rightSideContainer/
                // detailsGrid tout petit contre le bord droit ("très à droite et serré"). Il
                // faut au contraire que ce soit la grille de détails elle-même qui grandisse
                // pour occuper l'espace vide entre la température et le bord droit — voir
                // rightSideContainer.Layout.fillWidth ci-dessous.
                Item {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 0.6
                    visible: !conditionLabel.visible
                }

                ColumnLayout {
                    id: rightSideContainer
                    Layout.alignment: Qt.AlignVCenter
                    Layout.fillWidth: !conditionLabel.visible
                    spacing: 0
                    visible: !!(!root.showConditionExpanded && anyDetailEnabled)

                    GridLayout {
                        id: detailsGrid
                        visible: !!(!root.showConditionExpanded && anyDetailEnabled)
                        columns: 2
                        rowSpacing: Kirigami.Units.gridUnit * 0.3
                        // Avant : smallSpacing, pertinent uniquement quand la grille était collée
                        // au bord droit (rightNudge). Maintenant qu'elle remplit l'espace libre
                        // (Layout.fillWidth ci-dessous), un espacement plus généreux entre les
                        // deux colonnes évite qu'elles se retrouvent à nouveau collées l'une à
                        // l'autre une fois étalées.
                        columnSpacing: Kirigami.Units.gridUnit * 1.2
                        layoutDirection: Qt.RightToLeft
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                        // La grille remplit maintenant tout rightSideContainer (lui-même fillWidth,
                        // voir plus haut) au lieu de rester à sa taille naturelle collée à droite.
                        Layout.fillWidth: true

                        // rightNudge/Layout.rightMargin (-7.5) supprimé : il compensait le collage
                        // au bord droit d'avant, devenu obsolète maintenant que la grille s'étale
                        // dans l'espace disponible plutôt que d'être plaquée contre le bord.
                        Layout.topMargin: root.showConditionExpanded ? 0 : Kirigami.Units.gridUnit * 0.4

                        readonly property var quickStats: rootItem.buildDetailEntries(
                            rootItem.detailsOrderIds.slice(0, rootItem.compactDetailsMaxCount), "labelKey")

                        Repeater {
                            model: detailsGrid.quickStats
                            delegate: DetailValueColumn {
                                compact: true
                                label: modelData.label
                                value: modelData.value
                            }
                        }
                    }
                }
            }

            // En mode Bureau, la largeur est gérée à la main par l'utilisateur (voir isDesktopMode
            // plus haut) : on ne peut pas l'agrandir nous-mêmes comme en popup. Si la largeur
            // réelle devient trop juste pour le nombre de colonnes explicitement configuré dans
            // "Visible at once", on préfère prévenir l'utilisateur et aligner la valeur enregistrée
            // sur ce qui tient réellement plutôt que de rétrécir les icônes ou de laisser la valeur
            // affichée diverger silencieusement de celle des réglages.
            Kirigami.InlineMessage {
                id: desktopClampMessage
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.gridUnit
                Layout.rightMargin: Kirigami.Units.gridUnit
                Layout.topMargin: visible ? Kirigami.Units.smallSpacing : 0
                type: Kirigami.MessageType.Information
                showCloseButton: true
                visible: false
                property int clampedFrom: 0
                property int clampedTo: 0
                text: i18n("Widget too narrow to show %1 forecast days at once — reduced to %2. Resize it wider to show more.", clampedFrom, clampedTo)
            }

            // Attend la fin d'un redimensionnement (plutôt que de réagir à chaque pixel glissé)
            // avant de vérifier s'il faut prévenir l'utilisateur et ajuster la config.
            Timer {
                id: desktopClampTimer
                interval: 500
                Component.onCompleted: if (rootItem.isDesktopMode) restart();
                onTriggered: {
                    if (!rootItem.isDesktopMode || rootItem.configuredVisibleDayCount <= 0) return;
                    let maxFit = Math.max(1, Math.floor(forecastSection.width / rootItem.idealDayColumnWidth));
                    if (maxFit < rootItem.configuredVisibleDayCount) {
                        desktopClampMessage.clampedFrom = rootItem.configuredVisibleDayCount;
                        desktopClampMessage.clampedTo = maxFit;
                        desktopClampMessage.visible = true;
                        Plasmoid.configuration.forecastVisibleDayCount = maxFit;
                    } else {
                        desktopClampMessage.visible = false;
                    }
                }
            }

            Connections {
                target: rootItem
                enabled: rootItem.isDesktopMode
                function onWidthChanged() { desktopClampTimer.restart(); }
            }

            ListView {
                id: forecastSection
                Layout.fillWidth: true
                Layout.fillHeight: rootItem.isDesktopMode
                // Bureau : 6.0 gridUnit, inchangé (confirmé "nickel" par l'utilisateur).
                // Popup : ERREUR CORRIGÉE — le commentaire précédent affirmait que 6.0 gridUnit
                // était "la valeur d'origine de v0", ce qui était FAUX : v0 utilise 5.0 gridUnit
                // (vérifié directement dans FullRepresentationv0.qml). Cette confusion, cumulée
                // aux marges de respiration ajoutées ailleurs (popupSectionGap, popupEdgeMargin...)
                // pendant les réglages de centrage, faisait que le popup était sensiblement plus
                // haut que v0 — pas seulement à cause de la ligne "lieu". Ramené à 5.3 gridUnit :
                // proche de la vraie valeur v0 (5.0) tout en gardant un peu de marge au-dessus du
                // plancher anti-clipping (forecastMinPopupHeight, 5.2) pour ne pas re-couper "Dim."
                Layout.preferredHeight: rootItem.isDesktopMode
                ? Kirigami.Units.gridUnit * 6.0
                : Math.max(rootItem.forecastMinPopupHeight, Kirigami.Units.gridUnit * 5.3 - rootItem.locationRowExtraHeight)
                // Filet de sécurité dans les DEUX modes : sans ça, quand headerSection grandit
                // (ex. ligne "lieu" activée), forecastSection (sans minimum propre) pouvait être
                // écrasée sous la hauteur dont son contenu a besoin — jusqu'à clipper (clip: true)
                // le haut du label du premier jour ("Dim." partiellement caché/coupé), observé
                // aussi bien en Bureau qu'en Popup.
                Layout.minimumHeight: rootItem.isDesktopMode ? Kirigami.Units.gridUnit * 4.8 : rootItem.forecastMinPopupHeight

                // Bureau : symétrie verticale existante (voir desktopVerticalBreathing), inchangée.
                // Popup : popupSectionGap comme valeur identique des deux côtés (topMargin ==
                // bottomMargin par construction). L'asymétrie observée entre "header → liste"
                // et "liste → détails" ne vient pas d'ici : voir popupHeaderBottomTrim sur
                // headerSection.bottomMargin plus haut, qui absorbe l'excès directement à sa
                // source (le bas du header) plutôt que de forcer cette marge à compenser un
                // écart qu'elle n'a pas la place d'absorber.
                //
                // À savoir : cette ListView a une Layout.preferredHeight FIXE (gridUnit * 6.0) et
                // son delegate centre contentColumn verticalement dans chaque cellule. Avec une
                // seule rangée visible, ce centrage ajoute déjà ~15-20px de vide symétrique au-
                // dessus et en dessous de "Mer./Jeu./Ven.", en plus des marges ci-dessous. C'est
                // voulu : popupSectionGap n'a donc pas besoin d'être grand, l'essentiel de la
                // respiration visuelle vient de ce centrage (déjà symétrique par nature).
                // desktopHeaderSafetyPadding : padding de base non négociable, indépendant de
                // tout calcul de hauteur (voir rootItem.desktopHeaderSafetyPadding). Garantit un
                // espace minimum entre le header et la liste des jours même si un futur réglage
                // remet par erreur headerSection.bottomMargin à une valeur négative (voir la note
                // sur desktopHeaderBottomTrim, désormais à 0, plus haut dans le fichier).
                // Popup, sans la ligne "lieu" : le header se termine plus haut (pas de ligne
                // "Toulouse" en dessous de la température), donc popupSectionGap seul laissait
                // la liste des jours trop proche/trop haute. On ajoute un petit supplément
                // uniquement dans ce cas précis (localisation désactivée, mode Panel).
                Layout.topMargin: (rootItem.isDesktopMode ? Kirigami.Units.smallSpacing * rootItem.desktopVerticalBreathing : rootItem.popupSectionGap) + (rootItem.isDesktopMode ? rootItem.desktopHeaderSafetyPadding : 0)
                + (!rootItem.isDesktopMode && !rootItem.locationRowShouldShow ? Kirigami.Units.smallSpacing * 0.9 : 0)
                // Popup : popupSectionGap moins popupForecastBottomTrim (voir la note sur cette
                // propriété plus haut dans le fichier) — rapproche la bande de text details de la
                // liste des jours, pour égaliser avec l'espace "header → liste des jours" déjà
                // resserré côté haut. Bureau inchangé (symétrie desktopVerticalBreathing existante).
                Layout.bottomMargin: rootItem.isDesktopMode ? Kirigami.Units.smallSpacing * rootItem.desktopVerticalBreathing : Math.max(0, rootItem.popupSectionGap - rootItem.popupForecastBottomTrim)

                spacing: 0
                orientation: ListView.Horizontal

                snapMode: ListView.SnapToItem
                boundsBehavior: Flickable.OvershootBounds
                maximumFlickVelocity: 500
                flickDeceleration: 1000
                interactive: canScrollHorizontally
                clip: true

                // effectiveVisibleDayCount est un MAXIMUM : on n'affiche jamais plus de colonnes
                // que ce nombre (Math.min, alors que l'ancien code faisait l'inverse avec
                // Math.max et pouvait donc le dépasser dès que la largeur réelle grandissait).
                // On n'affiche pas non plus plus de colonnes que ce qui tient confortablement
                // dans la largeur réelle (idealDayColumnWidth) : les icônes ne rétrécissent
                // jamais en dessous de cette taille, on préfère afficher moins de colonnes.
                readonly property int visibleCols: {
                    let comfortable = Math.max(1,
                                               Math.min(rootItem.effectiveVisibleDayCount, Math.floor(width / rootItem.idealDayColumnWidth)));
                    // Cas "1 ligne" (popup/panneau, et bureau quand la hauteur ne permet pas
                    // plusieurs rangées) : ne jamais réserver plus de colonnes que de jours
                    // réellement disponibles ("Days to display"), sinon les colonnes en trop
                    // restent vides et le contenu ne remplit pas toute la largeur. Calculé
                    // directement depuis la hauteur (et non visibleRows, qui dépend lui-même de
                    // visibleCols) pour éviter toute dépendance circulaire.
                    let rowCapacity = rootItem.isDesktopMode
                    ? Math.max(1, Math.floor(height / (Kirigami.Units.gridUnit * 5.0)))
                    : 1;
                    if (rowCapacity <= 1 && rootItem.availableDayCount > 0) {
                        comfortable = Math.min(comfortable, rootItem.availableDayCount);
                    }
                    return comfortable;
                }
                readonly property int maxNeededRows: Math.max(1, Math.ceil(rootItem.availableDayCount / visibleCols))
                readonly property int visibleRows: rootItem.isDesktopMode ?
                Math.min(maxNeededRows, Math.max(1, Math.floor(height / (Kirigami.Units.gridUnit * 5.0)))) : 1

                readonly property int daysPerPage: visibleCols * visibleRows

                readonly property int totalColumns: {
                    if (visibleRows <= 1) return Math.max(1, rootItem.availableDayCount);
                    let fullPages = Math.floor(rootItem.availableDayCount / daysPerPage);
                    let remainder = rootItem.availableDayCount % daysPerPage;
                    let remainderCols = remainder === 0 ? 0 : Math.min(remainder, visibleCols);
                    return Math.max(1, (fullPages * visibleCols) + remainderCols);
                }

                readonly property bool canScrollHorizontally: contentWidth > width + 1

                model: totalColumns

                // BUG CORRIGÉ : le delegate a une largeur DYNAMIQUE (width / visibleCols, voir
                // colDelegate plus bas), mais contentX est un décalage en PIXELS ABSOLUS que Qt
                // Quick ne recalcule jamais tout seul quand cette largeur change. Au premier
                // affichage du popup, la largeur passe presque toujours par plusieurs valeurs
                // avant de se stabiliser (Kirigami calcule la taille finale après coup) : si
                // contentX n'était pas exactement 0 à ce moment-là (overshoot du Flickable,
                // arrondi, etc.), il ne retombe PAS automatiquement sur une frontière de colonne
                // valide une fois la largeur stabilisée — SnapToItem ne se déclenche que sur une
                // interaction (flick), jamais sur un simple changement de taille. Résultat observé :
                // une colonne affichée à moitié, la flèche "précédent" visible alors que rien n'a
                // été scrollé. On re-snap explicitement à chaque changement de largeur/nombre de
                // colonnes, et on force 0 au chargement pour partir d'un état toujours propre.
                function resnapContentX() {
                    if (visibleCols <= 0 || width <= 0) return;
                    let itemW = width / visibleCols;
                    let maxX = Math.max(0, contentWidth - width);
                    let snapped = Math.round(contentX / itemW) * itemW;
                    contentX = Math.max(0, Math.min(maxX, snapped));
                }
                onWidthChanged: resnapContentX()
                onVisibleColsChanged: resnapContentX()
                Component.onCompleted: contentX = 0

                MouseArea {
                    id: forecastHoverMouse
                    anchors.fill: parent
                    z: 1
                    acceptedButtons: Qt.NoButton
                    hoverEnabled: true

                    cursorShape: (hoveredIcon && rootItem.hasHourlyData && rootItem.anyChartEnabled) ? Qt.PointingHandCursor : Qt.ArrowCursor
                    property bool hoveredIcon: false
                    property var hoveredIconRef: null

                    onPositionChanged: function(mouse) {
                        let colDelegate = forecastSection.itemAt(forecastSection.contentX + mouse.x, mouse.y);
                        if (colDelegate && rootItem.hasHourlyData && rootItem.anyChartEnabled) {
                            let cellHeight = forecastSection.height / forecastSection.visibleRows;
                            let rowIndex = Math.floor(mouse.y / cellHeight);
                            let dayCell = colDelegate.rowRepeater.itemAt(rowIndex);
                            if (dayCell && dayCell.iconItem && dayCell.visible) {
                                let pt = mapToItem(dayCell.iconItem, mouse.x, mouse.y);
                                let inside = pt.x >= 0 && pt.x <= dayCell.iconItem.width && pt.y >= 0 && pt.y <= dayCell.iconItem.height;
                                hoveredIcon = inside;
                                hoveredIconRef = inside ? dayCell.iconItem : null;
                            } else {
                                hoveredIcon = false;
                                hoveredIconRef = null;
                            }
                        } else {
                            hoveredIcon = false;
                            hoveredIconRef = null;
                        }
                    }
                    onExited: { hoveredIcon = false; hoveredIconRef = null; }

                    property int currentIndex: 0
                    property real wheelAccum: 0
                    readonly property real wheelThreshold: 120

                    onWheel: function(wheel) {
                        let delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x;
                        let itemW = forecastSection.width / forecastSection.visibleCols;
                        let maxIndex = Math.max(0, Math.round((forecastSection.contentWidth - forecastSection.width) / itemW));
                        wheelAccum += delta;

                        while (wheelAccum <= -wheelThreshold) {
                            currentIndex = Math.min(maxIndex, currentIndex + 1);
                            wheelAccum += wheelThreshold;
                        }
                        while (wheelAccum >= wheelThreshold) {
                            currentIndex = Math.max(0, currentIndex - 1);
                            wheelAccum -= wheelThreshold;
                        }

                        let targetX = Math.max(0, Math.min(forecastSection.contentWidth - forecastSection.width, currentIndex * itemW));
                        forecastScrollAnim.to = targetX;
                        forecastScrollAnim.restart();
                        wheel.accepted = true;
                    }
                }

                NumberAnimation {
                    id: forecastScrollAnim
                    target: forecastSection
                    property: "contentX"
                    duration: 200
                    easing.type: Easing.OutCubic
                }

                Item {
                    id: leftScrollHint
                    z: 2
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: rootItem.forecastArrowIconOffset
                    anchors.leftMargin: -1
                    width: Kirigami.Units.gridUnit * 1.55
                    height: width
                    visible: forecastSection.canScrollHorizontally
                    // Condition booléenne (indépendante de l'opacité animée) : sert à la fois
                    // pour l'opacité, l'activation de la zone cliquable et le curseur, afin que
                    // ce dernier ne reste jamais en mode "main" une fois la flèche disparue.
                    readonly property bool active: forecastSection.contentX > 1
                    opacity: active ? (leftHintMouse.containsMouse ? 1.0 : 0.55) : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 3
                        radius: width / 2
                        color: Kirigami.Theme.textColor
                        opacity: leftHintMouse.containsMouse ? 0.08 : 0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: parent.width * 0.5
                        height: width
                        source: "go-previous"
                        color: Kirigami.Theme.textColor
                    }

                    MouseArea {
                        id: leftHintMouse
                        anchors.fill: parent
                        hoverEnabled: leftScrollHint.active
                        enabled: leftScrollHint.active
                        // "visible: false" (et pas seulement enabled/hoverEnabled à false) est nécessaire :
                        // même désactivée, une MouseArea garde un cursorShape explicite, et comme cette zone
                        // reste "au-dessus" de la cellule du jour dans la pile de rendu (elle est enfant direct
                        // de forecastSection, alors que la cellule est nichée dans le contentItem de la ListView),
                        // Qt Quick continuerait à appliquer SON curseur (ArrowCursor) au lieu de laisser passer
                        // la main au curseur de la zone de détection de l'icône météo en dessous.
                        visible: leftScrollHint.active
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            let itemW = forecastSection.width / forecastSection.visibleCols;
                            let target = Math.max(0, forecastSection.contentX - itemW);
                            forecastScrollAnim.to = target;
                            forecastScrollAnim.restart();
                        }
                    }
                }

                Item {
                    id: rightScrollHint
                    z: 2
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: rootItem.forecastArrowIconOffset
                    anchors.rightMargin: -1
                    width: Kirigami.Units.gridUnit * 1.55
                    height: width
                    visible: forecastSection.canScrollHorizontally
                    // Idem flèche gauche : condition booléenne indépendante de l'opacité animée.
                    readonly property bool active: forecastSection.contentX < (forecastSection.contentWidth - forecastSection.width - 1)
                    opacity: active ? (rightHintMouse.containsMouse ? 1.0 : 0.55) : 0
                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 3
                        radius: width / 2
                        color: Kirigami.Theme.textColor
                        opacity: rightHintMouse.containsMouse ? 0.08 : 0
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: parent.width * 0.5
                        height: width
                        source: "go-next"
                        color: Kirigami.Theme.textColor
                    }

                    MouseArea {
                        id: rightHintMouse
                        anchors.fill: parent
                        hoverEnabled: rightScrollHint.active
                        enabled: rightScrollHint.active
                        // Voir le commentaire équivalent sur leftHintMouse : même logique nécessaire ici.
                        visible: rightScrollHint.active
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            let itemW = forecastSection.width / forecastSection.visibleCols;
                            let maxX = forecastSection.contentWidth - forecastSection.width;
                            let target = Math.min(maxX, forecastSection.contentX + itemW);
                            forecastScrollAnim.to = target;
                            forecastScrollAnim.restart();
                        }
                    }
                }

                delegate: Column {
                    id: colDelegate
                    width: forecastSection.width / forecastSection.visibleCols
                    height: forecastSection.height
                    spacing: 0

                    readonly property int colIndex: index
                    // API officielle Repeater.itemAt() plutôt qu'un accès positionnel à children[],
                    // qui dépend de l'ordre interne (fragile : le Repeater lui-même compte comme enfant).
                    property alias rowRepeater: dayRowRepeater

                    Repeater {
                        id: dayRowRepeater
                        model: forecastSection.visibleRows
                        delegate: Item {
                            id: dayCell
                            width: colDelegate.width
                            height: colDelegate.height / forecastSection.visibleRows

                            // Ordre de lecture correct : on remplit chaque "page" (bloc de visibleCols x visibleRows)
                            // ligne par ligne, de gauche à droite, avant de passer à la page suivante.
                            readonly property int pageIndex: Math.floor(colDelegate.colIndex / forecastSection.visibleCols)
                            readonly property int colInPage: colDelegate.colIndex % forecastSection.visibleCols
                            readonly property int logicalDayIndex: (pageIndex * forecastSection.daysPerPage) + (index * forecastSection.visibleCols) + colInPage
                            visible: logicalDayIndex < rootItem.availableDayCount

                            readonly property int dayIndex: logicalDayIndex + root.forecastStartDay
                            property alias iconItem: hitArea

                            readonly property bool isCurrentDay: dayIndex === rootItem.currentDayIndex
                            readonly property bool isInteractive: rootItem.hasHourlyData && rootItem.anyChartEnabled

                            Item {
                                id: hitArea
                                z: 3

                                // 0 = Large : toute la colonne (comportement historique).
                                // 1 = Moyen : rectangle centré, juste assez large/haut pour le jour + l'icône + min/max
                                //     (pas toute la largeur de la colonne, ne mord jamais sur la colonne voisine).
                                // 2 = Petit : uniquement le cercle bleuté de l'icône.
                                readonly property int zoneMode: rootItem.forecastHoverZoneSize

                                // Largeur du mode Moyen : carré centré sur l'icône météo, dont le côté est
                                // égal à la hauteur de la zone (déjà correcte), plafonné pour ne jamais
                                // mordre sur la zone de détection du jour voisin.
                                readonly property real mediumMaxWidth: parent.width - Kirigami.Units.gridUnit * 0.4
                                readonly property real mediumWidth: Math.min(contentColumn.height, mediumMaxWidth)

                                // hitArea est un enfant direct de dayCell, mais iconWrapper/hoverCircle sont imbriqués
                                // deux niveaux plus bas (dans contentColumn). On ne peut pas les ANCRER directement
                                // (ancres = parent/frère direct uniquement en QML), donc on recompose leur position
                                // absolue via de simples lectures de propriétés (x/y/width/height), qui elles restent
                                // pleinement réactives quel que soit le niveau d'imbrication.
                                readonly property real iconAbsX: contentColumn.x + iconWrapper.x + hoverCircle.x
                                readonly property real iconAbsY: contentColumn.y + iconWrapper.y + hoverCircle.y

                                x: zoneMode === 2 ? iconAbsX : (zoneMode === 1 ? (parent.width - mediumWidth) / 2 : 0)
                                y: zoneMode === 2 ? iconAbsY : (zoneMode === 1 ? contentColumn.y : 0)
                                width:  zoneMode === 2 ? hoverCircle.width  : (zoneMode === 1 ? mediumWidth          : parent.width)
                                height: zoneMode === 2 ? hoverCircle.height : (zoneMode === 1 ? contentColumn.height : parent.height)

                                MouseArea {
                                    id: dayMouse
                                    anchors.fill: parent
                                    hoverEnabled: dayCell.isInteractive
                                    enabled: dayCell.isInteractive
                                    cursorShape: dayCell.isInteractive ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    onClicked: rootItem.openDayDetail(dayCell.dayIndex)

                                    PlasmaComponents3.ToolTip {
                                        visible: dayMouse.containsMouse
                                        delay: 500
                                        text: i18n("Click for hourly details")
                                    }
                                }
                            }

                            ColumnLayout {
                                id: contentColumn
                                width: parent.width
                                anchors.verticalCenter: parent.verticalCenter
                                // Décalage direct (voir forecastCenterOffset plus haut dans le fichier) :
                                // négatif = vers le haut en QML (axe Y vers le bas). Limité au cas 1 seule
                                // rangée visible (celui de la capture) : avec plusieurs rangées, chaque
                                // cellule est déjà plus petite et ce décalage romprait l'alignement entre
                                // elles. S'applique en Popup ET en Bureau (voir la note sur forecastCenterOffset).
                                anchors.verticalCenterOffset: forecastSection.visibleRows === 1 ? -rootItem.forecastCenterOffset : 0
                                spacing: 0

                                PlasmaComponents3.Label {
                                    id: dayLabel
                                    Layout.fillWidth: true
                                    text: {
                                        if (rootItem.dailyData && rootItem.dailyData.time) {
                                            let d = new Date(rootItem.dailyData.time[dayCell.dayIndex]);
                                            return root.days ? root.days[d.getDay()] : "";
                                        }
                                        return "";
                                    }
                                    horizontalAlignment: Text.AlignHCenter
                                    font.capitalization: Font.Capitalize
                                    font.pixelSize: Kirigami.Units.gridUnit * 0.65
                                    opacity: 0.8
                                    color: Kirigami.Theme.textColor
                                }

                                Item {
                                    id: iconWrapper
                                    readonly property real maxIconSize: Kirigami.Units.gridUnit * 2.7
                                    readonly property real widthBasedSize: dayCell.width * 0.7
                                    readonly property real iconSize: Math.max(Kirigami.Units.gridUnit * 1.2, Math.min(maxIconSize, widthBasedSize))

                                    Layout.preferredWidth: iconSize
                                    Layout.preferredHeight: iconSize
                                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter

                                    readonly property int displayedCode: {
                                        if (dayCell.isCurrentDay && weatherData && weatherData.weatherCode !== undefined && weatherData.weatherCode !== "--") {
                                            return parseInt(weatherData.weatherCode);
                                        }
                                        return (rootItem.dailyData && rootItem.dailyData.weather_code) ? rootItem.dailyData.weather_code[dayCell.dayIndex] : null;
                                    }

                                    Rectangle {
                                        id: hoverCircle
                                        anchors.centerIn: parent
                                        width: parent.iconSize * (3.0 / 2.7)
                                        height: width
                                        radius: width / 2
                                        color: rootItem.isDarkTheme ? Kirigami.Theme.textColor : Kirigami.Theme.highlightColor
                                        readonly property bool isHovered: dayCell.isInteractive && forecastHoverMouse.hoveredIconRef === hitArea
                                        opacity: isHovered ? (dayMouse.pressed ? (rootItem.isDarkTheme ? 0.28 : 0.22) : (rootItem.isDarkTheme ? 0.16 : 0.13)) : 0
                                        Behavior on opacity { NumberAnimation { duration: 150 } }
                                    }

                                    Kirigami.Icon {
                                        anchors.centerIn: parent
                                        width: parent.iconSize
                                        height: width
                                        source: (rootItem.dailyData && iconWrapper.displayedCode !== null) ? weatherData.assignIcon(iconWrapper.displayedCode) : ""
                                    }
                                }

                                RowLayout {
                                    id: tempRow
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 4
                                    PlasmaComponents3.Label {
                                        text: rootItem.dailyData ? Math.round(rootItem.dailyData.temperature_2m_max[dayCell.dayIndex]) + "°" : ""
                                        font.bold: true
                                        font.pixelSize: Kirigami.Units.gridUnit * 0.75
                                        color: Kirigami.Theme.textColor
                                    }
                                    PlasmaComponents3.Label {
                                        text: rootItem.dailyData ? Math.round(rootItem.dailyData.temperature_2m_min[dayCell.dayIndex]) + "°" : ""
                                        opacity: 0.6
                                        font.pixelSize: Kirigami.Units.gridUnit * 0.75
                                        color: Kirigami.Theme.textColor
                                    }
                                }
                            }
                        }
                    }
                }
            }

            RowLayout {
                id: detailsRow
                visible: !!showBottomDetails
                Layout.fillWidth: true
                // Hauteur fixe restaurée à sa valeur d'origine (celle de v0), pour garder
                // la hauteur totale du popup identique à v0 — voir calculatedHeight, qui
                // dérive TOUT le reste de la somme des enfants de classicContent : réduire
                // cette valeur réduit le popup entier, ce n'était pas l'effet demandé.
                // Le contenu (label + valeur) était par défaut aligné en HAUT de cette
                // boîte, laissant tout l'espace libre en dessous — d'où l'impression que
                // le texte "restait trop haut". Fix : Qt.AlignBottom sur le delegate du
                // Repeater plus bas (pas ici) pousse le contenu vers le BAS de cette même
                // boîte, sans changer sa hauteur ni celle du popup.
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2.2
                // Même logique de protection que headerSection.Layout.minimumHeight ci-dessus :
                // par précaution, empêche aussi detailsRow d'être compressé sous sa hauteur
                // nécessaire quand l'espace vertical manque (c'est forecastSection, avec son
                // fillHeight, qui doit céder de la place en premier).
                Layout.minimumHeight: Layout.preferredHeight
                // Popup : popupSideMargin, la MÊME valeur que headerSection (au lieu de
                // 0.5 gridUnit ici vs 1 gridUnit sur le header, incohérent). Bureau inchangé.
                Layout.leftMargin: rootItem.isDesktopMode ? Kirigami.Units.gridUnit * 0.5 : rootItem.popupSideMargin
                Layout.rightMargin: rootItem.isDesktopMode ? Kirigami.Units.gridUnit * 0.5 : rootItem.popupSideMargin

                // Bureau : symétrie verticale existante (voir desktopVerticalBreathing), inchangée.
                // Popup : popupEdgeMargin, la MÊME valeur que headerSection.topMargin plus haut
                // → "bord bas → text detail" symétrique à "bord haut → température", et le
                // text detail descend enfin jusqu'à sa vraie place (plus de vide résiduel
                // sous lui, voir calculatedHeight qui suit désormais le contenu réel).
                Layout.bottomMargin: rootItem.isDesktopMode ? Kirigami.Units.smallSpacing * rootItem.desktopVerticalBreathing : rootItem.popupEdgeMargin

                spacing: Kirigami.Units.smallSpacing

                readonly property var visibleDetails: rootItem.buildDetailEntries(
                    rootItem.detailsOrderIds, "bottomRowLabelKey")

                Repeater {
                    model: detailsRow.visibleDetails
                    delegate: RowLayout {
                        Layout.fillWidth: true
                        // Pousse le contenu (divider + DetailValueColumn) vers le BAS de la
                        // hauteur fixe de detailsRow (voir la note sur Layout.preferredHeight
                        // plus haut) : sans alignement explicite, RowLayout aligne ses enfants
                        // en haut par défaut, laissant tout l'espace libre sous le texte.
                        // Qt.AlignBottom (essayé d'abord) collait le texte tout en bas de la
                        // boîte — trop bas. Qt.AlignVCenter répartit l'espace libre pour
                        // moitié au-dessus, pour moitié en dessous : décalage plus modéré.
                        Layout.alignment: Qt.AlignVCenter
                        Layout.topMargin: rootItem.detailsRowVerticalNudge
                        spacing: Kirigami.Units.smallSpacing
                        Rectangle {
                            visible: index > 0
                            Layout.preferredWidth: 1
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 1.2
                            color: Kirigami.Theme.textColor
                            opacity: 0.15
                            Layout.alignment: Qt.AlignVCenter
                        }
                        DetailValueColumn {
                            label: modelData.label
                            value: modelData.value
                        }
                    }
                }
            }
        }

        // ============================================================
        // === VUE DÉTAIL ===
        // ============================================================
        ColumnLayout {
            id: dayDetailView
            anchors.fill: parent
            spacing: 0

            opacity: rootItem.selectedDayIndex !== -1 ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            readonly property string dayLabelFull: {
                if (!rootItem.dailyData || rootItem.selectedDayIndex < 0) return "";
                let d = new Date(rootItem.dailyData.time[rootItem.selectedDayIndex]);
                let locale = Qt.locale();
                return d.toLocaleString(locale, "dddd");
            }

            readonly property var activeDef: (rootItem.chartDefs.length > 0)
            ? rootItem.chartDefs[Math.min(rootItem.activeChart, rootItem.chartDefs.length - 1)]
            : { field: "", label: "", unit: "", color: Kirigami.Theme.textColor, chartType: 0 }
            readonly property var activeValues: rootItem.hourlySlice(activeDef.field)
            readonly property string activeUnit: activeDef.unit
            readonly property string activeLabel: activeDef.label
            readonly property color activeColor: activeDef.color

            // Série secondaire (overlay pluie % + mm) : absente (undefined) sur tous
            // les charts normaux, donc ces propriétés retombent proprement sur des
            // valeurs vides/neutres qui laissent LineChart en mode simple série.
            readonly property var activeSecondaryValues: activeDef.secondaryField ? rootItem.hourlySlice(activeDef.secondaryField) : []
            readonly property string activeSecondaryLabel: activeDef.secondaryLabel || ""
            readonly property string activeSecondaryUnit: activeDef.secondaryUnit || ""
            readonly property color activeSecondaryColor: activeDef.secondaryColor || Kirigami.Theme.textColor
            readonly property bool activeSecondaryDecimals: !!activeDef.secondaryDecimals
            readonly property int activeSecondaryChartType: activeDef.secondaryChartType !== undefined ? activeDef.secondaryChartType : -1

            RowLayout {
                id: navigationHeader
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.smallSpacing
                Layout.leftMargin: Kirigami.Units.smallSpacing
                Layout.rightMargin: Kirigami.Units.smallSpacing
                spacing: 0

                Item {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 1.6
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 1.6

                    Rectangle {
                        anchors.centerIn: parent
                        // Légèrement plus petit que la zone cliquable (parent.width/height) pour
                        // que le cercle sombre au clic/survol ne remplisse pas tout le carré de
                        // 1.6 gridUnit : marge de respiration tout autour, purement visuelle.
                        width: parent.width * 0.8
                        height: parent.height * 0.8
                        radius: width / 2
                        color: Kirigami.Theme.textColor
                        opacity: backMouse.pressed ? 0.15 : (backMouse.containsMouse ? 0.08 : 0.0)
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: Kirigami.Units.gridUnit * 1.0
                        height: Kirigami.Units.gridUnit * 1.0
                        source: "go-previous"
                        opacity: backMouse.pressed ? 0.6 : (backMouse.containsMouse ? 1.0 : 0.75)
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                    MouseArea {
                        id: backMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: rootItem.closeDayDetail()
                    }
                }

                PlasmaComponents3.Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    font.bold: true
                    font.capitalization: Font.Capitalize
                    text: dayDetailView.dayLabelFull
                    color: Kirigami.Theme.textColor
                }

                Item {
                    Layout.preferredWidth: Kirigami.Units.gridUnit * 1.6
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 1.6
                }
            }

            Components.LineChart {
                id: dayLineChart
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.leftMargin: Kirigami.Units.smallSpacing
                Layout.rightMargin: Kirigami.Units.smallSpacing
                Layout.bottomMargin: Kirigami.Units.smallSpacing

                label:       dayDetailView.activeLabel
                unit:        dayDetailView.activeUnit
                values:      dayDetailView.activeValues
                lineColor:   dayDetailView.activeColor
                isToday:     rootItem.selectedDayIndex === rootItem.currentDayIndex
                viewActive:  rootItem.selectedDayIndex !== -1

                secondaryValues:   dayDetailView.activeSecondaryValues
                secondaryLabel:    dayDetailView.activeSecondaryLabel
                secondaryUnit:     dayDetailView.activeSecondaryUnit
                secondaryColor:    dayDetailView.activeSecondaryColor
                secondaryDecimals: dayDetailView.activeSecondaryDecimals
                secondaryChartType: dayDetailView.activeSecondaryChartType

                preciseTemp: root.yAxisDecimals
                chartType:   dayDetailView.activeDef.chartType
                yAxisReadingEnabled: root.interactiveYAxis
                hoverDecimals: root.hoverDecimals
                xAxisPrecision: root.xAxisPrecision
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Kirigami.Units.smallSpacing
                Layout.rightMargin: Kirigami.Units.smallSpacing
                Layout.bottomMargin: Kirigami.Units.smallSpacing
                spacing: Kirigami.Units.smallSpacing

                component ChartTab : Rectangle {
                    property string tabLabel: ""
                    property int tabIndex: 0
                    property color tabColor: Kirigami.Theme.highlightColor

                    Layout.fillWidth: true
                    Layout.preferredHeight: Kirigami.Units.gridUnit * 1.4
                    radius: Kirigami.Units.smallSpacing

                    readonly property bool isActive: rootItem.activeChart === tabIndex
                    color: isActive ? Qt.rgba(tabColor.r, tabColor.g, tabColor.b, 0.20) : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.06)
                    Behavior on color { ColorAnimation { duration: 150 } }

                    Rectangle {
                        visible: parent.isActive
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 3
                        height: 2
                        radius: 1
                        color: parent.tabColor
                    }

                    PlasmaComponents3.Label {
                        anchors.centerIn: parent
                        text: parent.tabLabel
                        font.pixelSize: Kirigami.Units.gridUnit * 0.52
                        font.bold: parent.isActive
                        color: parent.isActive ? parent.tabColor : Kirigami.Theme.textColor
                        opacity: parent.isActive ? 1.0 : 0.55
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }

                    TapHandler {
                        onTapped: rootItem.activeChart = parent.tabIndex
                    }
                }

                Repeater {
                    model: rootItem.chartDefs
                    delegate: ChartTab {
                        tabLabel: modelData.tabLabel
                        tabIndex: index
                        tabColor: modelData.color
                    }
                }
            }
        }
    }

    component DetailValueColumn : ColumnLayout {
        property string label: ""
        property string value: ""
        property bool compact: false

        spacing: 1
        // Avant : Layout.fillWidth: !compact — la grille compacte du header ne pouvait donc
        // jamais s'étaler, même une fois son parent (detailsGrid) passé en fillWidth ci-dessus.
        Layout.fillWidth: true
        Layout.preferredWidth: compact ? Kirigami.Units.gridUnit * 2.2 : rootItem.detailMinColumnWidth

        readonly property real labelSize: compact ? Kirigami.Units.gridUnit * 0.50 : Kirigami.Units.gridUnit * 0.52
        readonly property real labelOpacity: compact ? 0.55 : 0.60
        readonly property real numSize: compact ? Kirigami.Units.gridUnit * 0.68 : Kirigami.Units.gridUnit * 0.72
        readonly property real degreeSuperSize: compact ? Kirigami.Units.gridUnit * 0.45 : Kirigami.Units.gridUnit * 0.48
        readonly property real degreeUnitSize: compact ? Kirigami.Units.gridUnit * 0.52 : Kirigami.Units.gridUnit * 0.55
        readonly property real percentSize: compact ? Kirigami.Units.gridUnit * 0.48 : Kirigami.Units.gridUnit * 0.54
        readonly property real speedSize: compact ? Kirigami.Units.gridUnit * 0.50 : Kirigami.Units.gridUnit * 0.53
        readonly property real degreeSuperLeftPadding: compact ? 1.2 : 0
        readonly property real degreeUnitLeftPadding: compact ? -0.5 : 0.5
        readonly property real speedBaselineOffset: compact ? -0.5 : -0.2

        PlasmaComponents3.Label {
            text: parent.label
            font.pixelSize: parent.labelSize
            opacity: parent.labelOpacity
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            color: Kirigami.Theme.textColor
        }

        Row {
            Layout.alignment: Qt.AlignHCenter
            spacing: 0
            readonly property var _split: {
                let v = parent.value;
                let m = v.match(/^(-?\d+(?:\.\d+)?)\s*(.+)$/);
                return m ? { num: m[1], unit: m[2] } : { num: v, unit: "" };
            }
            readonly property string _unitType: {
                let u = _split.unit;
                if (u === "°C" || u === "°F") return "degree";
                if (u === "K") return "kelvin";
                if (u === "%") return "percent";
                return "speed";
            }
            PlasmaComponents3.Label {
                id: numLabel
                text: parent._split.num
                font.pixelSize: parent.parent.numSize
                font.bold: true
                color: Kirigami.Theme.textColor
            }
            PlasmaComponents3.Label {
                visible: parent._unitType === "degree"
                text: parent._split.unit.charAt(0)
                font.pixelSize: parent.parent.degreeSuperSize
                font.bold: true
                leftPadding: parent.parent.degreeSuperLeftPadding
                anchors.top: numLabel.top
                anchors.topMargin: 1
                color: Kirigami.Theme.textColor
            }
            PlasmaComponents3.Label {
                visible: parent._unitType === "degree"
                text: parent._split.unit.substring(1)
                font.pixelSize: parent.parent.degreeUnitSize
                font.bold: true
                leftPadding: parent.parent.degreeUnitLeftPadding
                anchors.top: numLabel.top
                anchors.topMargin: parent.parent.compact ? 2.25 : 2
                color: Kirigami.Theme.textColor
            }
            PlasmaComponents3.Label {
                visible: parent._unitType === "kelvin"
                text: parent._split.unit
                font.pixelSize: parent.parent.degreeUnitSize
                font.bold: true
                leftPadding: parent.parent.compact ? 1.5 : 1
                anchors.top: numLabel.top
                anchors.topMargin: parent.parent.compact ? 2.25 : 2
                color: Kirigami.Theme.textColor
            }
            PlasmaComponents3.Label {
                visible: parent._unitType === "percent"
                text: parent._split.unit
                font.pixelSize: parent.parent.percentSize
                font.bold: true
                leftPadding: parent.parent.compact ? 3 : 2
                anchors.verticalCenter: numLabel.verticalCenter
                color: Kirigami.Theme.textColor
            }
            PlasmaComponents3.Label {
                visible: parent._unitType === "speed"
                text: parent._split.unit
                font.pixelSize: parent.parent.speedSize
                font.bold: true
                leftPadding: 2
                anchors.baseline: numLabel.baseline
                anchors.baselineOffset: parent.parent.speedBaselineOffset
                color: Kirigami.Theme.textColor
            }
        }
    }
}
