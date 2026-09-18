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

# Read a process's name and parent pid from /proc.
#
# Returns null if the process does not exist. Reads /proc directly rather
# than calling `ps`, which costs about 100ms per call because it samples
# CPU usage.
#
# Linux only.
def proc-info [pid: int] {
    let path = $"/proc/($pid)/status"
    if not ($path | path exists) { return null }
    let lines = open --raw $path | lines
    {
        name: (
            $lines
            | where {|l| $l starts-with "Name:" }
            | first
            | split row "\t"
            | last
            | str trim
        )
        ppid: (
            $lines
            | where {|l| $l starts-with "PPid:" }
            | first
            | split row "\t"
            | last
            | str trim
            | into int
        )
    }
}

# Walk up the process tree and find the nearest ancestor with a matching name.
#
# Starts at `start_pid` and follows parent pids upward. Returns the pid of the
# first process whose name appears in `names`, or null if the walk reaches pid 1
# without a match.
#
# Names come from /proc, which truncates them to 15 characters. Entries in
# `names` longer than that will never match.
# 
# @example "find the terminal running this shell" {
#     find-ancestor-by-name $nu.pid ["foot" "kitty" "alacritty"]
# } --result 4242
export def find-ancestor-by-name [start_pid: int, names: list<string>] {
    mut current = $start_pid
    mut seen = []
    loop {
        # `seen` guards against a cycle, which should not happen but would
        # otherwise hang the loop forever.
        if $current <= 1 or $current in $seen { return null }
        $seen = ($seen | append $current)
        let info = (proc-info $current)
        if $info == null { return null }
        if $info.name in $names { return $current }
        $current = $info.ppid
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
