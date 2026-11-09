#!/usr/bin/env bash
#
# Toggle whether a window is sticky, or set it explicitly.  Sticky windows follow you to whichever
# workspace you switch to on the main monitor (see aerospace_move_stickies.sh).
#
# Sticky window ids are kept in $TMPDIR/<aerospace pid>-stickies, one per line, so the list
# goes away on its own when AeroSpace restarts and its window ids are no longer valid.
#
# Usage: aerospace_toggle_sticky.sh [--notify] <window-id> [on|off]
#   With on or off, a window already in that state is left alone.
#   With --notify, show a notification with the window's app, title, and resulting sticky state.

set -euo pipefail

usage="Usage: $(basename "$0") [--notify] <window-id> [on|off]"

notify=false
if [ "${1:-}" = "--notify" ]; then
    notify=true
    shift
fi

window_id=${1:?$usage}
wanted=${2:-toggle}

aerospace_pid=$(pgrep -ax AeroSpace | head -1)
[ -n "$aerospace_pid" ] || { echo "AeroSpace isn't running" >&2; exit 1; }
stickies_file="${TMPDIR:-/tmp}"
stickies_file="${stickies_file%/}/${aerospace_pid}-stickies"
touch "$stickies_file"

if grep -qxF "$window_id" "$stickies_file"; then
    current=on
else
    current=off
fi

case "$wanted" in
    toggle) [ "$current" = "on" ] && wanted=off || wanted=on ;;
    on|off) ;;
    *)      echo "$usage" >&2; exit 1 ;;
esac

if [ "$wanted" = "on" ] && [ "$current" = "off" ]; then
    echo "$window_id" >> "$stickies_file"
elif [ "$wanted" = "off" ] && [ "$current" = "on" ]; then
    grep -vxF "$window_id" "$stickies_file" > "${stickies_file}.tmp" || true
    mv "${stickies_file}.tmp" "$stickies_file"
fi

if $notify; then
    # The title is the last field and is taken from everything after the second "|", in case it has a "|"
    window=$(aerospace list-windows --all --format '%{window-id}|%{app-name}|%{window-title}' \
        | awk -F'|' -v id="$window_id" '$1 == id { title = $0; sub(/^[^|]*\|[^|]*\|/, "", title); print $2 " — " title; exit }')
    [ "$wanted" = "on" ] && heading="Window is sticky" || heading="Window is no longer sticky"
    terminal-notifier -title "$heading" -message "${window:-Window $window_id}"
fi
