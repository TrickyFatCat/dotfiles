#!/usr/bin/env bash

# ---------------------------------------------------------------------------
# Requires: bash 4+ (associative arrays), jq (to parse `mmsg` JSON output).
## ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Porting to another WM: everything below is MangoWM-specific (it only
# knows about `mmsg`). terminal-detect.sh has no WM knowledge at all —
# to port, replace get_focused_client_json/json_field with an equivalent
# for your WM's IPC (e.g. swaymsg/hyprctl/i3-msg) and leave that file
# untouched.
# ---------------------------------------------------------------------------
set -euo pipefail

source "$HOME/.config/bash/detect-terminal.sh"

default_terminal="${TERMINAL:-kitty}"
editor="${EDITOR:-hx}"
editor_arg="."

# ---------------------------------------------------------------------------
# Focused-client detection via mmsg (MangoWM's IPC tool)
# ---------------------------------------------------------------------------
get_focused_client_json() {
    command -v mmsg >/dev/null 2>&1 || return 1
    mmsg get focusing-client 2>/dev/null
}

json_field() {
    # $1 = json string, $2 = jq filter
    jq -r "$2" <<<"$1" 2>/dev/null
}

# ---------------------------------------------------------------------------
# Sets globals: target_terminal, target_cwd
# `target_terminal` is always `default_terminal` — this function only ever
# tries to find a good `cwd` to open it at. Detection (mmsg/process tree)
# is used purely to locate the cwd, never to pick which terminal to launch.
# ---------------------------------------------------------------------------
resolve_target() {
    target_terminal="$default_terminal"
    target_cwd="$HOME"

    local client_json pid name title from_title fg_pid
    client_json="$(get_focused_client_json)" || { echo "DEBUG: mmsg unavailable" >&2; return 0; }
    [[ -z "$client_json" ]] && { echo "DEBUG: empty client_json" >&2; return 0; }
    echo "DEBUG: client_json=$client_json" >&2

    pid="$(json_field "$client_json" '.pid // empty')"
    [[ -z "$pid" ]] && { echo "DEBUG: no pid" >&2; return 0; }
    echo "DEBUG: pid=$pid" >&2

    name="$(ps -o comm= -p "$pid" 2>/dev/null || true)"
    echo "DEBUG: name=$name" >&2
    [[ -z "${TERMINAL_LAUNCHERS[$name]:-}" ]] && { echo "DEBUG: '$name' not in registry" >&2; return 0; }

    title="$(json_field "$client_json" '.title // empty')"
    echo "DEBUG: title=$title" >&2
    from_title="$(title_cwd "$title")"
    echo "DEBUG: from_title=$from_title" >&2
    if [[ -n "$from_title" ]]; then
        target_cwd="$from_title"
        return 0
    fi

    fg_pid="$(find_fg_pid "$pid")"
    echo "DEBUG: fg_pid=$fg_pid" >&2
    target_cwd="$(proc_cwd "$fg_pid")"
    echo "DEBUG: proc_cwd result=$target_cwd" >&2
}
spawn_editor() {
    local cwd="$1" fn
    fn="${TERMINAL_LAUNCHERS[$default_terminal]}"
    "$fn" "$cwd"
}

resolve_target
spawn_editor "$target_cwd"
