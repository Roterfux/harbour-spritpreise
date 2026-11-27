#!/bin/sh
# Build the aarch64 RPM of harbour-spritpreise with the Sailfish Platform SDK chroot in WSL (run as root).
# Usage: wsl -d FedoraLinux-44 -- sh /mnt/c/.../harbour-spritpreise/tools/build-rpm.sh  -> harbour-spritpreise/RPMS/*.rpm
set -e
HERE=$(cd "$(dirname "$0")/.." && pwd)
SRC=$HERE
SDK_ROOT=${SDK_ROOT:-/srv/sailfishos}
TARGET=${TARGET:-SailfishOS-latest-aarch64}
BUILD_USER=${BUILD_USER:-sfdev}
WORK=/home/$BUILD_USER/harbour-spritpreise
LOG=/home/$BUILD_USER/spritpreise-build.log

# QML must compile with the phone's Qt 5.6 first (a QML error = white screen on the phone).
OUT=$(sh "$SRC/tools/qml-check.sh")
echo "$OUT" | grep -E 'FAIL|DONE|NO RESULT'
echo "$OUT" | grep -q 'DONE 0' || { echo "QML CHECK FAILED"; exit 1; }

rm -rf "$WORK"
mkdir -p "$WORK"
tar -C "$SRC" --exclude=.git --exclude=RPMS --exclude=tools -cf - . | tar -C "$WORK" -xf -
find "$WORK" -type d -exec chmod 755 {} +
find "$WORK" -type f -exec chmod 644 {} +
chown -R "$BUILD_USER:$BUILD_USER" "$WORK"

cd "$SDK_ROOT"
if ! ./sdks/sfossdk/sdk-chroot -u "$BUILD_USER" \
        sh -c "cd $WORK && mb2 -t $TARGET build" > "$LOG" 2>&1; then
    tail -40 "$LOG"
    echo "BUILD FAILED (full log: $LOG)"
    exit 1
fi

grep -E "warning: |error: " "$LOG" | sort | uniq -c | sort -rn | head -20 || true
mkdir -p "$HERE/RPMS"
cp "$WORK"/RPMS/*.rpm "$HERE/RPMS/"
ls -l "$HERE/RPMS"
