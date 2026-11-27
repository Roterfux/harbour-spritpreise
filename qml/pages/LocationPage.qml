import QtQuick 2.2
import Sailfish.Silica 1.0
import "../js/api.js" as Api

Page {
    id: page
    allowedOrientations: Orientation.All

    property bool searching: false
    property string errorText: ""
    property bool showingResults: false
    property var lastSearch: null

    ListModel { id: placesModel }

    function loadSaved() {
        showingResults = false
        placesModel.clear()
        var saved = app.savedPlaces()
        for (var i = 0; i < saved.length; i++) {
            placesModel.append({ label: saved[i].label, description: saved[i].description || "",
                                 lat: saved[i].lat, lng: saved[i].lng, saved: true })
        }
    }

    function search(query) {
        query = query.trim()
        if (query.length < 3 || searching) return
        // Nominatim policy: at most one request per second.
        if (lastSearch && (new Date() - lastSearch) < 1000) return
        lastSearch = new Date()
        searching = true
        errorText = ""
        Api.geocode(query, function(err, results) {
            searching = false
            if (err) {
                errorText = err
                return
            }
            showingResults = true
            placesModel.clear()
            for (var i = 0; i < results.length; i++) {
                results[i].saved = false
                placesModel.append(results[i])
            }
            if (results.length === 0) errorText = qsTr("Nothing found in Austria")
        })
    }

    function choose(place) {
        app.addSavedPlace(place)
        app.setCoords(place.label, place.lat, place.lng)
        pageStack.navigateBack()
    }

    Component.onCompleted: loadSaved()

    SilicaListView {
        id: list
        anchors.fill: parent
        model: placesModel

        PullDownMenu {
            MenuItem {
                text: qsTr("Choose Bundesland / Bezirk")
                onClicked: pageStack.animatorPush(Qt.resolvedUrl("RegionPage.qml"))
            }
        }

        header: Column {
            width: list.width

            PageHeader { title: qsTr("Location") }

            SearchField {
                id: searchField
                width: parent.width
                placeholderText: qsTr("Address, place or postcode")
                inputMethodHints: Qt.ImhNoPredictiveText
                EnterKey.enabled: text.trim().length >= 3
                EnterKey.iconSource: "image://theme/icon-m-search"
                EnterKey.onClicked: page.search(text)
                onTextChanged: if (text === "" && page.showingResults) page.loadSaved()
                Component.onCompleted: if (!app.hasLocation) forceActiveFocus()
            }

            BusyIndicator {
                anchors.horizontalCenter: parent.horizontalCenter
                size: BusyIndicatorSize.Small
                running: page.searching
                visible: running
            }

            Label {
                visible: page.errorText !== ""
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                text: page.errorText
                color: Theme.errorColor
                wrapMode: Text.Wrap
            }

            SectionHeader {
                visible: placesModel.count > 0
                text: page.showingResults ? qsTr("Results") : qsTr("Recent places")
            }
        }

        delegate: ListItem {
            id: item
            contentHeight: Theme.itemSizeMedium

            Column {
                anchors {
                    left: parent.left; right: parent.right
                    leftMargin: Theme.horizontalPageMargin; rightMargin: Theme.horizontalPageMargin
                    verticalCenter: parent.verticalCenter
                }
                Label {
                    width: parent.width
                    text: model.label
                    truncationMode: TruncationMode.Fade
                    color: item.highlighted ? Theme.highlightColor : Theme.primaryColor
                }
                Label {
                    width: parent.width
                    text: model.description
                    visible: text !== "" && text !== model.label
                    truncationMode: TruncationMode.Fade
                    font.pixelSize: Theme.fontSizeExtraSmall
                    color: item.highlighted ? Theme.secondaryHighlightColor : Theme.secondaryColor
                }
            }

            onClicked: page.choose({ label: model.label, description: model.description,
                                     lat: model.lat, lng: model.lng })

            menu: model.saved ? savedMenu : null

            Component {
                id: savedMenu
                ContextMenu {
                    MenuItem {
                        text: qsTr("Remove")
                        onClicked: item.remorseDelete(function() {
                            app.removeSavedPlace(index)
                            page.loadSaved()
                        })
                    }
                }
            }
        }

        ViewPlaceholder {
            enabled: placesModel.count === 0 && !page.searching && page.errorText === ""
            text: qsTr("Enter an address")
            hintText: qsTr("or pull down to choose a region")
        }

        VerticalScrollDecorator {}
    }

    Label {
        anchors {
            bottom: parent.bottom; bottomMargin: Theme.paddingMedium
            horizontalCenter: parent.horizontalCenter
        }
        text: qsTr("Search © OpenStreetMap contributors")
        font.pixelSize: Theme.fontSizeTiny
        color: Theme.secondaryColor
    }
}
