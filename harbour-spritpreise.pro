TARGET = harbour-spritpreise

CONFIG += sailfishapp
QT += network

SOURCES += src/harbour-spritpreise.cpp

# .desktop must be installed explicitly
desktop.files = harbour-spritpreise.desktop
desktop.path = /usr/share/applications
INSTALLS += desktop

DISTFILES += \
    harbour-spritpreise.desktop \
    rpm/harbour-spritpreise.spec \
    qml/harbour-spritpreise.qml \
    qml/js/api.js \
    qml/cover/CoverPage.qml \
    qml/pages/MainPage.qml \
    qml/pages/LocationPage.qml \
    qml/pages/RegionPage.qml \
    qml/pages/StationPage.qml \
    qml/pages/SettingsPage.qml

icons86.files = icons/86x86/harbour-spritpreise.png
icons86.path = /usr/share/icons/hicolor/86x86/apps
icons108.files = icons/108x108/harbour-spritpreise.png
icons108.path = /usr/share/icons/hicolor/108x108/apps
icons128.files = icons/128x128/harbour-spritpreise.png
icons128.path = /usr/share/icons/hicolor/128x128/apps
icons172.files = icons/172x172/harbour-spritpreise.png
icons172.path = /usr/share/icons/hicolor/172x172/apps
INSTALLS += icons86 icons108 icons128 icons172
