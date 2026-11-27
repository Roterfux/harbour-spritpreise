# Spritpreise (harbour-spritpreise)

SailfishOS app showing the cheapest petrol stations in Austria near an
address, or in a Bundesland / Bezirk.

- Prices: E-Control Spritpreisrechner API (free, no key)
- Address search: Nominatim / OpenStreetMap (searches only on Enter, max 1/s)
- Fuel types: Super 95, Diesel, CNG
- Cover shows the cheapest price and has a refresh action
- Remembers the last 10 places; refreshes when reopened after 10+ minutes
- Permissions: Internet only (no GPS)

## Layout

```
harbour-spritpreise.pro / .desktop / rpm/*.spec
src/harbour-spritpreise.cpp   sets a User-Agent for all QML requests (Nominatim requires it)
qml/harbour-spritpreise.qml   app state, settings (Nemo.Configuration), refresh logic
qml/js/api.js                 E-Control + Nominatim clients, sorting (ES5 only)
qml/pages/                    MainPage, LocationPage, RegionPage, StationPage, SettingsPage
qml/cover/CoverPage.qml
icons/                        86/108/128/172 px
```

## Build and run

The project must be inside the sfdk workspace (e.g. `~/repos/sailfishos-dev/`).

```bash
cd ~/repos/sailfishos-dev/harbour-spritpreise
SDK=~/SailfishOS/bin/sfdk

# Emulator
$SDK -c target=SailfishOS-5.0.0.62-i486 build
$SDK emulator start
$SDK -c target=SailfishOS-5.0.0.62-i486 -c "device=Sailfish OS Emulator 5.0.0.62" deploy --sdk
$SDK -c "device=Sailfish OS Emulator 5.0.0.62" run harbour-spritpreise

# Phone (clean first when switching architecture)
rm -f *.o Makefile .qmake.stash harbour-spritpreise RPMS/*.rpm
$SDK -c target=SailfishOS-5.0.0.62-aarch64 build
$SDK -c target=SailfishOS-5.0.0.62-aarch64 -c device="<device-name>" deploy --sdk
```

Logs: `journalctl -f | grep -i spritpreise`

## Not yet verified on a device

The API couldn't be reached while this was written, so the response
parsing follows existing open-source clients and is written defensively.
Check these first:

1. Station search for an address returns a list with prices.
2. Region search (`/search/gas-stations/by-region?code=&type=`) and the
   region list (`/regions`): the parameter names come from older clients.
3. Station details (opening hours, payment, phone) look right.
4. "Navigate" opens a maps app via `geo:`; otherwise it falls back to
   openstreetmap.org in the browser.

## Ideas for later

- GPS as an extra location option (needs `Location` permission, ~1 h)
- German translation (`CONFIG += sailfishapp_i18n`, strings already use qsTr)
- Favourite stations
