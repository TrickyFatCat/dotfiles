#!/usr/bin/env nu

# Terminal used when no terminal is focused (or detection fails).
const DEFAULT_TERMINAL = "kitty"

# Editor to run inside the terminal.
const EDITOR = "hx"

# "." tells Helix to open the file picker for the current directory,
# instead of a blank buffer. This only works because each terminal
# below is told to set its process cwd to $cwd before running $EDITOR.
const EDITOR_ARG = "."

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

def proc-name [pid: int] {
    let row = ps | where pid == $pid
    if ($row | is-empty) {
        ""
    } else {
        $row | get name | get 0
    }
}

# Expands a leading "~" to $env.HOME, mirroring shell tilde expansion.
def expand-tilde [p: string] {
    if ($p | str starts-with "~") {
        $env.HOME + ($p | str substring 1..)
    } else {
        $p
    }
}

# Some terminals (kitty with shell integration / OSC 7, or a prompt like
# starship) put the current directory straight into the window title —
# e.g. "~/Projects/Odin/3d-software-renderer". When that's the case, this
# is a strictly better, zero-dependency source of truth than remote
# control or process-tree walking: no sockets, no multi-instance
# ambiguity, no risk of latching onto a helper process's cwd.
#
# Returns null if the title doesn't look like a directory path (e.g. a
# foreground app has overwritten the title with something else).
def title-cwd [title: string] {
    let t = $title | str trim
    if ($t | str starts-with "/") or ($t | str starts-with "~") {
        let expanded = (expand-tilde $t)
        if ($expanded | path exists) {
            return $expanded
        }
    }
    null
}

# Walk down the process tree from the terminal's pid to find
# the deepest running child — this is the shell (or whatever
# foreground command) actually sitting in the terminal right now.
#
# Used only as a fallback when the window title doesn't yield a usable
# cwd. Filters out kitty's "kitten __watch_conf__" config-watcher child,
# which is forked early and would otherwise be mistaken for the real
# foreground process.
def find-fg-pid [start_pid: int] {
    mut current = $start_pid
    mut seen = [$start_pid]
    loop {
        let children = (
            ps | where ppid == $current and name != "kitten" | get pid
        )
        if ($children | is-empty) {
            break
        }
        let next = $children | get 0
        if $next in $seen {
            break
        }
        $seen = ($seen | append $next)
        $current = $next
    }
    $current
}

def proc-cwd [pid: int] {
    let link = $"/proc/($pid)/cwd"
    if ($link | path exists) {
        let resolved = do { ^readlink -f $link } | complete
        if $resolved.exit_code == 0 {
            $resolved.stdout | str trim
        } else {
            $env.HOME
        }
    } else {
        $env.HOME
    }
}

# Returns a record { terminal: string, cwd: string }
def resolve-target [] {
    let client = (get-focused-client)
    if $client == null {
        return {terminal: $DEFAULT_TERMINAL, cwd: $env.HOME}
    }

    let pid = $client.pid? | default null
    if $pid == null {
        return {terminal: $DEFAULT_TERMINAL, cwd: $env.HOME}
    }

    let name = (proc-name $pid)
    let known_terminals = [
        "kitty"
        "foot"
        "footclient"
        "alacritty"
        "wezterm-gui"
        "wezterm"
        "xterm"
        "ghostty"
    ]
    if not ($name in $known_terminals) {
        return {terminal: $DEFAULT_TERMINAL, cwd: $env.HOME}
    }

    # Prefer the window title as the cwd source: it comes straight from
    # the compositor, requires no extra config, and sidesteps every
    # process-tree/multi-instance issue entirely.
    let title = $client.title? | default ""
    let from_title = (title-cwd $title)
    if $from_title != null {
        return {terminal: $name, cwd: $from_title}
    }

    # Fallback: walk the process tree from the terminal's pid.
    let fg_pid = (find-fg-pid $pid)
    let cwd = (proc-cwd $fg_pid)
    {terminal: $name, cwd: $cwd}
}

# Launches the given terminal at cwd, running $EDITOR.
# Each terminal has its own CLI for "start here, run this command".
def spawn-editor [terminal: string, cwd: string] {
    match $terminal {
        "kitty" => { ^kitty --directory $cwd -- $EDITOR $EDITOR_ARG }
        "foot" | "footclient" => { ^foot -D $cwd $EDITOR $EDITOR_ARG }
        "alacritty" => { ^alacritty --working-directory $cwd -e $EDITOR $EDITOR_ARG }
        "wezterm" | "wezterm-gui" => { ^wezterm start --cwd $cwd -- $EDITOR $EDITOR_ARG }
        "xterm" => { ^xterm -e $"cd '($cwd)' && ($EDITOR) ($EDITOR_ARG)" }
        "ghostty" => { ^ghostty $"--working-directory=($cwd)" -e $EDITOR $EDITOR_ARG }
        _ => { ^kitty --directory $cwd -- $EDITOR $EDITOR_ARG }
    }
}

let target = (resolve-target)
spawn-editor $target.terminal $target.cwd
