#!/usr/bin/env bash
#
# Move and/or resize the focused floating window by the given deltas, in pixels.
#   dx, dy: shift the window's top-left corner
#   dw, dh: change the window's width and height
#
# e.g. grow 100px to the left: -100 0 100 0 (shift left, then widen to keep the right edge put)
#
# aerospace's resize command doesn't support floating windows yet
# (https://github.com/nikitabobko/AeroSpace/issues/9), so this goes through System Events.
# Whatever runs this needs Accessibility permission; from an aerospace binding, that's AeroSpace.
#
# Usage: aerospace_adjust_floating.sh <dx> <dy> <dw> <dh>

set -euo pipefail

dx=${1:?dx required}
dy=${2:?dy required}
dw=${3:?dw required}
dh=${4:?dh required}

# Leave tiled windows to aerospace's own move and resize commands
[ "$(aerospace list-windows --focused --format '%{window-layout}')" = "floating" ] || exit 0

osascript - "$dx" "$dy" "$dw" "$dh" <<'EOF'
on run argv
    set dx to (item 1 of argv) as integer
    set dy to (item 2 of argv) as integer
    set dw to (item 3 of argv) as integer
    set dh to (item 4 of argv) as integer
    tell application "System Events"
        set frontApp to first application process whose frontmost is true
        set win to value of attribute "AXFocusedWindow" of frontApp
        set {x, y} to position of win
        set {w, h} to size of win
        set position of win to {x + dx, y + dy}
        set size of win to {w + dw, h + dh}
    end tell
end run
EOF
