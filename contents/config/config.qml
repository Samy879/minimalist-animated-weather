import QtQuick
import org.kde.plasma.configuration

ConfigModel {
	// Les icônes de la barre latérale pointent vers les SVG du plasmoïde
	// (contents/ui/icons/) plutôt que vers le thème d'icônes système, pour
	// un rendu identique sur toutes les distributions/thèmes.
	// config.qml se trouve dans contents/config/, d'où le "../ui/icons/...".
	ConfigCategory {
		name: i18n("Source & Location")
		icon: Qt.resolvedUrl("../icons/source-location.svg")
		source: "settings/ConfigSource.qml"
	}
	ConfigCategory {
		name: i18n("Appearance")
		// Icône du thème système (le fichier local livré avec le plasmoïde
		// une icône du thème d'icônes système, garantie disponible sur
		// toutes les distributions/thèmes Plasma.
		icon: "preferences-desktop-theme"
		source: "settings/ConfigAppearance.qml"
	}
	ConfigCategory {
		name: i18n("Data & Charts")
		icon: Qt.resolvedUrl("../icons/data-charts.svg")
		source: "settings/ConfigData.qml"
	}
	ConfigCategory {
		name: i18n("Support & Community")
		icon: Qt.resolvedUrl("../icons/support-community.svg")
		source: "settings/ConfigSupport.qml"
	}
}
