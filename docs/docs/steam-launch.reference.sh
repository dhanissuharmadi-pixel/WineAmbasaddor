#!/bin/bash
# Ambassador - Steam bottle launcher (phase-0 spec for SteamModule).
# Full webhelper black-screen fix per the Vineport recipe: CEF forced to
# in-process software rendering via BOTH Steam.exe -cef-* flags AND the
# STEAM_CEF_COMMAND_LINE env var. No wrapper .exe yet (env path first).
set -eo pipefail

BOTTLE="$HOME/Library/Application Support/Ambassador/bottles/steam"
WINE="$HOME/Library/Application Support/Ambassador/runtimes/wine-devel-11.10/Wine Devel.app/Contents/Resources/wine/bin"
STEAM_EXE="C:/Program Files (x86)/Steam/steam.exe"

export WINEPREFIX="$BOTTLE/prefix"
export WINEARCH=win64
export PATH="$WINE:$PATH"
export WINESERVER="$WINE/wineserver"
export WINEESYNC=1 WINEMSYNC=1 WINEDEBUG=-all

# .NET JIT under Rosetta
export DOTNET_EnableWriteXorExecute=0

# CEF black-screen fix - force in-process software rendering for Steam's UI only
export STEAM_DISABLE_GPU_PROCESS=1
export GALLIUM_DRIVER=llvmpipe
export STEAM_CEF_COMMAND_LINE="--no-sandbox --in-process-gpu --disable-gpu --disable-gpu-compositing --use-gl=swiftshader --disable-software-rasterizer"

# DXVK (d3d11) + vkd3d (d3d12) native-then-builtin, for later game rendering
export WINEDLLOVERRIDES="d3d11,d3d10core,d3d12,d3d12core=n,b"

# ── Install / re-install the webhelper wrapper ────────────────────────
# Steam FILTERS STEAM_CEF_COMMAND_LINE (drops --in-process-gpu), so the env
# var alone leaves a black screen. The wrapper appends the flags to the real
# binary's own command line (last-wins), which sticks. Find the cef dir(s)
# dynamically - Steam renames it between versions (cef.win64 -> cef.win7x64).
WRAPPER="$BOTTLE/steamwebhelper_wrapper.exe"
if [[ -f "$WRAPPER" ]]; then
    while IFS= read -r whx; do
        [[ -n "$whx" ]] || continue
        dir="$(dirname "$whx")"
        size=$(stat -f%z "$whx" 2>/dev/null || echo 0)
        # Real Steam binary is multi-MB; our wrapper is ~17KB. Only back up a
        # real binary - never overwrite steamwebhelper_real.exe with the wrapper.
        if [[ "$size" -gt 1048576 ]]; then
            cp "$whx" "$dir/steamwebhelper_real.exe"
            cp "$WRAPPER" "$whx"
            echo "  wrapper installed -> ${dir##*/Steam/}"
        fi
    done < <(find "$WINEPREFIX/drive_c/Program Files (x86)/Steam/bin/cef" \
                  -name "steamwebhelper.exe" 2>/dev/null)
fi

"$WINE/wineserver" -k 2>/dev/null && sleep 1 || true

echo "=== Ambassador Steam bottle ==="
echo "  Wine  : $("$WINE/wine" --version 2>/dev/null)"
echo "  Prefix: $WINEPREFIX"

# Steam exits 42 to request a relaunch (after applying an update or picking up
# the swapped webhelper). A real launcher must loop on it, not give up.
for attempt in 1 2 3 4 5; do
    echo "--- launch attempt $attempt ---"
    set +e
    "$WINE/wine" "$STEAM_EXE" \
        -cef-disable-gpu \
        -cef-disable-gpu-compositing \
        -cef-in-process-gpu \
        -cef-disable-sandbox \
        -no-cef-sandbox \
        -noverifyfiles -norepairfiles "$@"
    code=$?
    set -e
    "$WINE/wineserver" -w 2>/dev/null || true
    echo "--- steam.exe exited: $code ---"
    [[ "$code" == "42" ]] || break
    echo "exit 42 → relaunching to pick up update/wrapper..."
    sleep 2
done
