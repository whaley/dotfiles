#!/usr/bin/env bash
#
# Focus the next or previous floating window on the focused workspace, wrapping around.
# If the focused window isn't floating, next starts at the first floating window and prev at the last.
#
# all brings every floating window on the workspace to the front by focusing each in turn.  If a
# floating window was already focused, it's focused last so it stays on top.
#
# Usage: aerospace_cycle_floating.sh (next|prev|all)

set -euo pipefail

direction=${1:?next, prev, or all required}

floating_ids=()
while IFS='|' read -r id layout; do
    [ "$layout" = "floating" ] && floating_ids+=("$id")
done < <(aerospace list-windows --workspace focused --format '%{window-id}|%{window-layout}')

count=${#floating_ids[@]}
[ "$count" -gt 0 ] || exit 0

focused_id=$(aerospace list-windows --focused --format '%{window-id}' || true)

current=-1
for n in "${!floating_ids[@]}"; do
    [ "${floating_ids[$n]}" = "$focused_id" ] && current=$n
done

case "$direction" in
    next) target=$(( (current + 1) % count )) ;;
    prev) [ "$current" -lt 0 ] && target=$(( count - 1 )) || target=$(( (current - 1 + count) % count )) ;;
    all)
        for id in "${floating_ids[@]}"; do
            [ "$id" = "$focused_id" ] || aerospace focus --window-id "$id"
        done
        target=$current
        [ "$target" -ge 0 ] || exit 0
        ;;
    *)    echo "Usage: $(basename "$0") (next|prev|all)" >&2; exit 1 ;;
esac

aerospace focus --window-id "${floating_ids[$target]}"
