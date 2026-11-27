#!/bin/sh
# Compile every QML file with the SDK target's own Qt 5.6 + Silica (aarch64 under sb2/qemu),
# no phone or screen needed. Sailfish.WebView is not in the target, so a stub stands in for it.
# Run as root in WSL:  sh tools/qml-check.sh      Prints OK/FAIL per file and DONE <failures>.
# The target has no qmlscene binary: QMLSCENE points at one extracted from
# qt5-qtdeclarative-qmlscene (zypper download + rpm2cpio, not installed into the target).
set -e
SRC=$(cd "$(dirname "$0")/.." && pwd)
SDK_ROOT=${SDK_ROOT:-/srv/sailfishos}
TARGET=${TARGET:-SailfishOS-latest-aarch64}
BUILD_USER=${BUILD_USER:-sfdev}
W=/home/$BUILD_USER/qmlcheck
QMLSCENE=${QMLSCENE:-/home/$BUILD_USER/pkprobe/qs/usr/lib64/qt5/bin/qmlscene}

rm -rf "$W"; mkdir -p "$W/stub/Sailfish/WebView" "$W/stub/Sailfish/WebEngine"
cp -r "$SRC/qml" "$W/qml"

cat > "$W/stub/Sailfish/WebEngine/qmldir" <<'EOF'
module Sailfish.WebEngine
singleton WebEngineSettings 1.0 WebEngineSettings.qml
EOF
cat > "$W/stub/Sailfish/WebEngine/WebEngineSettings.qml" <<'EOF'
pragma Singleton
import QtQuick 2.0
QtObject {
    signal initialized()
    property bool autoLoadImages: true
    function setPreference(key, value, type) {}
}
EOF

cat > "$W/stub/Sailfish/WebView/qmldir" <<'EOF'
module Sailfish.WebView
WebView 1.0 WebView.qml
WebViewPage 1.0 WebViewPage.qml
EOF
cat > "$W/stub/Sailfish/WebView/WebView.qml" <<'EOF'
import QtQuick 2.0
Item {
    property url url
    property string title
    property bool loading
    property int loadProgress
    property bool canGoBack
    property bool canGoForward
    property bool active
    signal linkClicked(string url)
    function runJavaScript(script, callback, errorCallback) {}
    function goBack() {}
    function goForward() {}
    function reload() {}
    function stop() {}
}
EOF
cat > "$W/stub/Sailfish/WebView/WebViewPage.qml" <<'EOF'
import QtQuick 2.0
import Sailfish.Silica 1.0
Page {}
EOF

FILES=$(cd "$W" && find qml -name '*.qml' | sort | sed 's/.*/"&",/' | tr -d '\n')
cat > "$W/check.qml" <<EOF
import QtQuick 2.6
Item {
    Timer { interval: 10; running: true; onTriggered: parent.check() }
    function check() {
        var files = [$FILES]
        var bad = 0
        for (var i = 0; i < files.length; ++i) {
            var c = Qt.createComponent("file://$W/" + files[i], Component.PreferSynchronous)
            if (c.status === Component.Ready) {
                console.log("OK   " + files[i])
            } else {
                bad += 1
                console.log("FAIL " + files[i] + ": " + c.errorString().replace(/\n/g, " "))
            }
        }
        console.log("DONE " + bad)
        Qt.quit()
    }
}
EOF
chown -R "$BUILD_USER:$BUILD_USER" "$W"

cd "$SDK_ROOT"
./sdks/sfossdk/sdk-chroot -u "$BUILD_USER" sh -c \
  "cd $W && QML2_IMPORT_PATH=$W/stub QT_LOGGING_TO_CONSOLE=1 QT_QPA_PLATFORM=minimal \
   timeout 300 sb2 -t $TARGET $QMLSCENE $W/check.qml" > "$W/log" 2>&1 || true
grep -E '(OK|FAIL|DONE) ' "$W/log" | sed 's/^.*\(OK \|FAIL\|DONE\)/\1/'
grep -q 'DONE ' "$W/log" || { echo "NO RESULT:"; grep -v Mounting "$W/log" | tail -25; }
