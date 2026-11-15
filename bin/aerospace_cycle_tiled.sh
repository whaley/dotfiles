#!/usr/bin/env bash
#
# Focus the next or previous tiled (non-floating) window on the focused workspace, in DFS order,
# wrapping around.
#
# `focus dfs-next --ignore-floating` fails when the focused window is itself floating, so in that
# case (or when nothing is focused) jump to the first tiled window instead.
#
# Usage: aerospace_cycle_tiled.sh (next|prev)

set -euo pipefail

direction=${1:-next}
case "$direction" in
    next|prev) ;;
    *) echo "Usage: $(basename "$0") (next|prev)" >&2; exit 1 ;;
esac

tiled_ids=()
while IFS='|' read -r id layout; do
    [ "$layout" = "floating" ] || tiled_ids+=("$id")
done < <(aerospace list-windows --workspace focused --format '%{window-id}|%{window-layout}')

[ "${#tiled_ids[@]}" -gt 0 ] || exit 0

focused_layout=$(aerospace list-windows --focused --format '%{window-layout}' 2>/dev/null || true)

if [ -n "$focused_layout" ] && [ "$focused_layout" != "floating" ]; then
    aerospace focus --ignore-floating --boundaries-action wrap-around-the-workspace "dfs-$direction"
    exit 0
fi

# dfs-index walks the tiling tree, so 0 should be the first tiled window.  Fall back to any tiled
# window if that didn't land on one.
aerospace focus --dfs-index 0 || true
focused_layout=$(aerospace list-windows --focused --format '%{window-layout}' 2>/dev/null || true)
if [ -z "$focused_layout" ] || [ "$focused_layout" = "floating" ]; then
    aerospace focus --window-id "${tiled_ids[0]}"
fi
