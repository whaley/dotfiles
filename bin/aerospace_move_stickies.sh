#!/usr/bin/env bash
#
# Move every sticky window (see aerospace_toggle_sticky.sh) to the focused workspace, but only
# when that workspace is on the main monitor.  Meant to run from exec-on-workspace-change, which
# sets AEROSPACE_FOCUSED_WORKSPACE.
#
# Moving a window raises it, so if any stickies were moved, raise the workspace's tiled windows
# back above them by focusing each one, then restore the original focus.
#
# Windows that no longer exist are dropped from the stickies file.

set -euo pipefail

aerospace_pid=$(pgrep -ax AeroSpace | head -1)
[ -n "$aerospace_pid" ] || { echo "AeroSpace isn't running" >&2; exit 1; }
stickies_file="${TMPDIR:-/tmp}"
stickies_file="${stickies_file%/}/${aerospace_pid}-stickies"
[ -s "$stickies_file" ] || exit 0

workspace=${AEROSPACE_FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused)}

main_monitor=$(aerospace list-monitors --format '%{monitor-id}|%{monitor-is-main}' | awk -F'|' '$2 == "true" { print $1; exit }')
aerospace list-workspaces --monitor "$main_monitor" | grep -qxF "$workspace" || exit 0

existing_windows=$(aerospace list-windows --all --format '%{window-id}|%{workspace}')
stale_ids=()
moved=false
while read -r id; do
    [ -n "$id" ] || continue
    current_workspace=$(awk -F'|' -v id="$id" '$1 == id { print $2; exit }' <<< "$existing_windows")
    if ! grep -q "^${id}|" <<< "$existing_windows"; then
        stale_ids+=("$id")
    elif [ "$current_workspace" != "$workspace" ]; then
        aerospace move-node-to-workspace --window-id "$id" "$workspace" || true
        moved=true
    fi
done < "$stickies_file"

for id in "${stale_ids[@]+"${stale_ids[@]}"}"; do
    aerospace_toggle_sticky.sh "$id" off
done

$moved || exit 0

focused_id=$(aerospace list-windows --focused --format '%{window-id}' 2>/dev/null || true)
while IFS='|' read -r id layout; do
    [ "$layout" = "floating" ] || [ "$id" = "$focused_id" ] || aerospace focus --window-id "$id" || true
done < <(aerospace list-windows --workspace "$workspace" --format '%{window-id}|%{window-layout}')
[ -z "$focused_id" ] || aerospace focus --window-id "$focused_id" || true
