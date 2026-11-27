import QtQuick 2.2
import Sailfish.Silica 1.0

Page {
    id: page
    allowedOrientations: Orientation.All

    property var station: ({})
    property real price: -1
    property real distance: -1

    readonly property var loc: station.location || {}
    readonly property var contact: station.contact || {}
    readonly property var payment: station.paymentMethods || {}
    readonly property var offer: station.offerInformation || {}
    readonly property var hours: station.openingHours || []

    function navigate() {
        var lat = loc.latitude, lng = loc.longitude
        if (!Qt.openUrlExternally("geo:" + lat + "," + lng))
            Qt.openUrlExternally("https://www.openstreetmap.org/?mlat=" + lat + "&mlon=" + lng
                                 + "#map=17/" + lat + "/" + lng)
    }

    function paymentText() {
        var p = []
        if (payment.cash) p.push(qsTr("Cash"))
        if (payment.debitCard) p.push(qsTr("Debit card"))
        if (payment.creditCard) p.push(qsTr("Credit card"))
        if (payment.others) p.push(payment.others)
        return p.join(", ")
    }

    function serviceText() {
        var s = []
        if (offer.service) s.push(qsTr("Service"))
        if (offer.selfService) s.push(qsTr("Self-service"))
        if (offer.unattended) s.push(qsTr("Unattended"))
        return s.join(", ")
    }

    function websiteUrl() {
        var w = String(contact.website || "")
        if (w === "") return ""
        return w.indexOf("http") === 0 ? w : "https://" + w
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge

        PullDownMenu {
            MenuItem {
                text: qsTr("Open website")
                visible: page.websiteUrl() !== ""
                onClicked: Qt.openUrlExternally(page.websiteUrl())
            }
            MenuItem {
                text: qsTr("Call")
                visible: !!page.contact.telephone
                onClicked: Qt.openUrlExternally("tel:" + String(page.contact.telephone).replace(/\s/g, ""))
            }
            MenuItem {
                text: qsTr("Navigate")
                onClicked: page.navigate()
            }
        }

        Column {
            id: column
            width: parent.width

            PageHeader {
                title: page.station.name || ""
                description: page.station.open === false ? qsTr("Closed now") : qsTr("Open now")
            }

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: app.formatPrice(page.price)
                font.pixelSize: Theme.fontSizeHuge
                color: Theme.highlightColor
            }
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: page.price > 0 ? app.fuelLabel : qsTr("No price published")
                color: Theme.secondaryHighlightColor
                font.pixelSize: Theme.fontSizeSmall
            }

            SectionHeader { text: qsTr("Address") }

            DetailItem {
                label: qsTr("Street")
                value: page.loc.address || ""
                visible: value !== ""
            }
            DetailItem {
                label: qsTr("Town")
                value: [page.loc.postalCode, page.loc.city].filter(function(s) { return s }).join(" ")
                visible: value !== ""
            }
            DetailItem {
                label: qsTr("Distance")
                value: app.formatDistance(page.distance)
                visible: value !== ""
            }

            SectionHeader {
                text: qsTr("Opening hours")
                visible: page.hours.length > 0
            }
            Repeater {
                model: page.hours
                DetailItem {
                    label: modelData.label || modelData.day || ""
                    value: (modelData.from && modelData.to)
                           ? modelData.from + " – " + modelData.to : qsTr("closed")
                }
            }

            SectionHeader {
                text: qsTr("Details")
                visible: payDetail.visible || serviceDetail.visible || phoneDetail.visible
            }
            DetailItem {
                id: payDetail
                label: qsTr("Payment")
                value: page.paymentText()
                visible: value !== ""
            }
            DetailItem {
                id: serviceDetail
                label: qsTr("Service")
                value: page.serviceText()
                visible: value !== ""
            }
            DetailItem {
                id: phoneDetail
                label: qsTr("Phone")
                value: page.contact.telephone || ""
                visible: value !== ""
            }

            Item { width: 1; height: Theme.paddingLarge }

            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Navigate")
                onClicked: page.navigate()
            }
        }

        VerticalScrollDecorator {}
    }
}
