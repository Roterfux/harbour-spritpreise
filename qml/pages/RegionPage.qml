import QtQuick 2.2
import Sailfish.Silica 1.0
import "../js/api.js" as Api

Page {
    id: page
    allowedOrientations: Orientation.All

    property bool loading: true
    property string errorText: ""

    ListModel { id: regionsModel }

    function load() {
        loading = true
        errorText = ""
        Api.regions(function(err, list) {
            loading = false
            if (err) {
                errorText = err
                return
            }
            regionsModel.clear()
            for (var i = 0; i < list.length; i++) regionsModel.append(list[i])
        })
    }

    function choose(label, code, type) {
        app.setRegion(label, code, type)
        var main = pageStack.find(function(p) { return p.hasOwnProperty("askedForLocation") })
        if (main) pageStack.pop(main)
        else pageStack.navigateBack()
    }

    Component.onCompleted: load()

    SilicaListView {
        id: list
        anchors.fill: parent
        model: regionsModel

        PullDownMenu {
            visible: page.errorText !== ""
            MenuItem { text: qsTr("Retry"); onClicked: page.load() }
        }

        header: PageHeader {
            title: qsTr("Region")
            description: qsTr("Bundesland or Bezirk")
        }

        section.property: "state"
        section.delegate: SectionHeader { text: section }

        delegate: ListItem {
            id: item
            Label {
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * Theme.horizontalPageMargin
                anchors.verticalCenter: parent.verticalCenter
                text: model.whole ? qsTr("All of %1").arg(model.name) : model.name
                font.italic: model.whole
                truncationMode: TruncationMode.Fade
                color: item.highlighted ? Theme.highlightColor : Theme.primaryColor
            }
            onClicked: page.choose(model.whole ? model.name : model.name + ", " + model.state,
                                   model.code, model.type)
        }

        ViewPlaceholder {
            enabled: !page.loading && regionsModel.count === 0
            text: page.errorText !== "" ? page.errorText : qsTr("No regions")
            hintText: page.errorText !== "" ? qsTr("Pull down to retry") : ""
        }

        VerticalScrollDecorator {}
    }

    BusyIndicator {
        anchors.centerIn: parent
        size: BusyIndicatorSize.Large
        running: page.loading
    }
}
