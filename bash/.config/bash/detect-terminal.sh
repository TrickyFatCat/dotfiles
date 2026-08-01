# terminal-detect.sh
#
# Compositor-agnostic terminal helpers: nothing in this file knows about
# MangoWM, mmsg, or any specific WM's IPC. Everything here just takes a
# pid/title and answers questions about terminals and cwds. To port to a
# different WM, leave this file untouched and only rewrite the
# get_focused_client_json equivalent in the caller.
#
# Meant to be sourced, not executed directly:
#   source "$HOME/.config/bash/terminal-detect.sh"

# ---------------------------------------------------------------------------
# Terminal registry: name -> launcher function. Add a terminal by adding
# one array entry plus one function; nothing else needs to change.
# Uses $editor / $editor_arg from the caller's environment.
# ---------------------------------------------------------------------------
declare -A TERMINAL_LAUNCHERS=(
    [kitty]=spawn_kitty
    [foot]=spawn_foot
    [footclient]=spawn_foot
    [alacritty]=spawn_alacritty
    [wezterm]=spawn_wezterm
    [wezterm-gui]=spawn_wezterm
    [xterm]=spawn_xterm
    [ghostty]=spawn_ghostty
)

spawn_kitty()     { kitty --directory "$1" -- "$editor" "$editor_arg"; }
spawn_foot()      { foot -D "$1" "$editor" "$editor_arg"; }
spawn_alacritty() { alacritty --working-directory "$1" -e "$editor" "$editor_arg"; }
spawn_wezterm()   { wezterm start --cwd "$1" -- "$editor" "$editor_arg"; }
spawn_xterm()     { xterm -e "cd '$1' && $editor $editor_arg"; }
spawn_ghostty()   { ghostty --working-directory="$1" -e "$editor" "$editor_arg"; }

expand_tilde() {
    case "$1" in
        "~"*) printf '%s' "${HOME}${1#\~}" ;;
        *)    printf '%s' "$1" ;;
    esac
}

# Some terminals put the cwd straight into the window title (OSC 7 / shell
# integration, or prompts like starship), e.g. "~/Projects/Odin/renderer".
# That's a zero-dependency source of truth: no sockets, no multi-instance
# ambiguity, no risk of latching onto a helper process's cwd. Prints
# nothing if the title doesn't look like a real, existing directory.
title_cwd() {
    local title path expanded
    title="$(printf '%s' "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"

    # Common prompt-title convention: "user@host:/some/path" (the default
    # \u@\h:\w PS1 exported to the window title). Take everything after
    # the last colon before checking whether it looks like a path.
    case "$title" in
        *:*) path="${title##*:}" ;;
        *)   path="$title" ;;
    esac

    case "$path" in
        /*|"~"*)
            expanded="$(expand_tilde "$path")"
            [[ -d "$expanded" ]] && printf '%s' "$expanded"
            ;;
    esac
}

# Walk down the process tree from the terminal's pid to find the deepest
# running child - the shell (or whatever's in the foreground) actually
# sitting in the terminal right now. Used only as a fallback when the
# window title doesn't yield a usable cwd. Skips kitty's
# "kitten __watch_conf__" config-watcher child so it isn't mistaken for
# the real foreground process.
find_fg_pid() {
    local current="$1" next="" name pid
    while true; do
        next=""
        for pid in $(pgrep -P "$current" 2>/dev/null); do
            name="$(ps -o comm= -p "$pid" 2>/dev/null || true)"
            [[ "$name" == "kitten" ]] && continue
            next="$pid"
            break
        done
        [[ -z "$next" ]] && break
        current="$next"
    done
    printf '%s' "$current"
}

proc_cwd() {
    local pid="$1"
    if [[ -e "/proc/$pid/cwd" ]]; then
        readlink -f "/proc/$pid/cwd" 2>/dev/null || printf '%s' "$HOME"
    else
        printf '%s' "$HOME"
    fi
}
