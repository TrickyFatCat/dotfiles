use terminal-registry.nu registry

# Use to choose between env variable or a fallback option
# For example let term = (env-or "TERMINAL" "kitty")
export def --env env-or [name: string, fallback] {
    let kind = $fallback | describe
    if $kind != "string" and $kind != "nothing" {
        error make {msg: $"fallback must be a string or null, got ($kind)"}
    }

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

# Makes given file executable
# file: target file
export def mkexec [file: string] {
    if ($file | path type) != "file" {
        error make ("Invalid file path.")
    }

    chmod +x $file
}

# Open .bashrc
export def --env 'config bash' [] {
    let editor = env-or "EDITOR" null

    if $editor == null {
        error make ("EDITOR is not set in config.nu")
    }

    ^$editor ("~/.bashrc" | path expand)
}
