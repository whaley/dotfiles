#!/usr/bin/env bash

if ! command -v blueutil &> /dev/null; then
    echo "Error: blueutil not found on PATH."
    echo "Install it via Homebrew with: brew install blueutil"
    exit 1
fi

if [ -z "$1" ]; then
    echo "Usage: $(basename "$0") <device name>"
    exit 1
fi

DEVICE_NAME="$1"

# Check if device is paired
STATUS=$(blueutil --paired | grep "\"$DEVICE_NAME\"")

if [ -z "$STATUS" ]; then
    echo "Device not found: $DEVICE_NAME"
    exit 1
fi

if echo "$STATUS" | grep -q ", connected"; then
    echo "Disconnecting $DEVICE_NAME..."
    blueutil --disconnect "$DEVICE_NAME"
else
    echo "Connecting $DEVICE_NAME..."
    blueutil --connect "$DEVICE_NAME"
fi
