import QtQuick
import Qt5Compat.GraphicalEffects
import org.kde.kirigami as Kirigami

Item {
    id: cloudRoot
    anchors.fill: parent
    clip: true

    readonly property color cloudColor: Kirigami.Theme.textColor

    Repeater {
        model: 5

        delegate: Item {
            id: cloudDelegate

            property real progress: (1.0 / 5) * index

            property real currentY: Math.random() * (cloudRoot.height * 0.55)
            property real currentOp: 0.10 + (Math.random() * 0.15)

            property real baseScale: Math.min(1.0, Math.max(0.4, cloudRoot.width / 400))
            property real currentScale: baseScale * (0.6 + Math.random() * 0.4)

            // --- VITESSE LÉGÈREMENT RALENTIE ---
            // On augmente un peu la durée (55s de base) pour un mouvement plus apaisant
            property real currentDur: (100000 + (Math.random() * 100000)) / currentScale

            width: 300 * currentScale
            height: 120 * currentScale

            x: -width + (progress * (cloudRoot.width + width * 2))
            y: currentY

            opacity: Kirigami.Theme.brightness === Kirigami.Theme.Dark ? currentOp : currentOp * 0.6

            SequentialAnimation {
                running: true

                NumberAnimation {
                    target: cloudDelegate
                    property: "progress"
                    to: 1.0
                    duration: (1.0 - cloudDelegate.progress) * cloudDelegate.currentDur
                }

                SequentialAnimation {
                    loops: Animation.Infinite

                    ScriptAction {
                        script: {
                            cloudDelegate.currentY = Math.random() * (cloudRoot.height * 0.55);
                            cloudDelegate.currentScale = cloudDelegate.baseScale * (0.6 + Math.random() * 0.4);
                            // On applique le ralentissement ici aussi
                            cloudDelegate.currentDur = (55000 + (Math.random() * 55000)) / cloudDelegate.currentScale;
                        }
                    }

                    NumberAnimation {
                        target: cloudDelegate
                        property: "progress"
                        from: 0.0
                        to: 1.0
                        duration: cloudDelegate.currentDur
                    }
                }
            }

            Item {
                id: floatingContainer
                anchors.fill: parent

                SequentialAnimation on y {
                    loops: Animation.Infinite
                    NumberAnimation {
                        from: 0; to: 10 * currentScale;
                        duration: 20000 + (Math.random() * 10000); easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        from: 10 * currentScale; to: 0;
                        duration: 20000 + (Math.random() * 10000); easing.type: Easing.InOutSine
                    }
                }

                Item {
                    anchors.fill: parent

                    Rectangle { x: 20 * currentScale; y: 80 * currentScale; width: 260 * currentScale; height: 25 * currentScale; radius: 12 * currentScale; color: cloudRoot.cloudColor }
                    Rectangle { x: 40 * currentScale; y: 40 * currentScale; width: 70 * currentScale; height: 70 * currentScale; radius: width / 2; color: cloudRoot.cloudColor }
                    Rectangle { x: 90 * currentScale; y: 15 * currentScale; width: 100 * currentScale; height: 100 * currentScale; radius: width / 2; color: cloudRoot.cloudColor }
                    Rectangle { x: 170 * currentScale; y: 45 * currentScale; width: 60 * currentScale; height: 60 * currentScale; radius: width / 2; color: cloudRoot.cloudColor }
                }

                layer.enabled: true
                layer.effect: GaussianBlur {
                    radius: 6
                    samples: 16
                }
            }
        }
    }
}
