.pragma library
// ES5 only: SailfishOS ships Qt 5.6's JS engine (no let/const/arrow functions).

var BASE = "https://api.e-control.at/sprit/1.0"
var NOMINATIM = "https://nominatim.openstreetmap.org/search"

var FUEL_TYPES = [
    { code: "SUP", label: "Super 95" },
    { code: "DIE", label: "Diesel" },
    { code: "GAS", label: "CNG" }
]

function fuelIndex(code) {
    for (var i = 0; i < FUEL_TYPES.length; i++)
        if (FUEL_TYPES[i].code === code) return i
    return 0
}

function fuelLabel(code) {
    return FUEL_TYPES[fuelIndex(code)].label
}

function get(url, callback) {
    var xhr = new XMLHttpRequest()
    xhr.onreadystatechange = function() {
        if (xhr.readyState !== XMLHttpRequest.DONE) return
        if (xhr.status === 200) {
            var data
            try {
                data = JSON.parse(xhr.responseText)
            } catch (e) {
                callback("Invalid response from server")
                return
            }
            callback(null, data)
        } else if (xhr.status === 0) {
            callback("No connection")
        } else {
            callback("Server error (HTTP " + xhr.status + ")")
        }
    }
    xhr.open("GET", url)
    xhr.setRequestHeader("Accept", "application/json")
    xhr.send()
}

// ---- E-Control Spritpreisrechner ----

function stationsByCoords(lat, lng, fuelType, includeClosed, callback) {
    var url = BASE + "/search/gas-stations/by-address"
            + "?latitude=" + lat + "&longitude=" + lng
            + "&fuelType=" + fuelType
            + "&includeClosed=" + (includeClosed ? "true" : "false")
    get(url, function(err, data) {
        if (err) return callback(err)
        callback(null, normalizeList(data, fuelType))
    })
}

function stationsByRegion(code, type, fuelType, includeClosed, callback) {
    var url = BASE + "/search/gas-stations/by-region"
            + "?code=" + code + "&type=" + type
            + "&fuelType=" + fuelType
            + "&includeClosed=" + (includeClosed ? "true" : "false")
    get(url, function(err, data) {
        if (err) return callback(err)
        callback(null, normalizeList(data, fuelType))
    })
}

// Flattened list of Bundesländer (BL) and their districts (PB).
function regions(callback) {
    get(BASE + "/regions?includeCities=false", function(err, data) {
        if (err) return callback(err)
        var out = []
        var list = Array.isArray(data) ? data : []
        for (var i = 0; i < list.length; i++) {
            var bl = list[i]
            out.push({ code: bl.code, type: bl.type || "BL",
                       name: bl.name, state: bl.name, whole: true })
            var subs = bl.subRegions || []
            for (var j = 0; j < subs.length; j++) {
                out.push({ code: subs[j].code, type: subs[j].type || "PB",
                           name: subs[j].name, state: bl.name, whole: false })
            }
        }
        callback(null, out)
    })
}

function priceFor(station, fuelType) {
    var prices = station.prices || []
    for (var i = 0; i < prices.length; i++) {
        var p = prices[i]
        if (p.fuelType && p.fuelType !== fuelType) continue
        if (p.amount === undefined || p.amount === null || p.amount === "") continue
        var n = Number(p.amount)
        if (!isNaN(n) && n > 0) return n
    }
    return -1
}

function normalizeList(data, fuelType) {
    var list = Array.isArray(data) ? data : []
    var out = []
    for (var i = 0; i < list.length; i++) {
        var s = list[i] || {}
        var loc = s.location || {}
        out.push({
            name: s.name || "",
            address: loc.address || "",
            postalCode: loc.postalCode ? String(loc.postalCode) : "",
            city: loc.city || "",
            lat: Number(loc.latitude) || 0,
            lng: Number(loc.longitude) || 0,
            distance: (typeof s.distance === "number") ? s.distance : -1,
            open: s.open !== false,
            price: priceFor(s, fuelType),
            raw: JSON.stringify(s)
        })
    }
    return out
}

function sortStations(list, sortBy) {
    list.sort(function(a, b) {
        if (sortBy === "distance" && a.distance >= 0 && b.distance >= 0
                && a.distance !== b.distance)
            return a.distance - b.distance
        // stations without a published price go last
        if (a.price < 0 && b.price >= 0) return 1
        if (b.price < 0 && a.price >= 0) return -1
        if (a.price !== b.price) return a.price - b.price
        return a.distance - b.distance
    })
    return list
}

// ---- Nominatim (OpenStreetMap) geocoding ----
// Policy: max 1 request/s, no search-as-you-type. We only search on Enter.

function shortLabel(displayName) {
    var parts = String(displayName).split(",")
    return parts.slice(0, Math.min(3, parts.length)).join(",").trim()
}

function geocode(query, callback) {
    var url = NOMINATIM + "?format=jsonv2&countrycodes=at&limit=8&q="
            + encodeURIComponent(query)
    get(url, function(err, data) {
        if (err) return callback(err)
        var list = Array.isArray(data) ? data : []
        var out = []
        for (var i = 0; i < list.length; i++) {
            out.push({
                label: shortLabel(list[i].display_name),
                description: String(list[i].display_name || ""),
                lat: Number(list[i].lat),
                lng: Number(list[i].lon)
            })
        }
        callback(null, out)
    })
}
