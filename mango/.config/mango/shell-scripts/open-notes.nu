#!/usr/bin/env nu

const WATCHDOG_MARKER = "notes-scratchpad-watchdog"

# Spawn ob only if it isn't already running
let obsidian_running = (^pgrep -f "/usr/bin/ob" | complete | get exit_code) == 0
if not $obsidian_running {
    job spawn {
        bash -c "ob sync --path ~/Documents/Notes --continuous > /tmp/ob.log 2>&1"
    }
}

# Spawn the cleanup watchdog only if one isn't already running
let watchdog_running = (^pgrep -f $WATCHDOG_MARKER | complete | get exit_code) == 0
if not $watchdog_running {
    job spawn {
        bash -c $"setsid bash -c ': ($WATCHDOG_MARKER); tail --pid=($nu.pid) -f /dev/null 2>/dev/null; pkill -f \"/usr/bin/ob\"' < /dev/null > /dev/null 2>&1 &"
    }
}

hx ~/Documents/Notes/
