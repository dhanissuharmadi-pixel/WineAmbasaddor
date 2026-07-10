#!/bin/bash
# Build Ambassador.app - a double-clickable macOS bundle around the SwiftPM
# executable, with the pirate-glass icon. Re-run any time to rebuild.
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT="$PWD"
APP="$ROOT/Ambassador.app"
ICON_SRC="$ROOT/packaging/icon-1024.png"
SUPPORT="$HOME/Library/Application Support/Ambassador"
WINE_SRC="$SUPPORT/runtimes/wine-devel-11.10/Wine Devel.app/Contents/Resources/wine"
WRAPPER_SRC="$SUPPORT/steamwebhelper_wrapper.exe"

echo "==> Building AppIcon.icns"
ICONSET="$ROOT/packaging/AppIcon.iconset"
rm -rf "$ICONSET"; mkdir -p "$ICONSET"
for sz in 16 32 128 256 512; do
    sips -z "$sz" "$sz"           "$ICON_SRC" --out "$ICONSET/icon_${sz}x${sz}.png"    >/dev/null
    sips -z "$((sz*2))" "$((sz*2))" "$ICON_SRC" --out "$ICONSET/icon_${sz}x${sz}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$ROOT/packaging/AppIcon.icns"

echo "==> Building release binary"
swift build -c release --product AmbassadorApp

BIN="$ROOT/.build/release/AmbassadorApp"
RESBUNDLE="$(find -L "$ROOT/.build/release" -maxdepth 1 -name '*.bundle' | head -1)"

echo "==> Assembling $APP"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/Ambassador"
cp "$ROOT/packaging/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
[ -n "$RESBUNDLE" ] && cp -R "$RESBUNDLE" "$APP/Contents/Resources/" && echo "    embedded $(basename "$RESBUNDLE")"

# Bundle the Wine runtime so a friend needs no Homebrew/manual Wine install.
# D3DMetal is NOT here (it lives only in the GPTK runtime we don't ship).
if [ -x "$WINE_SRC/bin/wine" ]; then
    echo "==> Bundling Wine runtime (~800 MB, this takes a bit)"
    mkdir -p "$APP/Contents/Resources/runtime"
    cp -R "$WINE_SRC/bin" "$WINE_SRC/lib" "$WINE_SRC/share" "$APP/Contents/Resources/runtime/"
    # Trim Wine Gecko (~200 MB HTML engine; Steam uses its own CEF) and Wine
    # Mono (~225 MB .NET; Unity/Godot ship their own). Wine auto-offers to
    # download either on demand if a game ever actually needs it.
    rm -rf "$APP/Contents/Resources/runtime/share/wine/gecko" \
           "$APP/Contents/Resources/runtime/share/wine/mono"
    echo "    runtime: $(du -sh "$APP/Contents/Resources/runtime" | awk '{print $1}') (Gecko + Mono trimmed)"
else
    echo "!! Wine runtime not found at $WINE_SRC - app will not be self-contained"
fi

# Bundle the webhelper wrapper (the Steam black-screen fix).
[ -f "$WRAPPER_SRC" ] && cp "$WRAPPER_SRC" "$APP/Contents/Resources/steamwebhelper_wrapper.exe" && echo "    embedded steamwebhelper_wrapper.exe"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>Ambassador</string>
  <key>CFBundleDisplayName</key><string>Ambassador</string>
  <key>CFBundleIdentifier</key><string>id.alaric.ambassador</string>
  <key>CFBundleExecutable</key><string>Ambassador</string>
  <key>CFBundleIconFile</key><string>AppIcon</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>0.0.1</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
</dict></plist>
PLIST

echo "==> Ad-hoc codesigning"
codesign --force --deep -s - "$APP" >/dev/null 2>&1 || true

echo "==> Done: $APP"
