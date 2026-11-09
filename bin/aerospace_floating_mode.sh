#!/usr/bin/env bash
#
# Run when entering and leaving aerospace's floating mode.
#
#   enter: remember the focused window if it's tiled, then bring every floating window on the
#          workspace to the front (aerospace_cycle_floating.sh all)
#   exit:  raise every tiled window on the workspace so they cover the floating ones, focusing the
#          remembered tiled window last so focus goes back to where it was before floating mode
#
# macOS has no way to send a window to the back, so raising is done by focusing each window in turn.
# The remembered window id is kept in $TMPDIR/<aerospace pid>-floating-mode-return.
#
# Usage: aerospace_floating_mode.sh (enter|exit)

set -euo pipefail

action=${1:?enter or exit required}

aerospace_pid=$(pgrep -ax AeroSpace | head -1)
[ -n "$aerospace_pid" ] || { echo "AeroSpace isn't running" >&2; exit 1; }
return_file="${TMPDIR:-/tmp}"
return_file="${return_file%/}/${aerospace_pid}-floating-mode-return"

case "$action" in
    enter)
        focused=$(aerospace list-windows --focused --format '%{window-id}|%{window-layout}' || true)
        if [ -n "$focused" ] && [ "${focused#*|}" != "floating" ]; then
            echo "${focused%%|*}" > "$return_file"
        else
            rm -f "$return_file"
        fi
        aerospace_cycle_floating.sh all
        ;;
    exit)
        return_id=$(cat "$return_file" 2> /dev/null || true)
        rm -f "$return_file"

        tiled_ids=()
        while IFS='|' read -r id layout; do
            [ "$layout" != "floating" ] && tiled_ids+=("$id")
        done < <(aerospace list-windows --workspace focused --format '%{window-id}|%{window-layout}')

        # Focus the remembered window last, if it's still on this workspace
        last_id=
        for id in "${tiled_ids[@]+"${tiled_ids[@]}"}"; do
            if [ "$id" = "$return_id" ]; then
                last_id=$id
            else
                aerospace focus --window-id "$id"
            fi
        done
        [ -z "$last_id" ] || aerospace focus --window-id "$last_id"
        ;;
    *)
        echo "Usage: $(basename "$0") (enter|exit)" >&2
        exit 1
        ;;
esac
