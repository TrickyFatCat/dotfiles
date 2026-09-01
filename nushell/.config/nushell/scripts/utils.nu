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

# Open .bashrc for editing
export def --env 'config bash' [] {
    let editor = env-or "EDITOR" null

    if $editor == null {
        error make ("EDITOR is not set in config.nu")
    }

    ^$editor ("~/.bashrc" | path expand)
}

# Checks if a process of a given name is running
#
# name - a regex name pattern
export def is-process-running [name: string] {
    not (get-process-list $name | is-empty)
}

# Prints a list of running processes with a given name
#
# name - a regex name pattern
export def get-process-list [name: string] {
    ps | where name =~ $name
}

# Toggle kanata
export def --env 'toggle kanata' [] {
    let procs = get-process-list "kanata"

    if not ($procs | is-empty) {
        print $"(ansi red)Stopping kanata process.(ansi reset)"
        $procs | each {|proc| kill $proc.pid} | ignore
        notify-send "Kanata Service" "Kanata stopped working."
    } else {
        print $"(ansi green)Restarting kanata process.(ansi reset)"
        ^systemctl --user restart kanata.service
        notify-send "Kanata Service" "Kanata start working."
    }
}
