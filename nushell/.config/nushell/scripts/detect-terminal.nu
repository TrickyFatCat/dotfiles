# Terminal registry: the ONE place that knows about supported terminals.
# Add a new terminal by adding a row here — nothing else needs to change.
export def terminal-registry [editor: string, editor_arg: string] {
    [
        {
            name: "kitty"
            spawn: {|cwd| ^kitty --directory $cwd -- $editor $editor_arg }
        }
        {
            name: "foot"
            spawn: {|cwd| ^foot -D $cwd $editor $editor_arg }
        }
        {
            name: "footclient"
            spawn: {|cwd| ^foot -D $cwd $editor $editor_arg }
        }
        {
            name: "alacritty"
            spawn: {|cwd| ^alacritty --working-directory $cwd -e $editor $editor_arg }
        }
        {
            name: "wezterm"
            spawn: {|cwd| ^wezterm start --cwd $cwd -- $editor $editor_arg }
        }
        {
            name: "wezterm-gui"
            spawn: {|cwd| ^wezterm start --cwd $cwd -- $editor $editor_arg }
        }
        {
            name: "xterm"
            spawn: {|cwd| ^xterm -e $"cd '($cwd)' && ($editor) ($editor_arg)" }
        }
        {
            name: "ghostty"
            spawn: {|cwd| ^ghostty $"--working-directory=($cwd)" -e $editor $editor_arg }
        }
    ]
}

export def proc-name [pid: int] {
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
# 
# Returns null if the title doesn't look like a directory path (e.g. a
# foreground app has overwritten the title with something else).
export def title-cwd [title: string] {
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
