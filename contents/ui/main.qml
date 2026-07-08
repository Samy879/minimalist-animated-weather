import QtQuick
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import "components" as Components

PlasmoidItem {
  id: root
  width: compactRepresentation.implicitWidth

  Components.WeatherData {
    id: weatherSource
  }

  Plasmoid.contextualActions: [
    PlasmaCore.Action {
      text: i18n("Refresh now")
      icon.name: "view-refresh"
      onTriggered: weatherSource.updateWeather()
    }
  ]

  // Propriétés de configuration (Lien avec main.xml)
  property bool showConditionPanel: Plasmoid.configuration.showConditionPanel
  property int borderRadius: Plasmoid.configuration.borderRadius
  property real backgroundOpacity: Plasmoid.configuration.backgroundOpacity
  property bool interactiveYAxis: Plasmoid.configuration.interactiveYAxis
  property bool hoverDecimals: Plasmoid.configuration.hoverDecimals
  property bool xAxisPrecision: Plasmoid.configuration.xAxisPrecision
  property bool showAnimations: Plasmoid.configuration.showAnimations
  property bool temperaturePanelBold: Plasmoid.configuration.temperaturePanelBold
  property bool conditionPanelBold: Plasmoid.configuration.conditionPanelBold
  property bool reverseOrder: Plasmoid.configuration.reverseOrder
  property int temperatureUnit: Plasmoid.configuration.temperatureUnit
  property real temperatureFontSize: Plasmoid.configuration.temperatureFontSize
  property real conditionFontSize: Plasmoid.configuration.conditionFontSize

  property bool preciseTemp: Plasmoid.configuration.preciseTemp
  property bool yAxisDecimals: Plasmoid.configuration.yAxisDecimals

  // Gère l'affichage du titre dans la vue détaillée
  property bool showConditionExpanded: Plasmoid.configuration.showConditionExpanded

  property bool showTemperaturePanel: Plasmoid.configuration.showTemperaturePanel
  property int forecastStartDay: Plasmoid.configuration.forecastStartDay

  // Référence vers la FullRepresentation pour pouvoir appeler resetScroll()
  property var fullRepRef: null

  property var days: []
  Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
  preferredRepresentation: Plasmoid.formFactor === PlasmaCore.Types.Planar ? fullRepresentation : compactRepresentation

  Component.onCompleted: {
    let locale = Qt.locale();
    let tempDays = [];
    for (let i = 0; i < 7; i++) {
      tempDays.push(locale.dayName(i, Locale.ShortFormat));
    }
    days = tempDays;
  }

  compactRepresentation: CompactRepresentation {
    weatherData: weatherSource
  }

  fullRepresentation: FullRepresentation {
    weatherData: weatherSource
    Component.onCompleted: root.fullRepRef = this
  }

  Connections {
    target: root
    function onExpandedChanged() {
      if (root.expanded && root.fullRepRef) {
        root.fullRepRef.resetScroll();
      }
    }
  }
}
