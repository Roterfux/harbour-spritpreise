import QtQuick 2.2
import Sailfish.Silica 1.0
import "../js/api.js" as Api

Page {
    id: page
    allowedOrientations: Orientation.All

    property bool askedForLocation: false

    onStatusChanged: {
        if (status === PageStatus.Active && !app.hasLocation && !askedForLocation) {
            askedForLocation = true
            pageStack.animatorPush(Qt.resolvedUrl("LocationPage.qml"))
        }
    }

    SilicaListView {
        id: list
        anchors.fill: parent
        model: app.stationsModel

        PullDownMenu {
            busy: app.loading
            MenuItem {
                text: qsTr("Settings")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("SettingsPage.qml"))
            }
            MenuItem {
                text: qsTr("Change location")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("LocationPage.qml"))
            }
            MenuItem {
                text: qsTr("Refresh")
                enabled: app.hasLocation && !app.loading
                onClicked: app.refresh()
            }
        }

        header: Column {
            width: list.width

            PageHeader {
                title: app.fuelLabel
                description: app.hasLocation ? app.locationLabel : ""
            }

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

            Label {
                visible: app.errorText !== "" && list.count > 0
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                text: app.errorText
                color: Theme.errorColor
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.Wrap
            }

            Label {
                visible: list.count > 0
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                text: (app.lastUpdated
                       ? qsTr("Updated %1").arg(Qt.formatTime(app.lastUpdated, "hh:mm")) + " · "
                       : "")
                      + qsTr("Prices may only rise at 12:00")
                color: Theme.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeExtraSmall
                wrapMode: Text.Wrap
            }

            Item { width: 1; height: Theme.paddingMedium }
        }

        delegate: ListItem {
            id: item
            contentHeight: Math.max(Theme.itemSizeMedium, info.height + 2 * Theme.paddingMedium)
            opacity: model.open ? 1.0 : 0.6

            Column {
                id: info
                anchors {
                    left: parent.left
                    leftMargin: Theme.horizontalPageMargin
                    right: priceLabel.left
                    rightMargin: Theme.paddingMedium
                    verticalCenter: parent.verticalCenter
                }

                Label {
                    width: parent.width
                    text: model.name
                    truncationMode: TruncationMode.Fade
                    color: item.highlighted ? Theme.highlightColor : Theme.primaryColor
                }
                Label {
                    width: parent.width
                    text: [model.address, model.city].filter(function(s) { return s }).join(", ")
                    truncationMode: TruncationMode.Fade
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: item.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                }
                Label {
                    width: parent.width
                    text: [app.formatDistance(model.distance),
                           model.open ? "" : qsTr("closed")]
                          .filter(function(s) { return s }).join(" · ")
                    visible: text !== ""
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: item.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                }
            }

            Label {
                id: priceLabel
                anchors {
                    right: parent.right
                    rightMargin: Theme.horizontalPageMargin
                    verticalCenter: parent.verticalCenter
                }
                text: app.formatPrice(model.price)
                font.pixelSize: Theme.fontSizeLarge
                color: model.price > 0
                       ? (index === 0 && app.sortBy === "price" ? Theme.highlightColor : Theme.primaryColor)
                       : Theme.secondaryColor
            }

            menu: ContextMenu {
                MenuItem {
                    text: qsTr("Navigate")
                    onClicked: Qt.openUrlExternally("geo:" + model.lat + "," + model.lng)
                            || Qt.openUrlExternally("https://www.openstreetmap.org/?mlat="
                                                    + model.lat + "&mlon=" + model.lng
                                                    + "#map=17/" + model.lat + "/" + model.lng)
                }
            }

            onClicked: pageStack.animatorPush(Qt.resolvedUrl("StationPage.qml"), {
                station: JSON.parse(model.raw),
                price: model.price,
                distance: model.distance
            })
        }

        ViewPlaceholder {
            enabled: list.count === 0 && !app.loading
            text: !app.hasLocation ? qsTr("No location set")
                                   : (app.errorText !== "" ? app.errorText : qsTr("No stations found"))
            hintText: !app.hasLocation ? qsTr("Pull down to enter an address")
                                       : qsTr("Pull down to refresh")
        }

        VerticalScrollDecorator {}
    }

    BusyIndicator {
        anchors.centerIn: parent
        size: BusyIndicatorSize.Large
        running: app.loading && list.count === 0
    }
}
