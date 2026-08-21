#!/usr/bin/env -S nu --config ~/.config/nushell/config.nu

const WATCHDOG_MARKER = "notes-scratchpad-watchdog"
const TITLE = "Notes"
const NOTES_DIR = "~/Documents/Notes"

# Called twice: once by mango (no --inner) to pick a terminal and spawn it,
# then again by that terminal itself (with --inner) to do the actual work.
def --env main [--inner] {
    if not $inner {
        let term = (env-or "TERMINAL" "foot")
        let self_path = $env.CURRENT_FILE | path expand

        # NOT detached: this process must stay alive and match what mango
        # spawned, so toggle_named_scratchpad tracking keeps working.
        open-terminal $term --title=$TITLE --command=$self_path --args=["--inner"]
        return
    }

    let editor = (env-or "EDITOR" "hx")
    let notes_path = $NOTES_DIR | path expand -s

    # Spawn ob only if it isn't already running
    # let obsidian_running = (^pgrep -f "/usr/bin/ob" | complete | get exit_code) == 0
    let obsidian_running = ps | any {|p| $p.name == "ob"}
    if not $obsidian_running {
        job spawn {
            bash -c $"ob sync --path '($notes_path)' --continuous > /tmp/ob.log 2>&1"
        }
    }

    # Spawn the cleanup watchdog only if one isn't already running
    let watchdog_running = (^pgrep -f $WATCHDOG_MARKER | complete | get exit_code) == 0
    if not $watchdog_running {
        job spawn {
            bash -c $"setsid bash -c ': ($WATCHDOG_MARKER); tail --pid=($nu.pid) -f /dev/null 2>/dev/null; pkill -f \"/usr/bin/ob\"' < /dev/null > /dev/null 2>&1 &"
        }
    }

    ^setsid $editor $notes_path
}
