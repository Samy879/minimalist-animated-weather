import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import "."

Item {
    id: supportPage

    implicitWidth:  Kirigami.Units.gridUnit * 46
    implicitHeight: Kirigami.Units.gridUnit * 40

    Layout.minimumWidth: Kirigami.Units.gridUnit * 32
    Layout.minimumHeight: Kirigami.Units.gridUnit * 24

    readonly property real contentMaxWidth: Kirigami.Units.gridUnit * 44
    readonly property real fieldRadius: Kirigami.Units.smallSpacing * 1.3
    readonly property real logoCenterOffset: Kirigami.Units.gridUnit * 1.0 / 2

    property bool titleError: false
    property bool bodyError: false

    property bool hasRated: false
    property bool hasStarred: false

    // Largeur de contenu réellement nécessaire pour "Rate"/"Star" (traduits),
    // calculée à partir du texte le plus long des deux boutons + la place de
    // l'icône cœur, pour que les deux boutons restent identiques et que le
    // texte ne soit jamais recouvert par le cœur.
    readonly property real supportButtonContentWidth: Math.max(rateLabel.implicitWidth, starLabel.implicitWidth)
    + Kirigami.Units.iconSizes.small
    + Kirigami.Units.largeSpacing   // marge droite de l'icône
    + Kirigami.Units.smallSpacing   // marge entre texte et icône
    + Kirigami.Units.largeSpacing   // paddings gauche/droite du bouton
    readonly property real supportButtonWidth: Math.min(
        Math.max(supportButtonContentWidth, Kirigami.Units.gridUnit * 4.4),
                                                        Kirigami.Units.gridUnit * 9)

    property string firstUnlockedType: ""
    readonly property string leftEffectType: supportPage.firstUnlockedType !== "" ? supportPage.firstUnlockedType : "rate"
    readonly property string rightEffectType: supportPage.leftEffectType === "rate" ? "star" : "rate"

    property bool cfg_shootingStarEffect: false
    property bool cfg_rainbowEffect: false
    // --- Alias muets : évite les "does not have a property called cfg_x" ---
    // (KDE tente d'initialiser TOUTES les clés de main.xml sur CHAQUE page de config)
    // Propriétés cfg_ non utilisées par cette page :
    property var cfg_useCoordinatesIp: undefined
    property var cfg_latitudeC: undefined
    property var cfg_longitudeC: undefined
    property var cfg_showConditionPanel: undefined
    property var cfg_showConditionExpanded: undefined
    property var cfg_conditionAlignment: undefined
    property var cfg_reverseOrder: undefined
    property var cfg_temperatureUnit: undefined
    property var cfg_temperatureFontSize: undefined
    property var cfg_conditionFontSize: undefined
    property var cfg_showTemperaturePanel: undefined
    property var cfg_preciseTemp: undefined
    property var cfg_yAxisDecimals: undefined
    property var cfg_updateInterval: undefined
    property var cfg_forecastStartDay: undefined
    property var cfg_temperaturePanelBold: undefined
    property var cfg_conditionPanelBold: undefined
    property bool cfg_showAnimations: false // Utilisée pour griser les effets débloqués ci-dessous
    property var cfg_refreshTrigger: undefined
    property var cfg_borderRadius: undefined
    property var cfg_backgroundOpacity: undefined
    property var cfg_interactiveYAxis: undefined
    property var cfg_hoverDecimals: undefined
    property var cfg_xAxisPrecision: undefined
    property var cfg_weatherProvider: undefined
    property var cfg_apiKeyWeatherApi: undefined
    property var cfg_apiKeyTomorrow: undefined
    property var cfg_apiKeyOpenWeatherMap: undefined
    property var cfg_apiKeyVisualCrossing: undefined
    property var cfg_apiKeyPirateWeather: undefined
    property var cfg_providerMaxForecastDays: undefined
    property var cfg_detailsOrder: undefined
    property var cfg_chartsOrder: undefined
    property var cfg_forecastDayCount: undefined
    property var cfg_hasRated: undefined
    property var cfg_hasStarred: undefined
    // Contreparties "Default" (générées par KConfigXT), jamais utilisées par nos pages :
    property var cfg_useCoordinatesIpDefault: undefined
    property var cfg_latitudeCDefault: undefined
    property var cfg_longitudeCDefault: undefined
    property var cfg_showLocationExpanded: undefined
    property var cfg_showConditionPanelDefault: undefined
    property var cfg_showLocationExpandedDefault: undefined
    property var cfg_showConditionExpandedDefault: undefined
    property var cfg_conditionAlignmentDefault: undefined
    property var cfg_reverseOrderDefault: undefined
    property var cfg_temperatureUnitDefault: undefined
    property var cfg_temperatureFontSizeDefault: undefined
    property var cfg_conditionFontSizeDefault: undefined
    property var cfg_showTemperaturePanelDefault: undefined
    property var cfg_preciseTempDefault: undefined
    property var cfg_yAxisDecimalsDefault: undefined
    property var cfg_updateIntervalDefault: undefined
    property var cfg_forecastStartDayDefault: undefined
    property var cfg_temperaturePanelBoldDefault: undefined
    property var cfg_conditionPanelBoldDefault: undefined
    property var cfg_showAnimationsDefault: undefined
    property var cfg_refreshTriggerDefault: undefined
    property var cfg_borderRadiusDefault: undefined
    property var cfg_backgroundOpacityDefault: undefined
    property var cfg_interactiveYAxisDefault: undefined
    property var cfg_hoverDecimalsDefault: undefined
    property var cfg_xAxisPrecisionDefault: undefined
    property var cfg_weatherProviderDefault: undefined
    property var cfg_apiKeyWeatherApiDefault: undefined
    property var cfg_apiKeyTomorrowDefault: undefined
    property var cfg_apiKeyOpenWeatherMapDefault: undefined
    property var cfg_apiKeyVisualCrossingDefault: undefined
    property var cfg_apiKeyPirateWeatherDefault: undefined
    property var cfg_providerMaxForecastDaysDefault: undefined
    property var cfg_detailsOrderDefault: undefined
    property var cfg_chartsOrderDefault: undefined
    property var cfg_forecastDayCountDefault: undefined
    property var cfg_hasRatedDefault: undefined
    property var cfg_hasStarredDefault: undefined
    property var cfg_shootingStarEffectDefault: undefined
    property var cfg_rainbowEffectDefault: undefined
    property string title: ""

    property string thanksText: ""

    readonly property int thanksTotalDuration: 1650

    function githubIconDataUrl(color) {
        var svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path fill="' + color + '" d="M12 .297c-6.63 0-12 5.373-12 12 0 5.303 3.438 9.8 8.205 11.385.6.113.82-.258.82-.577 0-.285-.01-1.04-.015-2.04-3.338.724-4.042-1.61-4.042-1.61-.546-1.387-1.333-1.757-1.333-1.757-1.09-.744.083-.729.083-.729 1.205.084 1.84 1.238 1.84 1.238 1.07 1.834 2.807 1.304 3.492.997.108-.775.42-1.305.763-1.605-2.665-.303-5.467-1.334-5.467-5.93 0-1.31.468-2.38 1.235-3.22-.123-.303-.535-1.523.117-3.176 0 0 1.008-.322 3.3 1.23.957-.266 1.983-.399 3.003-.404 1.02.005 2.047.138 3.006.404 2.29-1.552 3.297-1.23 3.297-1.23.653 1.653.24 2.873.117 3.176.77.84 1.233 1.91 1.233 3.22 0 4.61-2.807 5.624-5.48 5.92.432.372.816 1.103.816 2.222 0 1.606-.015 2.898-.015 3.293 0 .32.216.694.825.576C20.565 22.092 24 17.592 24 12.297c0-6.627-5.373-12-12-12"/></svg>';
        return "data:image/svg+xml;utf8," + encodeURIComponent(svg);
    }

    function starIconDataUrl(color) {
        var svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path fill="' + color + '" d="M12 .587l3.668 7.568 8.332 1.151-6.064 5.828 1.48 8.279L12 19.771l-7.416 3.642 1.48-8.279L0 9.306l8.332-1.151z"/></svg>';
        return "data:image/svg+xml;utf8," + encodeURIComponent(svg);
    }

    function downloadIconDataUrl(color) {
        var svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path fill="' + color + '" d="M12 3a1 1 0 0 1 1 1v9.086l2.793-2.793a1 1 0 1 1 1.414 1.414l-4.5 4.5a1 1 0 0 1-1.414 0l-4.5-4.5a1 1 0 1 1 1.414-1.414L11 13.086V4a1 1 0 0 1 1-1zM5 18a1 1 0 0 1 1 1v1h12v-1a1 1 0 1 1 2 0v2a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1v-2a1 1 0 0 1 1-1z"/></svg>';
        return "data:image/svg+xml;utf8," + encodeURIComponent(svg);
    }

    function heartIconDataUrl(color) {
        var svg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><path fill="' + color + '" d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/></svg>';
        return "data:image/svg+xml;utf8," + encodeURIComponent(svg);
    }

    function colorToHex(c) {
        function toHex(v) {
            var h = Math.round(Math.max(0, Math.min(1, v)) * 255).toString(16);
            return h.length === 1 ? "0" + h : h;
        }
        return "#" + toHex(c.r) + toHex(c.g) + toHex(c.b);
    }

    property var stargazers: []
    property int stargazersCount: 0
    property bool stargazersLoading: true
    property bool stargazersError: false

    property var storeReviews: []
    property bool reviewsLoading: true
    property bool reviewsError: false

    readonly property var ratedReviews: supportPage.storeReviews.filter(function(r) { return r.rating > 0; })

    property int downloadsCount: 0
    property bool downloadsLoading: true
    property bool downloadsError: false

    function fetchStargazers() {
        supportPage.stargazersLoading = true;
        supportPage.stargazersError = false;

        let listReq = new XMLHttpRequest();
        listReq.onreadystatechange = function() {
            if (listReq.readyState !== XMLHttpRequest.DONE) return;
            supportPage.stargazersLoading = false;
            if (listReq.status === 200) {
                try {
                    let data = JSON.parse(listReq.responseText);
                    supportPage.stargazers = data;
                    if (supportPage.stargazersCount === 0) {
                        supportPage.stargazersCount = data.length;
                    }
                } catch (e) {
                    supportPage.stargazersError = true;
                }
            } else {
                supportPage.stargazersError = true;
            }
        };
        listReq.open("GET", "https://raw.githubusercontent.com/Samy879/minimalist-animated-weather/data/stargazers.json?_=" + Date.now());
        listReq.setRequestHeader("Accept", "application/vnd.github+json");
        listReq.setRequestHeader("Cache-Control", "no-cache");
        listReq.send();

        let countReq = new XMLHttpRequest();
        countReq.onreadystatechange = function() {
            if (countReq.readyState !== XMLHttpRequest.DONE || countReq.status !== 200) return;
            try {
                let repoData = JSON.parse(countReq.responseText);
                if (typeof repoData.stargazers_count === "number") {
                    supportPage.stargazersCount = repoData.stargazers_count;
                }
            } catch (e) {}
        };
        countReq.open("GET", "https://raw.githubusercontent.com/Samy879/minimalist-animated-weather/data/repo.json?_=" + Date.now());
        countReq.setRequestHeader("Accept", "application/vnd.github+json");
        countReq.setRequestHeader("Cache-Control", "no-cache");
        countReq.send();
    }

    function fetchStoreReviews() {
        supportPage.reviewsLoading = true;
        supportPage.reviewsError = false;

        let req = new XMLHttpRequest();
        req.onreadystatechange = function() {
            if (req.readyState !== XMLHttpRequest.DONE) return;
            supportPage.reviewsLoading = false;
            if (req.status === 200) {
                try {
                    let data = JSON.parse(req.responseText);
                    let list = [];
                    for (let i = 0; i < data.length; i++) {
                        let c = data[i] && data[i].comment;
                        if (!c || !c.comment_text_raw) continue;
                        list.push({
                            username: c.username || i18n("Anonymous"),
                                  rating: (function() {
                                      let r = parseFloat(c.rating);
                                      return (!isNaN(r) && r > 0) ? r : -1;
                                  })(),
                                  text: c.comment_text_raw
                        });
                    }
                    supportPage.storeReviews = list;
                } catch (e) {
                    supportPage.reviewsError = true;
                }
            } else {
                supportPage.reviewsError = true;
            }
        };
        req.open("GET", "https://store.kde.org/products/comments/list?p=2356087");
        req.send();
    }

    function fetchDownloadCount() {
        supportPage.downloadsLoading = true;
        supportPage.downloadsError = false;

        let req = new XMLHttpRequest();
        req.onreadystatechange = function() {
            if (req.readyState !== XMLHttpRequest.DONE) return;
            supportPage.downloadsLoading = false;
            if (req.status === 200) {
                try {
                    let data = JSON.parse(req.responseText);
                    let files = (data && data.files) || [];
                    let total = 0;
                    for (let i = 0; i < files.length; i++) {
                        total += files[i].downloaded_count_uk || 0;
                    }
                    supportPage.downloadsCount = total;
                } catch (e) {
                    supportPage.downloadsError = true;
                }
            } else {
                supportPage.downloadsError = true;
            }
        };
        req.open("GET", "https://store.kde.org/p/2356087/loadFiles");
        req.send();
    }

    function showThanks(text) {
        supportPage.thanksText = text;
        thanksPopupTimer.restart();
    }

    function handleSupportClick(type, url) {
        let alreadyUnlocked = supportPage.hasRated && supportPage.hasStarred;

        if (supportPage.firstUnlockedType === "") {
            supportPage.firstUnlockedType = type;
        }

        if (type === "rate") {
            plasmoid.configuration.hasRated = true;
            supportPage.hasRated = true;
        } else {
            plasmoid.configuration.hasStarred = true;
            supportPage.hasStarred = true;
        }

        let redirectTimer = type === "rate" ? rateRedirectTimer : starRedirectTimer;
        redirectTimer.url = url;

        let justUnlocked = !alreadyUnlocked && supportPage.hasRated && supportPage.hasStarred;

        if (justUnlocked) {
            celebrationOverlay.play(i18n("Thank you for your support!"), i18n("Every star and review helps the project grow."));
            redirectTimer.interval = celebrationOverlay.totalDuration;
        } else {
            supportPage.showThanks(type === "rate" ? i18n("Thank you for your rating!") : i18n("Thank you for the star!"));
            redirectTimer.interval = supportPage.thanksTotalDuration;
        }

        redirectTimer.restart();
    }

    Timer {
        id: rateRedirectTimer
        property string url: ""
        repeat: false
        onTriggered: { if (url.length > 0) { Qt.openUrlExternally(url); url = ""; } }
    }
    Timer {
        id: starRedirectTimer
        property string url: ""
        repeat: false
        onTriggered: { if (url.length > 0) { Qt.openUrlExternally(url); url = ""; } }
    }

    property var activeField: null

    function checkFormErrors() {
        if (feedbackTitle.text.trim() !== "" && feedbackInput.text.trim() !== "") {
            formErrorMsg.visible = false;
        }
    }

    function submitFeedback(method) {
        let isValid = true;
        if (feedbackTitle.text.trim() === "") { supportPage.titleError = true; isValid = false; }
        if (feedbackInput.text.trim() === "") { supportPage.bodyError = true; isValid = false; }

        if (!isValid) {
            formErrorMsg.visible = true;
            return;
        }

        formErrorMsg.visible = false;

        let prefix = feedbackTypeCombo.currentIndex === 2 ? "Bug:" : (feedbackTypeCombo.currentIndex === 1 ? "Improvement:" : "Suggestion:");
        let title = encodeURIComponent(prefix + " " + feedbackTitle.text);
        let body = encodeURIComponent(feedbackInput.text);

        if (method === "github") {
            let label = feedbackTypeCombo.currentIndex === 2 ? "bug" : "enhancement";
            let url = "https://github.com/Samy879/minimalist-animated-weather/issues/new?labels=" + label + "&title=" + title + "&body=" + body;
            Qt.openUrlExternally(url);
        } else {
            let url = "mailto:samy.rk800@gmail.com?subject=" + title + "&body=" + body;
            Qt.openUrlExternally(url);
        }

        feedbackThanksMsg.visible = true;
        feedbackThanksTimer.restart();
    }

    function toggleFormat(kind) {
        let target = supportPage.activeField || feedbackInput;
        if (!target || target === feedbackTitle) return;

        let start = target.selectionStart;
        let end = target.selectionEnd;
        let marker = kind === "bold" ? "**" : (kind === "italic" ? "*" : "~~");
        let mLen = marker.length;

        if (start === end) {
            target.insert(start, marker + marker);
            target.cursorPosition = start + mLen;
            target.forceActiveFocus();
            return;
        }

        let selectedText = target.selectedText;
        let removeLen = 0;

        if (kind === "strike" && selectedText.startsWith("~~") && selectedText.endsWith("~~")) {
            removeLen = 2;
        } else if (kind === "bold" || kind === "italic") {
            let m = selectedText.match(/^(\*+)(.*?)(\*+)$/);
            if (m) {
                let leftStars = m[1].length;
                let rightStars = m[3].length;
                if (kind === "bold" && leftStars >= 2 && rightStars >= 2) {
                    removeLen = 2;
                } else if (kind === "italic" && leftStars % 2 !== 0 && rightStars % 2 !== 0) {
                    removeLen = 1;
                }
            }
        }

        if (removeLen > 0) {
            let newText = selectedText.substring(removeLen, selectedText.length - removeLen);
            target.remove(start, end);
            target.insert(start, newText);
            target.select(start, start + newText.length);
            target.forceActiveFocus();
            return;
        }

        target.remove(start, end);
        target.insert(start, marker + selectedText + marker);
        target.select(start + mLen, start + mLen + selectedText.length);
        target.forceActiveFocus();
    }

    function insertList(type) {
        let target = supportPage.activeField || feedbackInput;
        if (!target || target === feedbackTitle) return;

        let start = target.selectionStart;
        let end = target.selectionEnd;
        let prefix = type === "bullet" ? "- " : "1. ";

        if (start === end) {
            let text = target.text;
            let before = text.substring(0, start);
            let needsNewline = before.length > 0 && !before.endsWith('\n');
            let insertStr = (needsNewline ? "\n" : "") + prefix;
            target.insert(start, insertStr);
            target.cursorPosition = start + insertStr.length;
        } else {
            let selectedText = target.selectedText;
            let lines = selectedText.split('\n');
            for (let i = 0; i < lines.length; i++) {
                let p = type === "bullet" ? "- " : (i + 1) + ". ";
                lines[i] = p + lines[i];
            }
            let newText = lines.join('\n');
            target.remove(start, end);
            target.insert(start, newText);
            target.select(start, start + newText.length);
        }
        target.forceActiveFocus();
    }

    function openLinkDialog() {
        let target = supportPage.activeField || feedbackInput;
        if (target === feedbackTitle) return;
        let start = target.selectionStart;
        let end = target.selectionEnd;
        let selectedText = target.selectedText;
        let urlPattern = /^(https?:\/\/|www\.)\S+$/i;

        linkDialog.pendingTarget = target;
        linkDialog.pendingStart = start;
        linkDialog.pendingEnd = end;

        if (selectedText.length > 0 && urlPattern.test(selectedText)) {
            linkDialog.prefillText = selectedText;
            linkDialog.prefillUrl = selectedText;
        } else if (selectedText.length > 0) {
            linkDialog.prefillText = selectedText;
            linkDialog.prefillUrl = "https://";
        } else {
            linkDialog.prefillText = "";
            linkDialog.prefillUrl = "https://";
        }
        linkDialog.open();
    }

    function applyLink(target, start, end, text, url) {
        if (!target) return;
        let cleanUrl = url.trim().length > 0 ? url.trim() : "https://";
        let cleanText = text.trim().length > 0 ? text.trim() : cleanUrl;
        target.remove(start, end);
        let linkMd = "[" + cleanText + "](" + cleanUrl + ")";
        target.insert(start, linkMd);
        target.forceActiveFocus();
        target.cursorPosition = start + linkMd.length;
    }

    Component.onCompleted: {
        supportPage.hasRated = plasmoid.configuration.hasRated;
        supportPage.hasStarred = plasmoid.configuration.hasStarred;

        if (supportPage.hasRated && !supportPage.hasStarred) {
            supportPage.firstUnlockedType = "rate";
        } else if (supportPage.hasStarred && !supportPage.hasRated) {
            supportPage.firstUnlockedType = "star";
        }

        supportPage.fetchStargazers();
        supportPage.fetchStoreReviews();
        supportPage.fetchDownloadCount();
    }

    ScrollView {
        id: scrollView
        anchors.fill: parent
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            id: contentColumn
            // Math.max(contentMaxWidth, implicitWidth): normally implicitWidth
            // (the true minimum needed by the widest card/row below, once
            // SettingsCard propagates it) stays under contentMaxWidth, so
            // this is a no-op and nothing changes for languages that already
            // fit. It only kicks in when a translation makes some row's
            // natural width exceed the usual cap — in that case the column
            // grows just enough to fit it, still capped by the actual
            // available scroll width so it can never overflow the window.
            readonly property real effectiveWidth: Math.min(scrollView.availableWidth - Kirigami.Units.gridUnit * 2, Math.max(supportPage.contentMaxWidth, contentColumn.implicitWidth))
            width: effectiveWidth
            x: Math.max(Kirigami.Units.gridUnit, (scrollView.availableWidth - effectiveWidth) / 2)
            spacing: Kirigami.Units.largeSpacing

            Item { Layout.preferredHeight: Kirigami.Units.gridUnit * 0.5 }

            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.gridUnit * 1.25

                Image {
                    Layout.preferredWidth: Kirigami.Units.iconSizes.huge
                    Layout.preferredHeight: Kirigami.Units.iconSizes.huge
                    Layout.alignment: Qt.AlignVCenter
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                    sourceSize.width: Kirigami.Units.iconSizes.huge * 2
                    sourceSize.height: Kirigami.Units.iconSizes.huge * 2
                    source: supportPage.heartIconDataUrl("#E63946")
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing * 1.5

                    Label {
                        text: i18n("Enjoying Minimalist Animated Weather?")
                        font.bold: true
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.35
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                        // Without this, this Label's own unwrapped one-line
                        // width (its implicitWidth, which wrapMode does NOT
                        // shrink) would feed into contentColumn's computed
                        // implicitWidth and inflate the whole page's width —
                        // defeating the wrap entirely. Layout.preferredWidth: 1
                        // tells the layout "use fillWidth for my real size,
                        // don't use my natural size as a sizing hint".
                        Layout.preferredWidth: 1
                    }

                    Label {
                        text: i18n("This applet is open-source and developed with passion. Your support keeps the project active and helps it grow within the KDE ecosystem.")
                        wrapMode: Text.WordWrap
                        opacity: 0.65
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.0
                        lineHeight: 1.35
                    }
                }
            }

            SectionHeader {
                text: i18n("Support the Project")
                // Pas "isFirst" : ce header n'est pas le tout premier élément de la page
                // (le bloc coeur + texte d'intro le précède), contrairement à "Panel Bar"
                // dans ConfigAppearance.qml par exemple. isFirst supprimait une marge haute
                // supplémentaire, ce qui rendait l'écart avec le texte d'intro plus petit
                // qu'entre les autres sous-sections (ex: Community Love).
            }

            SettingsCard {
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.gridUnit * 1.25

                    Item {
                        implicitWidth: Kirigami.Units.iconSizes.large
                        implicitHeight: Kirigami.Units.iconSizes.large
                        Layout.alignment: Qt.AlignVCenter
                        Kirigami.Icon {
                            source: "kde"
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: supportPage.logoCenterOffset
                            width: parent.width
                            height: parent.height
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing * 0.5
                        Label {
                            text: i18n("KDE Store")
                            font.bold: true
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.05
                        }
                        Label {
                            text: i18n("Leave a rating and a comment to help promote the plasmoid and reach more users.")
                            wrapMode: Text.WordWrap
                            opacity: 0.65
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                        }
                    }

                    Button {
                        id: rateButton
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: supportPage.supportButtonWidth
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 1.9
                        Layout.rightMargin: Kirigami.Units.gridUnit * 0.8

                        focusPolicy: Qt.NoFocus
                        hoverEnabled: true

                        leftPadding: Kirigami.Units.largeSpacing
                        rightPadding: Kirigami.Units.largeSpacing
                        topPadding: Kirigami.Units.smallSpacing * 0.6
                        bottomPadding: Kirigami.Units.smallSpacing * 0.6

                        onClicked: supportPage.handleSupportClick("rate", "https://store.kde.org/p/2356087")

                        readonly property color fgColor: (rateButton.down || rateButton.checked) ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                        readonly property color bgColor: rateButton.down ? Kirigami.Theme.highlightColor : (rateButton.hovered ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.18) : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.06))

                        background: Rectangle {
                            radius: supportPage.fieldRadius
                            color: rateButton.bgColor
                            border.width: 1
                            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.18)
                            Behavior on color { ColorAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        }

                        contentItem: Item {
                            anchors.fill: parent

                            Label {
                                id: rateLabel
                                text: i18n("Rate")
                                color: rateButton.fgColor
                                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.05
                                font.bold: true
                                elide: Text.ElideRight
                                fontSizeMode: Text.Fit
                                minimumPixelSize: Kirigami.Units.gridUnit * 0.55
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.right: rateStatusIcon.left
                                anchors.leftMargin: Kirigami.Units.smallSpacing
                                anchors.rightMargin: Kirigami.Units.smallSpacing * 0.6
                            }

                            Kirigami.Icon {
                                id: rateStatusIcon
                                width: Kirigami.Units.iconSizes.small
                                height: Kirigami.Units.iconSizes.small
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right
                                anchors.rightMargin: Kirigami.Units.largeSpacing

                                source: supportPage.hasRated ? "emblem-checked" : "emblem-favorite"
                                color: supportPage.hasRated ? Kirigami.Theme.positiveTextColor : "#e25c8a"

                                SequentialAnimation {
                                    running: !supportPage.hasRated
                                    loops: Animation.Infinite
                                    NumberAnimation { target: rateStatusIcon; property: "scale"; from: 1.0; to: 1.25; duration: 900; easing.type: Easing.InOutSine }
                                    NumberAnimation { target: rateStatusIcon; property: "scale"; from: 1.25; to: 1.0; duration: 900; easing.type: Easing.InOutSine }
                                    PauseAnimation { duration: 2200 }
                                }
                            }
                        }
                    }
                }

                Kirigami.Separator { Layout.fillWidth: true; opacity: 0.4 }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.gridUnit * 1.25

                    Item {
                        implicitWidth: Kirigami.Units.iconSizes.large
                        implicitHeight: Kirigami.Units.iconSizes.large
                        Layout.alignment: Qt.AlignVCenter

                        Rectangle {
                            width: parent.width * 0.84
                            height: width
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: supportPage.logoCenterOffset
                            radius: width / 2
                            color: "white"
                        }

                        Image {
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: supportPage.logoCenterOffset
                            width: parent.width * 0.90
                            height: width
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            mipmap: true
                            sourceSize.width: width * 2
                            sourceSize.height: height * 2
                            source: supportPage.githubIconDataUrl("#181717")
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing * 0.5
                        Label {
                            text: i18n("GitHub")
                            font.bold: true
                            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.05
                        }
                        Label {
                            text: i18n("Star the repository to support the project and follow its development.")
                            wrapMode: Text.WordWrap
                            opacity: 0.65
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                        }
                    }

                    Button {
                        id: starButton
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: supportPage.supportButtonWidth
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 1.9
                        Layout.rightMargin: Kirigami.Units.gridUnit * 0.8

                        focusPolicy: Qt.NoFocus
                        hoverEnabled: true

                        leftPadding: Kirigami.Units.largeSpacing
                        rightPadding: Kirigami.Units.largeSpacing
                        topPadding: Kirigami.Units.smallSpacing * 0.6
                        bottomPadding: Kirigami.Units.smallSpacing * 0.6

                        onClicked: supportPage.handleSupportClick("star", "https://github.com/Samy879/minimalist-animated-weather")

                        readonly property color fgColor: (starButton.down || starButton.checked) ? Kirigami.Theme.highlightedTextColor : Kirigami.Theme.textColor
                        readonly property color bgColor: starButton.down ? Kirigami.Theme.highlightColor : (starButton.hovered ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.18) : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.06))

                        background: Rectangle {
                            radius: supportPage.fieldRadius
                            color: starButton.bgColor
                            border.width: 1
                            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.18)
                            Behavior on color { ColorAnimation { duration: 120; easing.type: Easing.OutCubic } }
                        }

                        contentItem: Item {
                            anchors.fill: parent

                            Label {
                                id: starLabel
                                text: i18n("Star")
                                color: starButton.fgColor
                                font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.05
                                font.bold: true
                                elide: Text.ElideRight
                                fontSizeMode: Text.Fit
                                minimumPixelSize: Kirigami.Units.gridUnit * 0.55
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.right: starStatusIcon.left
                                anchors.leftMargin: Kirigami.Units.smallSpacing
                                anchors.rightMargin: Kirigami.Units.smallSpacing * 0.6
                            }

                            Kirigami.Icon {
                                id: starStatusIcon
                                width: Kirigami.Units.iconSizes.small
                                height: Kirigami.Units.iconSizes.small
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right
                                anchors.rightMargin: Kirigami.Units.largeSpacing

                                source: supportPage.hasStarred ? "emblem-checked" : "emblem-favorite"
                                color: supportPage.hasStarred ? Kirigami.Theme.positiveTextColor : "#e25c8a"

                                SequentialAnimation {
                                    running: !supportPage.hasStarred
                                    loops: Animation.Infinite
                                    NumberAnimation { target: starStatusIcon; property: "scale"; from: 1.0; to: 1.25; duration: 900; easing.type: Easing.InOutSine }
                                    NumberAnimation { target: starStatusIcon; property: "scale"; from: 1.25; to: 1.0; duration: 900; easing.type: Easing.InOutSine }
                                    PauseAnimation { duration: 2200 }
                                }
                            }
                        }
                    }
                }

                Label {
                    id: thanksLabel
                    text: supportPage.thanksText
                    color: Kirigami.Theme.positiveTextColor
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                    Layout.topMargin: visible ? Kirigami.Units.smallSpacing : 0
                    Layout.preferredHeight: visible ? implicitHeight : 0
                    visible: opacity > 0
                    opacity: 0
                    scale: 0.6
                    transformOrigin: Item.Center

                    Behavior on opacity { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }

                    Timer {
                        id: thanksPopupTimer
                        interval: 20
                        onTriggered: { thanksLabel.opacity = 1; thanksLabel.scale = 1; thanksFadeTimer.restart(); }
                    }
                    Timer {
                        id: thanksFadeTimer
                        interval: 1400
                        onTriggered: { thanksLabel.opacity = 0; thanksLabel.scale = 0.6; }
                    }
                }
            }

            SectionHeader {
                text: i18n("Community Love")
            }

            SettingsCard {
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing * 1.2

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Label {
                            text: i18n("KDE Store")
                            font.bold: true
                            opacity: 0.75
                            Layout.rightMargin: Kirigami.Units.smallSpacing * 1.3
                        }

                        Item {
                            implicitWidth: downloadBadgeRow.implicitWidth + Kirigami.Units.largeSpacing
                            implicitHeight: downloadBadgeRow.implicitHeight + Kirigami.Units.smallSpacing * 1.2
                            Layout.alignment: Qt.AlignVCenter

                            Rectangle {
                                anchors.fill: parent
                                radius: height / 2
                                color: Qt.rgba(Kirigami.Theme.positiveTextColor.r, Kirigami.Theme.positiveTextColor.g, Kirigami.Theme.positiveTextColor.b, 0.15)
                            }

                            RowLayout {
                                id: downloadBadgeRow
                                anchors.centerIn: parent
                                spacing: Kirigami.Units.smallSpacing * 0.6

                                Image {
                                    Layout.preferredWidth: Kirigami.Theme.defaultFont.pointSize * 1.15
                                    Layout.preferredHeight: Layout.preferredWidth
                                    Layout.alignment: Qt.AlignVCenter
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    sourceSize.width: width * 2
                                    sourceSize.height: height * 2
                                    source: supportPage.downloadIconDataUrl(supportPage.colorToHex(Kirigami.Theme.positiveTextColor))
                                    visible: !supportPage.downloadsError
                                }

                                Label {
                                    Layout.alignment: Qt.AlignVCenter
                                    text: {
                                        if (supportPage.downloadsLoading) return "…";
                                        if (supportPage.downloadsError) return i18n("N/A");
                                        return supportPage.downloadsCount.toLocaleString(Qt.locale(), 'f', 0);
                                    }
                                    font.bold: true
                                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.07
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }

                        ToolButton {
                            visible: !supportPage.reviewsLoading && !supportPage.reviewsError && supportPage.storeReviews.length > 0
                            text: i18n("Read comments")
                            icon.name: "view-list-text"
                            display: AbstractButton.TextBesideIcon
                            onClicked: reviewsPopup.open()
                        }
                    }

                    Kirigami.Separator { Layout.fillWidth: true; opacity: 0.2; visible: supportPage.ratedReviews.length > 0 }

                    Label {
                        visible: supportPage.reviewsLoading
                        text: i18n("Loading ratings…")
                        opacity: 0.6
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.9
                    }

                    Label {
                        visible: !supportPage.reviewsLoading && supportPage.reviewsError
                        text: i18n("Ratings unavailable right now.")
                        opacity: 0.6
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.9
                    }

                    Label {
                        visible: !supportPage.reviewsLoading && !supportPage.reviewsError && supportPage.ratedReviews.length === 0
                        text: i18n("No ratings yet, be the first!")
                        opacity: 0.6
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.9
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing * 0.7
                        visible: !supportPage.reviewsLoading && !supportPage.reviewsError && supportPage.ratedReviews.length > 0

                        ToolButton {
                            icon.name: "go-previous"
                            display: AbstractButton.IconOnly
                            enabled: !reviewListView.atXBeginning && reviewListView.contentWidth > reviewListView.width
                            onClicked: {
                                let newX = Math.max(0, reviewListView.contentX - reviewListView.width / 2);
                                reviewScrollAnim.to = newX;
                                reviewScrollAnim.restart();
                            }
                        }

                        ListView {
                            id: reviewListView
                            Layout.fillWidth: true
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 1.7
                            orientation: ListView.Horizontal
                            spacing: Kirigami.Units.smallSpacing * 0.7
                            clip: true
                            model: supportPage.ratedReviews
                            interactive: true
                            boundsBehavior: Flickable.StopAtBounds

                            NumberAnimation {
                                id: reviewScrollAnim
                                target: reviewListView
                                property: "contentX"
                                duration: 250
                                easing.type: Easing.OutCubic
                            }

                            delegate: Rectangle {
                                id: reviewChip
                                property var review: modelData
                                implicitWidth: chipRow.implicitWidth + Kirigami.Units.largeSpacing
                                height: ListView.view.height
                                radius: height / 2
                                color: chipMouse.containsMouse
                                ? Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.15)
                                : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.06)
                                border.width: 1
                                border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.15)
                                Behavior on color { ColorAnimation { duration: 120 } }

                                RowLayout {
                                    id: chipRow
                                    anchors.centerIn: parent
                                    spacing: Kirigami.Units.smallSpacing * 0.6

                                    Label {
                                        text: reviewChip.review.username
                                        font.bold: true
                                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.90
                                    }

                                    Label {
                                        text: reviewChip.review.rating + i18n("/10")
                                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.90
                                        font.bold: true
                                        color: Kirigami.Theme.highlightColor
                                    }
                                }

                                MouseArea {
                                    id: chipMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: chipCommentPopup.openFor(reviewChip)
                                    onExited: chipCommentPopup.close()
                                }
                            }
                        }

                        ToolButton {
                            icon.name: "go-next"
                            display: AbstractButton.IconOnly
                            enabled: !reviewListView.atXEnd && reviewListView.contentWidth > reviewListView.width
                            onClicked: {
                                let newX = Math.min(reviewListView.contentWidth - reviewListView.width, reviewListView.contentX + reviewListView.width / 2);
                                reviewScrollAnim.to = newX;
                                reviewScrollAnim.restart();
                            }
                        }
                    }

                    Popup {
                        id: chipCommentPopup
                        parent: Overlay.overlay
                        property string reviewText: ""

                        modal: false
                        focus: false
                        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
                        width: Math.min(Kirigami.Units.gridUnit * 18, (parent ? parent.width * 0.88 : Kirigami.Units.gridUnit * 18))
                        padding: Kirigami.Units.smallSpacing * 1.4

                        background: Rectangle {
                            color: Kirigami.Theme.backgroundColor
                            radius: supportPage.fieldRadius
                            border.width: 1
                            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.18)
                        }

                        function openFor(chipItem) {
                            reviewText = chipItem.review.text;
                            let pos = chipItem.mapToItem(Overlay.overlay, 0, chipItem.height + Kirigami.Units.smallSpacing * 0.5);
                            x = Math.max(Kirigami.Units.smallSpacing, Math.min(pos.x, Overlay.overlay.width - width - Kirigami.Units.smallSpacing));
                            y = pos.y;
                            open();
                        }

                        Label {
                            width: parent.width
                            text: chipCommentPopup.reviewText
                            wrapMode: Text.WordWrap
                            opacity: 0.8
                        }
                    }
                }
            }

            SettingsCard {
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing * 1.2

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Label {
                            text: i18n("GitHub")
                            font.bold: true
                            opacity: 0.75
                            Layout.rightMargin: Kirigami.Units.smallSpacing * 1.3
                        }

                        Item {
                            implicitWidth: starBadgeRow.implicitWidth + Kirigami.Units.largeSpacing
                            implicitHeight: starBadgeRow.implicitHeight + Kirigami.Units.smallSpacing * 1.2
                            Layout.alignment: Qt.AlignVCenter

                            Rectangle {
                                anchors.fill: parent
                                radius: height / 2
                                color: Qt.rgba(0.89, 0.63, 0.11, 0.15)
                            }

                            RowLayout {
                                id: starBadgeRow
                                anchors.centerIn: parent
                                spacing: Kirigami.Units.smallSpacing * 0.6

                                Image {
                                    Layout.preferredWidth: Kirigami.Theme.defaultFont.pointSize * 1.15
                                    Layout.preferredHeight: Layout.preferredWidth
                                    Layout.alignment: Qt.AlignVCenter
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    sourceSize.width: width * 2
                                    sourceSize.height: height * 2
                                    source: supportPage.starIconDataUrl("#e3a01b")
                                    visible: !supportPage.stargazersError
                                }

                                Label {
                                    Layout.alignment: Qt.AlignVCenter
                                    text: {
                                        if (supportPage.stargazersLoading) return "…";
                                        if (supportPage.stargazersError) return i18n("N/A");
                                        return supportPage.stargazersCount.toLocaleString(Qt.locale(), 'f', 0);
                                    }
                                    font.bold: true
                                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.07
                                }
                            }
                        }

                        Item { Layout.fillWidth: true }
                    }

                    Kirigami.Separator { Layout.fillWidth: true; opacity: 0.2; visible: !supportPage.stargazersLoading && !supportPage.stargazersError && supportPage.stargazers.length > 0 }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing
                        visible: !supportPage.stargazersLoading && !supportPage.stargazersError && supportPage.stargazers.length > 0

                        ToolButton {
                            icon.name: "go-previous"
                            display: AbstractButton.IconOnly
                            enabled: !avatarListView.atXBeginning && avatarListView.contentWidth > avatarListView.width
                            onClicked: {
                                let newX = Math.max(0, avatarListView.contentX - avatarListView.width / 2);
                                scrollAnim.to = newX;
                                scrollAnim.restart();
                            }
                        }

                        ListView {
                            id: avatarListView
                            Layout.fillWidth: true
                            Layout.preferredHeight: Kirigami.Units.iconSizes.medium
                            orientation: ListView.Horizontal
                            spacing: Kirigami.Units.smallSpacing
                            clip: true
                            model: supportPage.stargazers
                            interactive: true
                            boundsBehavior: Flickable.StopAtBounds

                            NumberAnimation {
                                id: scrollAnim
                                target: avatarListView
                                property: "contentX"
                                duration: 250
                                easing.type: Easing.OutCubic
                            }

                            delegate: Rectangle {
                                id: avatarBadge
                                width: Kirigami.Units.iconSizes.medium
                                height: width
                                radius: width / 2
                                color: Kirigami.Theme.backgroundColor
                                border.width: 1
                                border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.18)
                                clip: true

                                Image {
                                    anchors.fill: parent
                                    source: modelData.avatar_url || ""
                                    fillMode: Image.PreserveAspectCrop
                                    smooth: true
                                    asynchronous: true
                                }

                                HoverHandler { id: avatarHover }
                                ToolTip.visible: avatarHover.hovered
                                ToolTip.text: modelData.login || ""
                            }
                        }

                        ToolButton {
                            icon.name: "go-next"
                            display: AbstractButton.IconOnly
                            enabled: !avatarListView.atXEnd && avatarListView.contentWidth > avatarListView.width
                            onClicked: {
                                let newX = Math.min(avatarListView.contentWidth - avatarListView.width, avatarListView.contentX + avatarListView.width / 2);
                                scrollAnim.to = newX;
                                scrollAnim.restart();
                            }
                        }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.largeSpacing
                visible: supportPage.hasRated || supportPage.hasStarred

                SectionHeader {
                    text: i18n("Unlocked as a Thank You")
                }

                SettingsCard {
                    id: unlockedCard
                    Layout.fillWidth: true

                    Component {
                        id: shootingStarEffectComponent
                        RowLayout {
                            spacing: Kirigami.Units.smallSpacing
                            CheckBox {
                                text: i18n("Shooting Star Effect")
                                checked: supportPage.cfg_shootingStarEffect
                                enabled: supportPage.cfg_showAnimations
                                onToggled: supportPage.cfg_shootingStarEffect = checked
                            }
                            InfoIcon {
                                text: supportPage.cfg_showAnimations
                                ? i18n("Adds shooting stars to the animated theme's night sky.")
                                : i18n("Disabled because animations are turned off in the Appearance settings.")
                            }
                        }
                    }

                    Component {
                        id: rainbowEffectComponent
                        RowLayout {
                            spacing: Kirigami.Units.smallSpacing
                            CheckBox {
                                text: i18n("Rainbow Effect")
                                checked: supportPage.cfg_rainbowEffect
                                enabled: supportPage.cfg_showAnimations
                                onToggled: supportPage.cfg_rainbowEffect = checked
                            }
                            InfoIcon {
                                text: supportPage.cfg_showAnimations
                                ? i18n("Adds a rainbow to the animated theme when it's raining with the sun still out.")
                                : i18n("Disabled because animations are turned off in the Appearance settings.")
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Item {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            implicitHeight: leftEffectLoader.implicitHeight
                            clip: true

                            Loader {
                                id: leftEffectLoader
                                anchors.centerIn: parent
                                sourceComponent: supportPage.leftEffectType === "rate" ? shootingStarEffectComponent : rainbowEffectComponent

                                readonly property bool slotUnlocked: supportPage.leftEffectType === "rate" ? supportPage.hasRated : supportPage.hasStarred

                                opacity: slotUnlocked ? 1 : 0
                                scale: slotUnlocked ? 1 : 0.85
                                visible: opacity > 0.01

                                transform: Translate {
                                    x: leftEffectLoader.slotUnlocked ? 0 : -Kirigami.Units.gridUnit * 1.2
                                    Behavior on x { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
                                }

                                Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
                                Behavior on scale   { NumberAnimation { duration: 450; easing.type: Easing.OutBack } }
                            }
                        }

                        Kirigami.Separator {
                            Layout.fillHeight: true
                            opacity: (supportPage.hasStarred && supportPage.hasRated) ? 0.3 : 0
                            Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            implicitHeight: rightEffectLoader.implicitHeight

                            Loader {
                                id: rightEffectLoader
                                anchors.centerIn: parent
                                sourceComponent: supportPage.rightEffectType === "rate" ? shootingStarEffectComponent : rainbowEffectComponent

                                readonly property bool slotUnlocked: supportPage.rightEffectType === "rate" ? supportPage.hasRated : supportPage.hasStarred

                                opacity: slotUnlocked ? 1 : 0
                                scale: slotUnlocked ? 1 : 0.85
                                visible: opacity > 0.01

                                Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.OutCubic } }
                                Behavior on scale   { NumberAnimation { duration: 450; easing.type: Easing.OutBack } }
                            }
                        }
                    }
                }
            }

            SectionHeader {
                text: i18n("Feedback & Bug Reports")
            }

            SettingsCard {
                Label {
                    text: i18n("Found a bug or have an idea? Fill out the form below to send it directly to the developer.")
                    wrapMode: Text.WordWrap
                    opacity: 0.65
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                }

                Kirigami.InlineMessage {
                    id: formErrorMsg
                    type: Kirigami.MessageType.Error
                    text: i18n("Please fill in both the object/title and the description.")
                    visible: false
                    Layout.fillWidth: true
                }

                Kirigami.InlineMessage {
                    id: feedbackThanksMsg
                    type: Kirigami.MessageType.Positive
                    text: i18n("Thank you for your feedback! 🚀")
                    visible: false
                    Layout.fillWidth: true
                }

                Timer {
                    id: feedbackThanksTimer
                    interval: 4000
                    onTriggered: feedbackThanksMsg.visible = false
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing

                    ComboBox {
                        id: feedbackTypeCombo
                        Layout.preferredWidth: Kirigami.Units.gridUnit * 9
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 1.9
                        model: [i18n("Suggestion"), i18n("Improvement"), i18n("Bug")]
                    }

                    TextField {
                        id: feedbackTitle
                        Layout.fillWidth: true
                        placeholderText: i18n("Subject")

                        Keys.onReturnPressed: (event) => { event.accepted = true; supportPage.forceActiveFocus(); }
                        Keys.onEnterPressed: (event) => { event.accepted = true; supportPage.forceActiveFocus(); }

                        onTextChanged: { if (text.trim().length > 0) supportPage.titleError = false; checkFormErrors(); }
                        onActiveFocusChanged: if (activeFocus) { supportPage.activeField = feedbackTitle; }

                        background: Rectangle {
                            implicitHeight: Kirigami.Units.gridUnit * 1.9
                            radius: supportPage.fieldRadius
                            color: Kirigami.Theme.backgroundColor
                            border.width: 1.4
                            border.color: supportPage.titleError ? Kirigami.Theme.negativeTextColor : (feedbackTitle.activeFocus ? Kirigami.Theme.highlightColor : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.25))
                            Behavior on border.color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Kirigami.Units.smallSpacing * 0.5
                    spacing: Kirigami.Units.smallSpacing

                    readonly property bool formattingAvailable: supportPage.activeField !== feedbackTitle

                    ToolButton {
                        icon.name: "format-text-bold"
                        ToolTip.text: i18n("Bold")
                        ToolTip.visible: hovered
                        focusPolicy: Qt.NoFocus
                        enabled: parent.formattingAvailable
                        onClicked: supportPage.toggleFormat("bold")
                    }
                    ToolButton {
                        icon.name: "format-text-italic"
                        ToolTip.text: i18n("Italic")
                        ToolTip.visible: hovered
                        focusPolicy: Qt.NoFocus
                        enabled: parent.formattingAvailable
                        onClicked: supportPage.toggleFormat("italic")
                    }
                    ToolButton {
                        icon.name: "format-text-strikethrough"
                        ToolTip.text: i18n("Strikethrough")
                        ToolTip.visible: hovered
                        focusPolicy: Qt.NoFocus
                        enabled: parent.formattingAvailable
                        onClicked: supportPage.toggleFormat("strike")
                    }
                    ToolButton {
                        icon.name: "format-list-unordered"
                        ToolTip.text: i18n("Bulleted List")
                        ToolTip.visible: hovered
                        focusPolicy: Qt.NoFocus
                        enabled: parent.formattingAvailable
                        onClicked: supportPage.insertList("bullet")
                    }
                    ToolButton {
                        icon.name: "format-list-ordered"
                        ToolTip.text: i18n("Numbered List")
                        ToolTip.visible: hovered
                        focusPolicy: Qt.NoFocus
                        enabled: parent.formattingAvailable
                        onClicked: supportPage.insertList("number")
                    }
                    ToolButton {
                        icon.name: "insert-link"
                        ToolTip.text: i18n("Insert Link")
                        ToolTip.visible: hovered
                        focusPolicy: Qt.NoFocus
                        enabled: parent.formattingAvailable
                        onClicked: supportPage.openLinkDialog()
                    }

                    Item { Layout.fillWidth: true }
                }

                TextArea {
                    id: feedbackInput
                    Layout.fillWidth: true
                    Layout.minimumHeight: Kirigami.Units.gridUnit * 8
                    Layout.preferredHeight: Math.max(Kirigami.Units.gridUnit * 10, contentHeight + topPadding + bottomPadding)

                    placeholderText: i18n("Describe your idea or the bug in detail here...")
                    wrapMode: TextEdit.WordWrap

                    textFormat: TextEdit.PlainText

                    onTextChanged: { if (text.trim().length > 0) supportPage.bodyError = false; checkFormErrors(); }
                    onActiveFocusChanged: if (activeFocus) { supportPage.activeField = feedbackInput; }

                    background: Rectangle {
                        radius: supportPage.fieldRadius
                        color: Kirigami.Theme.backgroundColor
                        border.width: 1.4
                        border.color: supportPage.bodyError ? Kirigami.Theme.negativeTextColor : (feedbackInput.activeFocus ? Kirigami.Theme.highlightColor : Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.25))
                        Behavior on border.color { ColorAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: Kirigami.Units.smallSpacing
                    spacing: Kirigami.Units.largeSpacing

                    Button {
                        text: i18n("Open GitHub Issue")
                        icon.name: "vcs-normal"
                        focusPolicy: Qt.NoFocus
                        onClicked: submitFeedback("github")
                    }

                    Button {
                        text: i18n("Send via Email")
                        icon.name: "mail-send"
                        focusPolicy: Qt.NoFocus
                        onClicked: submitFeedback("email")
                    }
                }
            }

            Item { Layout.preferredHeight: Kirigami.Units.gridUnit * 0.5 }
        }
    }

    Dialog {
        id: linkDialog
        title: i18n("Insert Link")
        modal: true
        parent: Overlay.overlay
        x: parent ? Math.round((parent.width - width) / 2) : 0
        y: parent ? Math.round((parent.height - height) / 3) : 0
        standardButtons: Dialog.Ok | Dialog.Cancel

        property var pendingTarget: null
        property int pendingStart: 0
        property int pendingEnd: 0
        property string prefillText: ""
        property string prefillUrl: "https://"

        onOpened: {
            linkTextField.text = linkDialog.prefillText;
            linkUrlField.text = linkDialog.prefillUrl;
            linkTextField.forceActiveFocus();
            linkTextField.selectAll();
        }

        onAccepted: supportPage.applyLink(
            linkDialog.pendingTarget,
            linkDialog.pendingStart,
            linkDialog.pendingEnd,
            linkTextField.text,
            linkUrlField.text
        )

        ColumnLayout {
            implicitWidth: Kirigami.Units.gridUnit * 18
            spacing: Kirigami.Units.smallSpacing * 1.2

            Label { text: i18n("Text to display (optional, the URL is used if left empty)"); wrapMode: Text.WordWrap; Layout.fillWidth: true }
            TextField {
                id: linkTextField
                Layout.fillWidth: true
                placeholderText: i18n("Link text")
                onAccepted: linkDialog.accept()
            }

            Label { text: i18n("URL"); Layout.topMargin: Kirigami.Units.smallSpacing; font.bold: true }
            TextField {
                id: linkUrlField
                Layout.fillWidth: true
                placeholderText: "https://"
                onAccepted: linkDialog.accept()
            }
        }
    }

    Popup {
        id: reviewsPopup
        parent: Overlay.overlay
        x: (parent ? parent.width - width : 0) / 2
        y: (parent ? parent.height - height : 0) / 2
        width: Math.min(supportPage.contentMaxWidth, (parent ? parent.width * 0.9 : 480))
        height: Math.min(Kirigami.Units.gridUnit * 24, (parent ? parent.height * 0.85 : 400))
        modal: true
        focus: true
        padding: Kirigami.Units.gridUnit
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        background: Rectangle {
            color: Kirigami.Theme.backgroundColor
            radius: supportPage.fieldRadius * 1.4
            border.width: 1
            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.18)
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: Kirigami.Units.smallSpacing

            RowLayout {
                Layout.fillWidth: true
                Label {
                    text: i18n("Ratings on the KDE Store")
                    font.bold: true
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.1
                    Layout.fillWidth: true
                }
                ToolButton {
                    icon.name: "window-close"
                    display: AbstractButton.IconOnly
                    onClicked: reviewsPopup.close()
                }
            }

            Kirigami.Separator { Layout.fillWidth: true; opacity: 0.4 }

            ListView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: Kirigami.Units.gridUnit * 0.8
                model: supportPage.storeReviews
                ScrollBar.vertical: ScrollBar {}

                delegate: ColumnLayout {
                    width: ListView.view.width
                    spacing: Kirigami.Units.smallSpacing * 0.4

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing

                        Label {
                            text: modelData.username
                            font.bold: true
                        }

                        Item { Layout.fillWidth: true }

                        Label {
                            visible: modelData.rating > 0
                            text: modelData.rating + i18n("/10")
                            font.bold: true
                            color: Kirigami.Theme.highlightColor
                        }

                        Label {
                            visible: modelData.rating <= 0
                            text: i18n("Not rated")
                            opacity: 0.5
                            font.italic: true
                        }
                    }

                    Label {
                        text: modelData.text
                        wrapMode: Text.WordWrap
                        opacity: 0.75
                        Layout.fillWidth: true
                    }

                    Kirigami.Separator {
                        Layout.fillWidth: true
                        Layout.topMargin: Kirigami.Units.smallSpacing * 0.4
                        opacity: 0.3
                        visible: index < supportPage.storeReviews.length - 1
                    }
                }
            }
        }
    }

    Item {
        id: celebrationOverlay
        anchors.fill: parent
        z: 999
        visible: false

        property string messageText: ""
        property string subText: ""

        readonly property int totalDuration: 2830

        function play(text, sub) {
            messageText = text;
            subText = sub || "";
            visible = true;
            toastCard.opacity = 0;
            toastCard.scale = 0.85;
            toastCard.y = toastCard.baseY + Kirigami.Units.gridUnit * 0.6;
            shockwave.opacity = 0.8;
            shockwave.scale = 0;
            sparkleRepeater.launch();
            heartsRepeater.launch();
            wordsRepeater.launch();
            masterSequence.restart();
        }

        SequentialAnimation {
            id: masterSequence

            ParallelAnimation {
                NumberAnimation { target: shockwave; property: "scale"; from: 0; to: 1; duration: 750; easing.type: Easing.OutCubic }
                NumberAnimation { target: shockwave; property: "opacity"; from: 0.8; to: 0; duration: 750; easing.type: Easing.OutCubic }

                SequentialAnimation {
                    PauseAnimation { duration: 120 }
                    ParallelAnimation {
                        NumberAnimation { target: toastCard; property: "opacity"; to: 1; duration: 380; easing.type: Easing.OutCubic }
                        NumberAnimation { target: toastCard; property: "scale"; to: 1; duration: 480; easing.type: Easing.OutBack; easing.overshoot: 1.1 }
                        NumberAnimation { target: toastCard; property: "y"; to: toastCard.baseY; duration: 480; easing.type: Easing.OutCubic }
                    }
                }
            }

            PauseAnimation { duration: 1700 }

            ParallelAnimation {
                NumberAnimation { target: toastCard; property: "opacity"; to: 0; duration: 380; easing.type: Easing.InCubic }
                NumberAnimation { target: toastCard; property: "scale"; to: 0.94; duration: 380; easing.type: Easing.InCubic }
                NumberAnimation { target: toastCard; property: "y"; to: toastCard.baseY - Kirigami.Units.gridUnit * 0.4; duration: 380; easing.type: Easing.InCubic }
            }

            ScriptAction {
                script: { celebrationOverlay.visible = false; }
            }
        }

        Rectangle {
            id: shockwave
            width: Kirigami.Units.gridUnit * 14
            height: width
            radius: width / 2
            anchors.centerIn: parent
            color: "transparent"
            border.width: 2
            border.color: Kirigami.Theme.highlightColor
            opacity: 0
            transformOrigin: Item.Center
        }

        Item {
            anchors.fill: parent

            Repeater {
                id: sparkleRepeater
                model: 12

                function launch() {
                    for (let i = 0; i < count; i++) {
                        itemAt(i).burst(i);
                    }
                }

                Rectangle {
                    id: spark
                    width: Kirigami.Units.smallSpacing * 0.7
                    height: width
                    radius: width / 2
                    color: ["#ffd166", "#ff8fab", "#ff6b81"][index % 3]
                    opacity: 0

                    function burst(i) {
                        let cx = parent.width / 2;
                        let cy = parent.height / 2;
                        let angle = (i / sparkleRepeater.count) * Math.PI * 2 + Math.random() * 0.3;
                        let dist = Kirigami.Units.gridUnit * (4.5 + Math.random() * 3);

                        x = cx;
                        y = cy;
                        opacity = 1;
                        sparkAnimX.from = cx;
                        sparkAnimX.to = cx + Math.cos(angle) * dist;
                        sparkAnimY.from = cy;
                        sparkAnimY.to = cy + Math.sin(angle) * dist * 0.75 - Kirigami.Units.gridUnit;
                        sparkSeq.restart();
                    }

                    SequentialAnimation {
                        id: sparkSeq
                        ParallelAnimation {
                            NumberAnimation { id: sparkAnimX; target: spark; property: "x"; duration: 700; easing.type: Easing.OutCubic }
                            NumberAnimation { id: sparkAnimY; target: spark; property: "y"; duration: 700; easing.type: Easing.OutCubic }
                            NumberAnimation { target: spark; property: "opacity"; from: 1; to: 0; duration: 700; easing.type: Easing.InCubic }
                        }
                    }
                }
            }
        }

        Item {
            id: heartsContainer
            anchors.fill: parent
            clip: true

            Repeater {
                id: heartsRepeater
                model: 10

                function launch() {
                    for (let i = 0; i < count; i++) {
                        itemAt(i).rise(i * 35 + Math.random() * 60);
                    }
                }

                Item {
                    id: heartWrap
                    width: heart.implicitWidth
                    height: heart.implicitHeight

                    property real swayAmount: Kirigami.Units.gridUnit * (1.0 + Math.random() * 1.2)

                    Label {
                        id: heart
                        text: "❤"
                        color: ["#ff6b81", "#4dabf7", "#ffd166", "#63e6be", "#b197fc", "#ff8fab"][index % 6]
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * (1.0 + (index % 4) * 0.3)
                        opacity: 0
                        scale: 0.85
                    }

                    function rise(delay) {
                        heartWrap.x = Math.random() * (heartsContainer.width - heartWrap.width);
                        heartWrap.y = heartsContainer.height + 20;
                        riseAnim.startDelayMs = delay;
                        riseAnim.startX = heartWrap.x;
                        riseAnim.restart();
                    }

                    SequentialAnimation {
                        id: riseAnim
                        property int startDelayMs: 0
                        property real startX: 0

                        PauseAnimation { duration: riseAnim.startDelayMs }
                        ParallelAnimation {
                            NumberAnimation { target: heartWrap; property: "y"; to: -60; duration: 2000; easing.type: Easing.OutQuad }

                            SequentialAnimation {
                                loops: 3
                                NumberAnimation { target: heartWrap; property: "x"; to: riseAnim.startX + heartWrap.swayAmount; duration: 330; easing.type: Easing.InOutSine }
                                NumberAnimation { target: heartWrap; property: "x"; to: riseAnim.startX - heartWrap.swayAmount; duration: 330; easing.type: Easing.InOutSine }
                            }

                            SequentialAnimation {
                                loops: 2
                                NumberAnimation { target: heart; property: "scale"; from: 0.85; to: 1.08; duration: 420; easing.type: Easing.InOutSine }
                                NumberAnimation { target: heart; property: "scale"; from: 1.08; to: 0.85; duration: 420; easing.type: Easing.InOutSine }
                            }

                            SequentialAnimation {
                                NumberAnimation { target: heart; property: "opacity"; from: 0; to: 0.85; duration: 300 }
                                PauseAnimation { duration: 1200 }
                                NumberAnimation { target: heart; property: "opacity"; from: 0.85; to: 0; duration: 500 }
                            }
                        }
                    }
                }
            }
        }

        Item {
            id: wordsContainer
            anchors.fill: parent
            clip: true

            Repeater {
                id: wordsRepeater
                model: 6

                readonly property var phrases: [
                    i18n("Thank you!"),
                    i18n("You're amazing!"),
                    i18n("You rock!"),
                    i18n("You're the best!"),
                    i18n("Much appreciated!"),
                    i18n("Awesome!")
                ]
                readonly property var accents: ["#ff6b81", "#4dabf7", "#ffd166", "#63e6be", "#b197fc", "#ff8fab"]

                function launch() {
                    for (let i = 0; i < count; i++) {
                        itemAt(i).rise(i * 160 + Math.random() * 90);
                    }
                }

                Rectangle {
                    id: wordChip
                    property color accent: wordsRepeater.accents[index % wordsRepeater.accents.length]
                    property real swayAmount: Kirigami.Units.gridUnit * (0.5 + Math.random() * 0.5)

                    width: wordLabel.implicitWidth + Kirigami.Units.gridUnit * 1.1
                    height: wordLabel.implicitHeight + Kirigami.Units.smallSpacing * 1.1
                    radius: height / 2
                    color: Qt.rgba(accent.r, accent.g, accent.b, 0.16)
                    border.width: 1
                    border.color: Qt.rgba(accent.r, accent.g, accent.b, 0.45)
                    opacity: 0
                    scale: 0.85

                    Label {
                        id: wordLabel
                        anchors.centerIn: parent
                        text: wordsRepeater.phrases[index % wordsRepeater.phrases.length]
                        color: Kirigami.Theme.textColor
                        font.bold: true
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.85
                    }

                    function rise(delay) {
                        wordChip.x = Kirigami.Units.gridUnit * 1.5 + Math.random() * (wordsContainer.width - wordChip.width - Kirigami.Units.gridUnit * 3);
                        wordChip.y = wordsContainer.height + 20;
                        wordRiseAnim.startDelayMs = delay;
                        wordRiseAnim.startX = wordChip.x;
                        wordRiseAnim.restart();
                    }

                    SequentialAnimation {
                        id: wordRiseAnim
                        property int startDelayMs: 0
                        property real startX: 0

                        PauseAnimation { duration: wordRiseAnim.startDelayMs }
                        ParallelAnimation {
                            NumberAnimation { target: wordChip; property: "y"; to: -40; duration: 1800; easing.type: Easing.OutQuad }
                            NumberAnimation { target: wordChip; property: "scale"; from: 0.85; to: 1; duration: 300; easing.type: Easing.OutBack }

                            SequentialAnimation {
                                loops: 2
                                NumberAnimation { target: wordChip; property: "x"; to: wordRiseAnim.startX + wordChip.swayAmount; duration: 450; easing.type: Easing.InOutSine }
                                NumberAnimation { target: wordChip; property: "x"; to: wordRiseAnim.startX - wordChip.swayAmount; duration: 450; easing.type: Easing.InOutSine }
                            }

                            SequentialAnimation {
                                NumberAnimation { target: wordChip; property: "opacity"; from: 0; to: 0.95; duration: 250 }
                                PauseAnimation { duration: 1050 }
                                NumberAnimation { target: wordChip; property: "opacity"; from: 0.95; to: 0; duration: 500 }
                            }
                        }
                    }
                }
            }
        }

        Rectangle {
            id: toastCard
            property real baseY: (parent.height - height) / 2

            x: (parent.width - width) / 2
            y: baseY
            width: Math.max(toastColumn.implicitWidth + Kirigami.Units.gridUnit * 3.2, Kirigami.Units.gridUnit * 17)
            height: toastColumn.implicitHeight + Kirigami.Units.gridUnit * 1.6
            radius: Kirigami.Units.gridUnit * 0.6
            color: Kirigami.Theme.backgroundColor
            border.width: 1
            border.color: Qt.rgba(Kirigami.Theme.textColor.r, Kirigami.Theme.textColor.g, Kirigami.Theme.textColor.b, 0.12)
            opacity: 0
            scale: 0.85
            transformOrigin: Item.Center

            Rectangle {
                anchors.fill: parent
                anchors.margins: -3
                radius: parent.radius + 3
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(Kirigami.Theme.highlightColor.r, Kirigami.Theme.highlightColor.g, Kirigami.Theme.highlightColor.b, 0.18)
                z: -1
            }

            ColumnLayout {
                id: toastColumn
                anchors.centerIn: parent
                spacing: Kirigami.Units.smallSpacing * 0.8

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Kirigami.Units.smallSpacing

                    Kirigami.Icon {
                        source: "emblem-favorite"
                        color: "#ff6b81"
                        implicitWidth: Kirigami.Units.iconSizes.medium
                        implicitHeight: Kirigami.Units.iconSizes.medium
                    }

                    Label {
                        text: celebrationOverlay.messageText
                        color: Kirigami.Theme.textColor
                        font.bold: true
                        font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.5
                    }
                }

                Label {
                    Layout.alignment: Qt.AlignHCenter
                    visible: text.length > 0
                    text: celebrationOverlay.subText
                    color: Kirigami.Theme.textColor
                    opacity: 0.6
                    font.pointSize: Kirigami.Theme.defaultFont.pointSize * 0.95
                }
            }
        }
    }
}
