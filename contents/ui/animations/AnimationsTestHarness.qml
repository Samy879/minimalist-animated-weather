import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami

Kirigami.ApplicationWindow {
    id: window
    width: 800
    height: 600
    visible: true
    title: "Testeur d'Animations Final"

    property bool isDark: true

    // Couleurs du plasmoid
    readonly property color bgColor: isDark ? "#1a1b26" : "#f0f2f5"
    readonly property color fgColor: isDark ? "white" : "black"

    // On utilise un fond neutre pour la fenêtre "bureau"
    color: isDark ? "#000000" : "#aaaaaa"

    Kirigami.Theme.inherit: false
    Kirigami.Theme.colorSet: Kirigami.Theme.Window

    // =======================================================
    // LA "BOÎTE" DU PLASMOID (Simulation de FullRepresentation)
    // =======================================================
    Rectangle {
        id: plasmoidContainer
        width: Kirigami.Units.gridUnit * 18 // ~ contentWidth
        height: Kirigami.Units.gridUnit * 12.5 // ~ calculatedHeight
        anchors.centerIn: parent
        radius: 12
        color: window.bgColor
        clip: true

        // 1. L'Animation en arrière-plan
        Loader {
            id: animLoader
            anchors.fill: parent
            source: "Rain.qml"
        }

        // 2. L'Interface au-dessus (Calquée sur FullRepresentation.qml)
        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // --- HEADER SECTION (Température & Condition) ---
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Kirigami.Units.gridUnit * 0.5
                Layout.leftMargin: Kirigami.Units.gridUnit
                Layout.rightMargin: Kirigami.Units.gridUnit
                spacing: 0

                Row {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 0

                    Text {
                        text: "12"
                        font.pixelSize: Kirigami.Units.gridUnit * 2.5
                        font.bold: true
                        color: window.fgColor
                    }
                    Text {
                        text: "°C"
                        font.pixelSize: Kirigami.Units.gridUnit * 1.5
                        font.bold: true
                        topPadding: Kirigami.Units.gridUnit * 0.2
                        color: window.fgColor
                    }
                }

                Text {
                    text: "Averses de pluie"
                    Layout.alignment: Qt.AlignVCenter
                    Layout.fillWidth: true
                    Layout.leftMargin: Kirigami.Units.gridUnit * 0.6
                    font.pixelSize: Kirigami.Units.gridUnit * 1.0
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    color: window.fgColor
                }
            }

            Item { Layout.fillHeight: true } // Espaceur flexible

            // --- FORECAST SECTION (Jours de la semaine) ---
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 5
                spacing: 0

                Repeater {
                    model: ["Auj", "Jeu", "Ven"]
                    delegate: ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            Layout.fillWidth: true
                            text: modelData
                            horizontalAlignment: Text.AlignHCenter
                            font.pixelSize: Kirigami.Units.gridUnit * 0.65
                            opacity: 0.8
                            color: window.fgColor
                        }

                        // Fausse icône
                        Item {
                            Layout.preferredWidth: Kirigami.Units.gridUnit * 2.7
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 2.7
                            Layout.alignment: Qt.AlignHCenter
                            Text {
                                anchors.centerIn: parent
                                text: index === 0 ? "🌧️" : "☁️" // Icône bidon pour le test
                                font.pixelSize: Kirigami.Units.gridUnit * 1.2
                            }
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 4
                            Text {
                                text: (15 - index) + "°"
                                font.bold: true
                                font.pixelSize: Kirigami.Units.gridUnit * 0.75
                                color: window.fgColor
                            }
                            Text {
                                text: (8 - index) + "°"
                                opacity: 0.6
                                font.pixelSize: Kirigami.Units.gridUnit * 0.75
                                color: window.fgColor
                            }
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true } // Espaceur flexible

            // --- DETAILS ROW (Vent, Humidité, etc.) ---
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2.2
                Layout.leftMargin: Kirigami.Units.gridUnit * 0.5
                Layout.rightMargin: Kirigami.Units.gridUnit * 0.5
                Layout.bottomMargin: Kirigami.Units.gridUnit * 0.5
                spacing: Kirigami.Units.smallSpacing

                Repeater {
                    model: [
                        { label: "Vent", val: "18", unit: "km/h" },
                        { label: "Humidité", val: "82", unit: "%" },
                        { label: "Précip.", val: "4", unit: "mm" }
                    ]
                    delegate: RowLayout {
                        Layout.fillWidth: true
                        spacing: Kirigami.Units.smallSpacing

                        Rectangle {
                            visible: index > 0
                            Layout.preferredWidth: 1
                            Layout.preferredHeight: Kirigami.Units.gridUnit * 1.2
                            color: window.fgColor
                            opacity: 0.15
                            Layout.alignment: Qt.AlignVCenter
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: modelData.label
                                font.pixelSize: Kirigami.Units.gridUnit * 0.52
                                opacity: 0.60
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                color: window.fgColor
                            }
                            Row {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 2
                                Text {
                                    text: modelData.val
                                    font.pixelSize: Kirigami.Units.gridUnit * 0.72
                                    font.bold: true
                                    color: window.fgColor
                                }
                                Text {
                                    text: modelData.unit
                                    font.pixelSize: Kirigami.Units.gridUnit * 0.53
                                    font.bold: true
                                    anchors.baseline: parent.children[0].baseline
                                    color: window.fgColor
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // =======================================================
    // PANNEAU DE CONTRÔLE (Hors du widget)
    // =======================================================
    footer: ToolBar {
        Row {
            anchors.centerIn: parent
            spacing: 20
            Button {
                text: window.isDark ? "Passer en mode CLAIR" : "Passer en mode SOMBRE"
                onClicked: window.isDark = !window.isDark
            }
            ComboBox {
                width: 180
                model: ["Rain.qml", "Snow.qml", "Mist.qml", "Sun.qml", "Night.qml", "Storm.qml", "Cloud.qml", "Wind.qml", "Hail.qml", "Drizzle.qml", "Rainbow.qml"]
                onActivated: (index) => animLoader.source = model[index]
            }
        }
    }
}
