#!/usr/bin/env bash
#
# Move every sticky window (see aerospace_toggle_sticky.sh) to the focused workspace, but only
# when that workspace is on the main monitor.  Meant to run from exec-on-workspace-change.
#
# Moving a window raises it, so if any stickies were moved, raise the workspace's tiled windows
# back above them by focusing each one, then restore the original focus.
#
# Windows that no longer exist are dropped from the stickies file.
#
# Workspace changes come in bursts (e.g. an app activating on one workspace and then being moved
# to another), and focusing a window on another workspace is itself a workspace change.  So that
# overlapping runs can't fight over which workspace is current:
#   - only one run works at a time; a run that finds the lock taken leaves a rerun marker for the
#     run holding it, which goes around again once it's done
#   - each pass waits for the burst to settle, then reads the focused workspace itself rather
#     than trusting AEROSPACE_FOCUSED_WORKSPACE, which may already be stale
#   - the raising stops as soon as the focused workspace isn't the one being worked on, so this
#     script never switches workspaces itself

set -euo pipefail

aerospace_pid=$(pgrep -ax AeroSpace | head -1)
[ -n "$aerospace_pid" ] || { echo "AeroSpace isn't running" >&2; exit 1; }
stickies_file="${TMPDIR:-/tmp}"
stickies_file="${stickies_file%/}/${aerospace_pid}-stickies"
[ -s "$stickies_file" ] || exit 0

lock_dir="${stickies_file}.lock"
rerun_file="${stickies_file}.rerun"

# mkdir is atomic, so it works as a lock.  A lock whose owner has died is taken over.  An empty
# pid file means its owner is between mkdir and writing its pid, so it's treated as alive.
take_lock() {
    mkdir "$lock_dir" 2> /dev/null && return 0
    local owner
    owner=$(cat "$lock_dir/pid" 2> /dev/null || true)
    [ -n "$owner" ] && ! kill -0 "$owner" 2> /dev/null || return 1
    rm -rf "$lock_dir"
    mkdir "$lock_dir" 2> /dev/null
}

if ! take_lock; then
    touch "$rerun_file"
    exit 0
fi
echo $$ > "$lock_dir/pid"
trap 'rm -rf "$lock_dir"' EXIT

focused_workspace() {
    aerospace list-workspaces --focused
}

move_stickies() {
    sleep 0.15
    local workspace main_monitor existing_windows current_workspace focused_id id layout
    workspace=$(focused_workspace)

    main_monitor=$(aerospace list-monitors --format '%{monitor-id}|%{monitor-is-main}' | awk -F'|' '$2 == "true" { print $1; exit }')
    aerospace list-workspaces --monitor "$main_monitor" | grep -qxF "$workspace" || return 0

    existing_windows=$(aerospace list-windows --all --format '%{window-id}|%{workspace}')
    local stale_ids=()
    local moved=false
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

    $moved || return 0

    focused_id=$(aerospace list-windows --focused --format '%{window-id}' 2> /dev/null || true)
    while IFS='|' read -r id layout; do
        [ "$(focused_workspace)" = "$workspace" ] || return 0
        [ "$layout" = "floating" ] || [ "$id" = "$focused_id" ] || aerospace focus --window-id "$id" || true
    done < <(aerospace list-windows --workspace "$workspace" --format '%{window-id}|%{window-layout}')
    [ -n "$focused_id" ] && [ "$(focused_workspace)" = "$workspace" ] || return 0
    aerospace focus --window-id "$focused_id" || true
}

while true; do
    rm -f "$rerun_file"
    move_stickies
    [ -e "$rerun_file" ] || break
done

# A run that came in between the last check and releasing the lock would otherwise be lost
rm -rf "$lock_dir"
trap - EXIT
[ ! -e "$rerun_file" ] || exec "$0"
