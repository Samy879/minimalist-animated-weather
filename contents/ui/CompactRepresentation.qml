import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import "js/UnitConverter.js" as UnitConverter

Item {
    id: iconAndTem

    // Toujours fourni explicitement par main.qml (compactRepresentation: CompactRepresentation { weatherData: weatherSource }).
    property var weatherData: null

    // Comme fullRepRef pour FullRepresentation dans main.qml : "expanded" vit
    // uniquement sur PlasmoidItem (root) en Plasma 6, pas sur l'attached
    // property Plasmoid — donc pas moyen de l'atteindre depuis ce fichier
    // séparé sans que main.qml nous le transmette explicitement.
    property var plasmoidRoot: null

    // Confirmé via main.qml : root n'expose qu'un width (dérivé de
    // compactRepresentation.implicitWidth — donc circulaire si on l'utilisait
    // ici) et aucun height du tout. L'idiome standard pour lire la taille
    // réellement disponible depuis un compactRepresentation est son parent
    // (le conteneur fourni par le panneau), pas une propriété de root.
    Layout.minimumWidth: isVertical ? parent.width : initial.implicitWidth
    Layout.minimumHeight: isVertical ? wrapper_vertical.implicitHeight : parent.height

    readonly property bool isVertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical

    // --- PROPRIÉTÉS DE CONFIGURATION ---
    property bool showTemperatureText: Plasmoid.configuration.showTemperaturePanel
    property real fontTemp: Plasmoid.configuration.temperatureFontSize
    property real fontCond: Plasmoid.configuration.conditionFontSize
    property bool reverseOrder: Plasmoid.configuration.reverseOrder

    readonly property bool showCondition: Plasmoid.configuration.showConditionPanel || false
    // "root" n'existe pas dans ce document (un id est local au fichier QML où
    // il est déclaré, jamais visible depuis un fichier importé séparément —
    // même en relation parent/enfant à l'exécution). Ces deux-là manquaient
    // à l'appel, contrairement à toutes les autres valeurs de config
    // ci-dessus qui suivent déjà l'idiome Plasmoid.configuration.X.
    property bool preciseTemp: Plasmoid.configuration.preciseTemp
    property int temperatureUnit: Plasmoid.configuration.temperatureUnit

    MouseArea {
        id: panelMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        // "expanded" vit sur PlasmoidItem (root), pas sur l'attached property
        // Plasmoid en Plasma 6 : Plasmoid.expanded est un no-op silencieux.
        // On passe donc par plasmoidRoot, transmis explicitement par main.qml
        // (compactRepresentation: CompactRepresentation { plasmoidRoot: root }).
        onClicked: {
            if (plasmoidRoot) plasmoidRoot.expanded = !plasmoidRoot.expanded
        }
    }

    // Léger retour tactile au clic — cohérent avec les éléments interactifs
    // de la vue complète (bouton retour, jours de prévisions cliquables).
    opacity: panelMouse.pressed ? 0.75 : 1.0
    Behavior on opacity { NumberAnimation { duration: 120 } }

    // --- MODE HORIZONTAL (Panel en bas/haut) ---
    RowLayout {
        id: initial
        anchors.fill: parent
        visible: !isVertical
        spacing: 4

        Kirigami.Icon {
            id: icon
            Layout.preferredWidth: parent.height * 0.9
            Layout.preferredHeight: parent.height * 0.9
            Layout.alignment: Qt.AlignVCenter
            source: weatherData.iconWeatherCurrent

            isMask: false
            smooth: true
            roundToIconSize: false
        }

        // Utilisation d'un GridLayout pour permettre l'inversion des lignes
        GridLayout {
            columns: 1
            rowSpacing: 0
            Layout.alignment: Qt.AlignVCenter
            visible: showTemperatureText || showCondition

            // 1. BLOC TEMPÉRATURE
            Row {
                id: tempRow
                visible: showTemperatureText
                // Si reverseOrder est vrai, on passe à la ligne 1 (bas), sinon ligne 0 (haut)
                Layout.row: reverseOrder ? 1 : 0

                PlasmaComponents3.Label {
                    text: preciseTemp ? weatherData.currentTemperature : weatherData.currentTemperatureRounded
                    font.bold: Plasmoid.configuration.temperaturePanelBold // Mise en gras spécifique température
                    font.pixelSize: fontTemp
                }
                PlasmaComponents3.Label {
                    text: UnitConverter.temperatureUnitLabel(temperatureUnit)
                    font.bold: Plasmoid.configuration.temperaturePanelBold // Mise en gras spécifique température
                    font.pixelSize: fontTemp
                }
            }

            // 2. BLOC CONDITION (Texte court)
            PlasmaComponents3.Label {
                id: conditionLabel
                text: weatherData.weatherShortText
                // Si reverseOrder est vrai, on passe à la ligne 0 (haut), sinon ligne 1 (bas)
                Layout.row: reverseOrder ? 0 : 1
                font.pixelSize: fontCond
                font.bold: Plasmoid.configuration.conditionPanelBold // Mise en gras spécifique condition
                opacity: 0.9
                visible: showCondition
                Layout.fillWidth: true
            }
        }
    }

    // --- MODE VERTICAL (Panel à gauche/droite) ---
    ColumnLayout {
        id: wrapper_vertical
        anchors.fill: parent
        visible: isVertical
        spacing: 2

        Kirigami.Icon {
            Layout.preferredWidth: parent.width * 0.8
            Layout.preferredHeight: parent.width * 0.8
            Layout.alignment: Qt.AlignHCenter
            source: weatherData.iconWeatherCurrent
            isMask: false
            smooth: true
            roundToIconSize: false
        }

        PlasmaComponents3.Label {
            text: weatherData.currentTemperature + UnitConverter.temperatureUnitLabel(temperatureUnit)
            Layout.alignment: Qt.AlignHCenter
            font.pixelSize: fontTemp
            font.bold: Plasmoid.configuration.temperaturePanelBold // Appliqué ici aussi pour la température
        }
    }
}
