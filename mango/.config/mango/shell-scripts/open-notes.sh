#!/usr/bin/env bash

WATCHDOG_MARKER="notes-scratchpad-watchdog"

# Spawn ob only if it isn't already running
if ! pgrep -f "/usr/bin/ob" >/dev/null; then
    ob sync --path ~/Documents/Notes --continuous > /tmp/ob.log 2>&1 &
fi

# Spawn the cleanup watchdog only if one isn't already running
if ! pgrep -f "$WATCHDOG_MARKER" >/dev/null; then
    bash -c ": $WATCHDOG_MARKER; tail --pid=$$ -f /dev/null 2>/dev/null; pkill -f '/usr/bin/ob'" &
fi

exec hx ~/Documents/Notes/
