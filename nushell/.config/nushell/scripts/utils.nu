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

# Walk up the process tree from `start_pid` and return the nearest ancestor
# whose process name is in `names`.
# Returns null if no match is found.
#
# Example:
#   find-ancestor-by-name $nu.pid ["kitty" "alacritty" "wezterm"]
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

# Find the terminal process that owns the current Nushell session.
export def find-ancestor-terminal [] {
    find-ancestor-by-name $nu.pid ($registry | get name)
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
