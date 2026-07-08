import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami

// Uniform "Restore Defaults" block shared by every settings page.
// Having a single component guarantees the reset control looks and
// behaves identically everywhere, instead of each page reinventing it.
//
// Usage:
//   ResetSection {
//       onConfirmed: {
//           cfg_someValue = Defaults.APPEARANCE.someValue;
//           ...
//       }
//   }
ColumnLayout {
    id: root

    Layout.fillWidth: true
    spacing: Kirigami.Units.largeSpacing

    property string message: i18n("Are you sure you want to restore this page's settings to their default values? This action cannot be undone.")

    signal confirmed()

    SectionHeader { text: i18n("Reset") }

    RowLayout {
        Layout.fillWidth: true

        SettingsCard {
            Layout.fillWidth: false
            implicitWidth: resetRow.implicitWidth + Kirigami.Units.largeSpacing * 2

            RowLayout {
                id: resetRow
                spacing: Kirigami.Units.smallSpacing

                Button {
                    text: i18n("Restore Defaults")
                    icon.name: "edit-undo"
                    onClicked: confirmDialog.open()
                }

                InfoIcon {
                    text: i18n("Resets every setting on this page to its factory default value.")
                }
            }
        }

        Item { Layout.fillWidth: true }
    }

    MessageDialog {
        id: confirmDialog
        title: i18n("Restore Defaults")
        text: root.message
        buttons: MessageDialog.Yes | MessageDialog.No
        onAccepted: root.confirmed()
    }
}
