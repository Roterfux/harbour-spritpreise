import QtQuick 2.2
import Sailfish.Silica 1.0
import "../js/api.js" as Api

Page {
    id: page
    allowedOrientations: Orientation.All

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge

        Column {
            id: column
            width: parent.width

            PageHeader { title: qsTr("Settings") }

            ComboBox {
                label: qsTr("Fuel")
                currentIndex: Api.fuelIndex(app.fuelType)
                menu: ContextMenu {
                    Repeater {
                        model: Api.FUEL_TYPES
                        MenuItem {
                            text: modelData.label
                            onClicked: app.setFuelType(modelData.code)
                        }
                    }
                }
            }

            ComboBox {
                label: qsTr("Sort by")
                currentIndex: app.sortBy === "distance" ? 1 : 0
                menu: ContextMenu {
                    MenuItem { text: qsTr("Price"); onClicked: app.setSortBy("price") }
                    MenuItem { text: qsTr("Distance"); onClicked: app.setSortBy("distance") }
                }
            }

            TextSwitch {
                text: qsTr("Include closed stations")
                checked: app.includeClosed
                onClicked: app.setIncludeClosed(checked)
            }

            SectionHeader { text: qsTr("About") }

            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                wrapMode: Text.Wrap
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.secondaryHighlightColor
                text: qsTr("Prices: E-Control Spritpreisrechner (spritpreisrechner.at). "
                           + "The service only returns prices for the cheapest stations "
                           + "of each search, so some stations may show no price. "
                           + "Stations may raise prices only once a day, at 12:00; "
                           + "they can lower them at any time.")
                      + "\n\n"
                      + qsTr("Address search: Nominatim, © OpenStreetMap contributors (ODbL).")
            }
        }

        VerticalScrollDecorator {}
    }
}
