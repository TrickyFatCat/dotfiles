#!/usr/bin/env nu
#
# Porting to another WM: everything below is MangoWM-specific (it only
# knows about `mmsg`). terminal-detect.nu has no WM knowledge at all —
# to port, replace `get-focused-client` with an equivalent for your WM's
# IPC (e.g. swaymsg/hyprctl/i3-msg) and leave the module untouched.
def env-or [name: string, fallback: string] {
    $env | get -o $name | default $fallback
}

let default_terminal = (env-or "TERMINAL" "kitty")
let editor = (env-or "EDITOR" "hx")
let editor_arg = (".")

# ---------------------------------------------------------------------------
# Focused-client detection via mmsg (MangoWM's IPC tool)
# ---------------------------------------------------------------------------
def get-focused-client [] {
    if (which mmsg | is-empty) {
        return null
    }

    let result = do { ^mmsg get focusing-client } | complete
    if $result.exit_code != 0 or ($result.stdout | str trim | is-empty) {
        return null
    }

    try {
        $result.stdout | from json
    } catch {
        null
    }
}

# Returns a record { terminal: string, cwd: string }
# `terminal` is always `default_terminal` — this function only ever tries
# to find a good `cwd` to open it at. Detection (mmsg/process tree) is
# used purely to locate the cwd, never to pick which terminal to launch.
def resolve-target [known_terminals: list<string>, default_terminal: string] {
    let client = (get-focused-client)
    if $client == null {
        return {terminal: $default_terminal, cwd: $env.HOME}
    }

    let pid = $client.pid? | default null
    if $pid == null {
        return {terminal: $default_terminal, cwd: $env.HOME}
    }

    let name = (proc-name $pid)
    if not ($name in $known_terminals) {
        return {terminal: $default_terminal, cwd: $env.HOME}
    }

    # Prefer the window title as the cwd source: it comes straight from
    # the compositor, requires no extra config, and sidesteps every
    # process-tree/multi-instance issue entirely.
    let title = $client.title? | default ""
    let from_title = (title-cwd $title)
    if $from_title != null {
        return {terminal: $default_terminal, cwd: $from_title}
    }

    # Fallback: walk the process tree from the terminal's pid.
    let fg_pid = (find-fg-pid $pid)
    let cwd = (proc-cwd $fg_pid)
    {terminal: $default_terminal, cwd: $cwd}
}

def spawn-editor [registry: table, cwd: string, default_terminal: string] {
    let chosen = $registry | where name == $default_terminal | get 0
    do $chosen.spawn $cwd
}

let registry = (terminal-registry $editor $editor_arg)
let known_terminals = $registry | get name
let target = (resolve-target $known_terminals $default_terminal)
spawn-editor $registry $target.cwd $default_terminal
