#!/usr/bin/env bash
#
# Move every sticky window (see aerospace_toggle_sticky.sh) to the focused workspace, but only
# when that workspace is on the main monitor.  Meant to run from exec-on-workspace-change, which
# sets AEROSPACE_FOCUSED_WORKSPACE.
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

existing_ids=$(aerospace list-windows --all --format '%{window-id}')
stale_ids=()
while read -r id; do
    [ -n "$id" ] || continue
    if grep -qxF "$id" <<< "$existing_ids"; then
        aerospace move-node-to-workspace --window-id "$id" "$workspace" || true
    else
        stale_ids+=("$id")
    fi
done < "$stickies_file"

for id in "${stale_ids[@]+"${stale_ids[@]}"}"; do
    aerospace_toggle_sticky.sh "$id" off
done
