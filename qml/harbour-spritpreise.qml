import QtQuick 2.2
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0
import "pages"
import "js/api.js" as Api

ApplicationWindow {
    id: app

    initialPage: Component { MainPage {} }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: defaultAllowedOrientations

    // ---- persisted settings ----
    ConfigurationGroup {
        id: config
        path: "/apps/harbour-spritpreise"

        property string fuelType: "SUP"
        property bool includeClosed: false
        property string sortBy: "price"       // "price" | "distance"
        property string mode: ""              // "coords" | "region" | ""
        property string label: ""
        property real lat: 0
        property real lng: 0
        property int regionCode: 0
        property string regionType: ""
        property string savedPlaces: "[]"     // JSON [{label, description, lat, lng}]
    }

    // ---- public state ----
    property alias fuelType: config.fuelType
    property alias includeClosed: config.includeClosed
    property alias sortBy: config.sortBy
    readonly property string fuelLabel: Api.fuelLabel(config.fuelType)
    readonly property string locationLabel: config.label
    readonly property bool hasLocation: (config.mode === "coords" && config.label !== "")
                                        || (config.mode === "region" && config.regionCode > 0)
    readonly property bool byRegion: config.mode === "region"

    property bool loading: false
    property string errorText: ""
    property var lastUpdated: null
    property var cheapest: null          // first station with a price
    property int requestId: 0

    property ListModel stationsModel: ListModel {}

    function formatPrice(p) {
        return p > 0 ? Number(p).toLocaleString(Qt.locale(), "f", 3) + " €" : "–"
    }

    function formatDistance(d) {
        if (d < 0) return ""
        return d < 1 ? Math.round(d * 1000) + " m"
                     : Number(d).toLocaleString(Qt.locale(), "f", 1) + " km"
    }

    function refresh() {
        if (!hasLocation) return
        var id = ++requestId
        loading = true
        errorText = ""
        timeout.restart()

        var done = function(err, list) {
            if (id !== requestId) return     // stale or timed out
            timeout.stop()
            loading = false
            if (err) {
                errorText = err
                return
            }
            Api.sortStations(list, config.sortBy)
            stationsModel.clear()
            var first = null
            for (var i = 0; i < list.length; i++) {
                stationsModel.append(list[i])
                if (!first && list[i].price > 0) first = list[i]
            }
            if (config.sortBy === "distance") {
                // cheapest is still the lowest price, not the nearest
                for (var j = 0; j < list.length; j++)
                    if (list[j].price > 0 && (!first || list[j].price < first.price))
                        first = list[j]
            }
            cheapest = first
            lastUpdated = new Date()
        }

        if (byRegion)
            Api.stationsByRegion(config.regionCode, config.regionType,
                                 config.fuelType, config.includeClosed, done)
        else
            Api.stationsByCoords(config.lat, config.lng,
                                 config.fuelType, config.includeClosed, done)
    }

    function resort() {
        var list = []
        for (var i = 0; i < stationsModel.count; i++) {
            var s = stationsModel.get(i)
            list.push({ name: s.name, address: s.address, postalCode: s.postalCode,
                        city: s.city, lat: s.lat, lng: s.lng, distance: s.distance,
                        open: s.open, price: s.price, raw: s.raw })
        }
        Api.sortStations(list, config.sortBy)
        stationsModel.clear()
        for (var j = 0; j < list.length; j++) stationsModel.append(list[j])
    }

    function setFuelType(code) {
        if (code === config.fuelType) return
        config.fuelType = code
        refresh()
    }

    function setSortBy(value) {
        if (value === config.sortBy) return
        config.sortBy = value
        resort()
    }

    function setIncludeClosed(value) {
        if (value === config.includeClosed) return
        config.includeClosed = value
        refresh()
    }

    function setCoords(label, lat, lng) {
        config.mode = "coords"
        config.label = label
        config.lat = lat
        config.lng = lng
        config.regionCode = 0
        stationsModel.clear()
        cheapest = null
        refresh()
    }

    function setRegion(label, code, type) {
        config.mode = "region"
        config.label = label
        config.regionCode = code
        config.regionType = type
        stationsModel.clear()
        cheapest = null
        refresh()
    }

    // ---- saved places ----
    function savedPlaces() {
        try {
            var list = JSON.parse(config.savedPlaces)
            return Array.isArray(list) ? list : []
        } catch (e) {
            return []
        }
    }

    function addSavedPlace(place) {
        var list = savedPlaces().filter(function(p) {
            return !(Math.abs(p.lat - place.lat) < 1e-5 && Math.abs(p.lng - place.lng) < 1e-5)
        })
        list.unshift({ label: place.label, description: place.description || "",
                       lat: place.lat, lng: place.lng })
        config.savedPlaces = JSON.stringify(list.slice(0, 10))
    }

    function removeSavedPlace(index) {
        var list = savedPlaces()
        list.splice(index, 1)
        config.savedPlaces = JSON.stringify(list)
    }

    Timer {
        id: timeout
        interval: 20000
        onTriggered: {
            if (!app.loading) return
            app.requestId++          // ignore the late answer
            app.loading = false
            app.errorText = qsTr("The request timed out")
        }
    }

    // Refresh on start and when brought back after 10+ minutes.
    Connections {
        target: Qt.application
        onStateChanged: {
            if (Qt.application.state === Qt.ApplicationActive && app.hasLocation && !app.loading
                    && (!app.lastUpdated || (new Date() - app.lastUpdated) > 10 * 60 * 1000))
                app.refresh()
        }
    }

    Component.onCompleted: refresh()
}
