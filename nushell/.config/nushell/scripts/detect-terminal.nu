# WM-agnostic detection helpers: process names, window-title cwd parsing,
# and process-tree walking. No knowledge of any specific WM or compositor —
# callers supply the pid to start from (e.g. via their WM's IPC tool).

export def process-name [pid: int] {
    let row = ps | where pid == $pid
    if ($row | is-empty) {
        ""
    } else {
        $row | get name | get 0
    }
}

# Expands a leading "~" to $env.HOME, mirroring shell tilde expansion.
export def expand-tilde [p: string] {
    if ($p | str starts-with "~") {
        $env.HOME + ($p | str substring 1..)
    } else {
        $p
    }
}

# Some terminals (kitty with shell integration / OSC 7, or a prompt like
# starship) put the current directory straight into the window title.
# Returns null if the title doesn't look like a directory path.
export def title-cwd [title: string] {
    let t = $title | str trim
    # Common convention: "user@host:/some/path" — take everything after
    # the last colon before checking whether it looks like a path.
    let candidate = if ($t | str contains ":") {
        $t | split row ":" | last
    } else {
        $t
    }
    if ($candidate | str starts-with "/") or ($candidate | str starts-with "~") {
        let expanded = (expand-tilde $candidate)
        if ($expanded | path exists) {
            return $expanded
        }
    }
    null
}

# Walk down the process tree from the terminal's pid to find the deepest
# running child — the shell (or foreground command) sitting in it now.
# Fallback only, used when the window title doesn't yield a usable cwd.
# Filters out kitty's "kitten __watch_conf__" config-watcher child.
export def find-fg-pid [start_pid: int] {
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

export def proc-cwd [pid: int] {
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
