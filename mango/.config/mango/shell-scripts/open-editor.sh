#!/usr/bin/env bash
#
# Bash port of the nushell open-editor script.
# Requires: jq (for parsing mmsg's JSON output)

set -uo pipefail

# Terminal used when no terminal is focused (or detection fails).
DEFAULT_TERMINAL="kitty"

# Editor to run inside the terminal.
EDITOR_BIN="hx"

# "." tells Helix to open the file picker for the current directory,
# instead of a blank buffer. This only works because each terminal
# below is told to set its process cwd to $cwd before running $EDITOR_BIN.
EDITOR_ARG="."

KNOWN_TERMINALS="kitty foot footclient alacritty wezterm-gui wezterm xterm ghostty"

# --- helpers ---------------------------------------------------------------

is_known_terminal() {
    local name="$1"
    for t in $KNOWN_TERMINALS; do
        [ "$t" = "$name" ] && return 0
    done
    return 1
}

# Returns the focused client's JSON on stdout, or nothing if unavailable.
get_focused_client_json() {
    command -v mmsg >/dev/null 2>&1 || return 1

    local out
    out=$(mmsg get focusing-client 2>/dev/null)
    [ -z "$(printf '%s' "$out" | tr -d '[:space:]')" ] && return 1

    printf '%s' "$out"
}

proc_name() {
    local pid="$1"
    ps -o comm= -p "$pid" 2>/dev/null | head -n1
}

# Expands a leading "~" to $HOME, mirroring shell tilde expansion.
expand_tilde() {
    local p="$1"
    if [[ "$p" == "~"* ]]; then
        printf '%s' "$HOME${p:1}"
    else
        printf '%s' "$p"
    fi
}

# Some terminals (kitty with shell integration / OSC 7, or a prompt like
# starship) put the current directory straight into the window title —
# e.g. "~/Projects/Odin/3d-software-renderer". When that's the case, this
# is a strictly better, zero-dependency source of truth than remote
# control or process-tree walking: no sockets, no multi-instance
# ambiguity, no risk of latching onto a helper process's cwd.
#
# Echoes the resolved cwd, or nothing if the title doesn't look like a
# usable directory path.
title_cwd() {
    local title="$1"
    # trim leading/trailing whitespace
    title="$(printf '%s' "$title" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

    case "$title" in
        /*|"~"*)
            local expanded
            expanded="$(expand_tilde "$title")"
            if [ -d "$expanded" ]; then
                printf '%s' "$expanded"
                return 0
            fi
            ;;
    esac
    return 1
}

# Walk down the process tree from the terminal's pid to find
# the deepest running child — this is the shell (or whatever
# foreground command) actually sitting in the terminal right now.
#
# Used only as a fallback when the window title doesn't yield a usable
# cwd. Filters out kitty's "kitten __watch_conf__" config-watcher child,
# which is forked early and would otherwise be mistaken for the real
# foreground process.
find_fg_pid() {
    local current="$1"
    local seen=" $current "

    while true; do
        local next
        next=$(ps -eo pid=,ppid=,comm= | awk -v ppid="$current" \
            '$2 == ppid && $3 != "kitten" {print $1; exit}')

        [ -z "$next" ] && break
        if [[ "$seen" == *" $next "* ]]; then
            break
        fi
        seen="$seen$next "
        current="$next"
    done

    printf '%s' "$current"
}

proc_cwd() {
    local pid="$1"
    local link="/proc/$pid/cwd"
    if [ -e "$link" ]; then
        local resolved
        resolved=$(readlink -f "$link" 2>/dev/null)
        if [ -n "$resolved" ]; then
            printf '%s' "$resolved"
            return
        fi
    fi
    printf '%s' "$HOME"
}

# Sets TARGET_TERMINAL and TARGET_CWD.
resolve_target() {
    TARGET_TERMINAL="$DEFAULT_TERMINAL"
    TARGET_CWD="$HOME"

    local client_json
    client_json=$(get_focused_client_json) || return 0

    local pid
    pid=$(printf '%s' "$client_json" | jq -r '.pid // empty')
    [ -z "$pid" ] && return 0

    local name
    name=$(proc_name "$pid")
    if ! is_known_terminal "$name"; then
        return 0
    fi
    TARGET_TERMINAL="$name"

    # Prefer the window title as the cwd source: it comes straight from
    # the compositor, requires no extra config, and sidesteps every
    # process-tree/multi-instance issue entirely.
    local title
    title=$(printf '%s' "$client_json" | jq -r '.title // empty')

    local from_title
    if from_title=$(title_cwd "$title"); then
        TARGET_CWD="$from_title"
        return 0
    fi

    # Fallback: walk the process tree from the terminal's pid.
    local fg_pid
    fg_pid=$(find_fg_pid "$pid")
    TARGET_CWD=$(proc_cwd "$fg_pid")
}

# Launches the given terminal at cwd, running $EDITOR_BIN.
# Each terminal has its own CLI for "start here, run this command".
spawn_editor() {
    local terminal="$1"
    local cwd="$2"

    case "$terminal" in
        kitty)
            kitty --directory "$cwd" -- "$EDITOR_BIN" "$EDITOR_ARG" ;;
        foot|footclient)
            foot -D "$cwd" "$EDITOR_BIN" "$EDITOR_ARG" ;;
        alacritty)
            alacritty --working-directory "$cwd" -e "$EDITOR_BIN" "$EDITOR_ARG" ;;
        wezterm|wezterm-gui)
            wezterm start --cwd "$cwd" -- "$EDITOR_BIN" "$EDITOR_ARG" ;;
        xterm)
            xterm -e "cd '$cwd' && $EDITOR_BIN $EDITOR_ARG" ;;
        ghostty)
            ghostty "--working-directory=$cwd" -e "$EDITOR_BIN" "$EDITOR_ARG" ;;
        *)
            kitty --directory "$cwd" -- "$EDITOR_BIN" "$EDITOR_ARG" ;;
    esac
}

# --- main --------------------------------------------------------------

resolve_target
spawn_editor "$TARGET_TERMINAL" "$TARGET_CWD"
