import QtQuick 2.2
import Sailfish.Silica 1.0

CoverBackground {
    id: cover

    Column {
        anchors {
            left: parent.left; right: parent.right
            margins: Theme.paddingLarge
            verticalCenter: parent.verticalCenter
            verticalCenterOffset: -Theme.paddingLarge
        }
        spacing: Theme.paddingSmall

        Label {
            width: parent.width
            text: app.fuelLabel
            color: Theme.secondaryHighlightColor
            font.pixelSize: Theme.fontSizeSmall
            truncationMode: TruncationMode.Fade
        }
        Label {
            width: parent.width
            text: app.cheapest ? app.formatPrice(app.cheapest.price)
                               : (app.loading ? "…" : "–")
            color: Theme.highlightColor
            font.pixelSize: Theme.fontSizeExtraLarge
            fontSizeMode: Text.HorizontalFit
        }
        Label {
            width: parent.width
            text: app.cheapest ? app.cheapest.name
                               : (app.hasLocation ? "" : qsTr("No location"))
            color: Theme.primaryColor
            font.pixelSize: Theme.fontSizeSmall
            wrapMode: Text.Wrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }
        Label {
            width: parent.width
            text: app.locationLabel
            visible: text !== ""
            color: Theme.secondaryColor
            font.pixelSize: Theme.fontSizeExtraSmall
            truncationMode: TruncationMode.Fade
        }
        Label {
            width: parent.width
            text: app.lastUpdated ? Qt.formatTime(app.lastUpdated, "hh:mm") : ""
            visible: text !== ""
            color: Theme.secondaryColor
            font.pixelSize: Theme.fontSizeExtraSmall
        }
    }

    CoverActionList {
        enabled: app.hasLocation
        CoverAction {
            iconSource: "image://theme/icon-cover-refresh"
            onTriggered: app.refresh()
        }
    }
}
