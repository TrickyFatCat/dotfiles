use terminal-registry.nu registry

# Use to choose between env variable or a fallback option
# For example let term = (env-or "TERMINAL" "kitty")
export def --env env-or [name: string, fallback: string] {
    $env | get -o $name | default $fallback
}

# Checks if current terminal is kitty
export def --env is-kitty-terminal [] {
    (env-or "TERMINAL" "kitty") == "kitty"
}

# Returns $env.KITTY_ALT_CONFIG if possible
# Does NOT validate kitty config
export def --env get-kitty-alt-config [] {
    if not (is-kitty-terminal) {
        return null
    }

    $env | get -o KITTY_ALT_CONFIG
}

# Walk up from a pid to the nearest ancestor whose name is in `names`.
# Matches by name, not a fixed hop count, so it still works when a process
# adds extra hops in between (wrappers, shells, a config-watcher child, etc).
# Returns the matching pid, or null if none found before hitting pid 1.
#
# Good for: finding "which terminal is hosting this session" so you can
# close it after spawning a replacement; finding an enclosing ssh/tmux/
# systemd-run session to signal; any case where you know the process
# you're after by name, but not how many layers of wrapping sit between
# it and where your script is currently running.
# 
# Examples:
#   find-ancestor-by-name $nu.pid ["kitty" "alacritty" "wezterm"]
#   find-ancestor-by-name $nu.pid ["sshd"]   # find the ssh session process
export def find-ancestor-by-name [start_pid: int, names: list<string>] {
    mut current = $start_pid
    mut seen = []
    loop {
        if $current == 1 or $current in $seen {
            return null
        }
        $seen = ($seen | append $current)
        let row = ps | where pid == $current
        if ($row | is-empty) {
            return null
        }
        let name = $row | get name | first
        if $name in $names {
            return $current
        }
        $current = ($row | get ppid | first)
    }
}

export def find-ancestor-terminal [] {
    find-ancestor-by-name $nu.pid (registry | get name)
}

# A function which allows to add a PATH to .bashrc from Nushell
# You can specify your path
# Or you can pipe it like pwd | add-to-bashrc-path
export def add-to-bashrc-path [dir?: string] {
    let dir = if ($dir | is-empty) { $in } else { $dir }
    let dir = $dir | path expand

    if not ($dir | path exists) {
        print $"(ansi red_bold)Error:(ansi reset) ($dir) does not exist"
        return
    }

    let type = $dir | path type

    if $type == "file" {
        let mode = ls -la $dir | get 0.mode
        let is_exec = $mode | str contains "x"

        if $is_exec {
            print $"(ansi red_bold)Error:(ansi reset) ($dir) is an (ansi yellow)executable file(ansi reset), not a directory"
        } else {
            print $"(ansi red_bold)Error:(ansi reset) ($dir) is a (ansi yellow)file(ansi reset), not a directory"
        }
        return
    }

    if $type != "dir" {
        print $"(ansi red_bold)Error:(ansi reset) ($dir) is not a directory (ansi purple)\(type: ($type)\)(ansi reset)"
        return
    }

    let bashrc = $env.HOME | path join ".bashrc"

    # Replace the home directory prefix with $HOME for portability
    let display_dir = if ($dir | str starts-with $env.HOME) {
        $dir | str replace $env.HOME "$HOME"
    } else {
        $dir
    }

    let line = $"export PATH=\"($display_dir):\$PATH\""

    let existing = open $bashrc | lines | any {|l| $l == $line}

    if $existing {
        print $"(ansi yellow)Already present(ansi reset) in ($bashrc)"
    } else {
        $line | save --append $bashrc
        print $"(ansi green_bold)Added(ansi reset) to (ansi cyan)($bashrc)(ansi reset): (ansi light_gray)($line)(ansi reset)"
    }
}
