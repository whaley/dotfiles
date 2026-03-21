#!/usr/bin/env bash

GRANDPARENT_PID=$(ps -p "$PPID" -o ppid=)
GRANDPARENT_NAME=$(ps -p "$GRANDPARENT_PID" -o comm=)

notify() {
  if command -v terminal-notifier &>/dev/null; then
    terminal-notifier -message "$@" -title "toggle_bt.sh ($GRANDPARENT_NAME)"
  else
    echo "$@"
  fi
}

if ! command -v blueutil &> /dev/null; then
    msg="Error: blueutil not found on PATH.
Install it via Homebrew with: brew install blueutil"
    notify "$msg"
    exit 1
fi

if [ -z "$1" ]; then
    notify "Usage: $(basename "$0") <device name>"
    exit 1
fi

DEVICE_NAME="$1"

# Check if device is paired
PAIRED_OUTPUT=$(blueutil --paired 2>&1)
rc=$?
if [ $rc -ne 0 ]; then
    # Catch non-zero return codes from blueutil, useful for bluetooth access permissions
    notify "blueutil error (exit $rc): $PAIRED_OUTPUT"
    exit 1
fi
STATUS=$(echo "$PAIRED_OUTPUT" | grep "\"$DEVICE_NAME\"")

if [ -z "$STATUS" ]; then
    notify "Device not found: $DEVICE_NAME"
    exit 1
fi

if echo "$STATUS" | grep -q ", connected"; then
    notify "Disconnecting $DEVICE_NAME..."
    output=$(blueutil --disconnect "$DEVICE_NAME" 2>&1)
    rc=$?
else
    notify "Connecting $DEVICE_NAME..."
    output=$(blueutil --connect "$DEVICE_NAME" 2>&1)
    rc=$?
fi

if [ $rc -ne 0 ]; then
    notify "blueutil error (exit $rc): $output"
    exit 1
fi
