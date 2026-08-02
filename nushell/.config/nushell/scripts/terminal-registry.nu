# Generalized terminal registry. Each entry translates a generic options
# record into that terminal's own argv shape. Detachment is handled
# uniformly outside the registry (see open-terminal), not per-entry.
#
# opts: { class, title, dir, config, term_args, command, args }
#
# NOTE: kitty/ghostty --class sets the Wayland/X11 app-id, expected in
# dotted GTK form ("project.chooser"), not dashed ("project-chooser").
# Confirmed on ghostty; use dotted names consistently across callers.

# NOTE: foot's flags are a best guess, verify against `foot --help`.
def foot-args [opts: record] {
    mut args = []
    if $opts.class != null { $args = ($args | append ["--app-id" $opts.class]) }
    if $opts.title != null { $args = ($args | append ["--title" $opts.title]) }
    if $opts.dir != null { $args = ($args | append ["-D" $opts.dir]) }
    if $opts.config != null { $args = ($args | append ["--config" $opts.config]) }
    $args = ($args | append $opts.term_args)
    if $opts.command != null {
        $args = ($args | append [$opts.command] | append $opts.args)
    }
    $args
}

export def registry [] {
    [
        {
            name: "kitty"
            args_for: {|opts|
                mut args = []
                if $opts.class != null { $args = ($args | append ["--class" $opts.class]) }
                if $opts.title != null { $args = ($args | append ["--title" $opts.title]) }
                if $opts.dir != null { $args = ($args | append ["--directory" $opts.dir]) }
                if $opts.config != null { $args = ($args | append ["--config" $opts.config]) }
                $args = ($args | append $opts.term_args)
                if $opts.command != null {
                    $args = ($args | append ["-e" $opts.command] | append $opts.args)
                }
                $args
            }
        }
        {
            name: "foot"
            args_for: {|opts| foot-args $opts }
        }
        {
            name: "footclient"
            args_for: {|opts| foot-args $opts }
        }
        {
            name: "alacritty"
            # -e must be the LAST flag; everything after is the command.
            args_for: {|opts|
                mut args = []
                if $opts.class != null { $args = ($args | append ["--class" $opts.class]) }
                if $opts.title != null { $args = ($args | append ["--title" $opts.title]) }
                if $opts.dir != null { $args = ($args | append ["--working-directory" $opts.dir]) }
                if $opts.config != null { $args = ($args | append ["--config-file" $opts.config]) }
                $args = ($args | append $opts.term_args)
                if $opts.command != null {
                    $args = ($args | append ["-e" $opts.command] | append $opts.args)
                }
                $args
            }
        }
        {
            name: "wezterm"
            # --config-file is a GLOBAL flag, must precede "start".
            # NOTE: --class is a best guess, verify against `wezterm start --help`.
            args_for: {|opts|
                mut args = []
                if $opts.config != null { $args = ($args | append ["--config-file" $opts.config]) }
                $args = ($args | append ["start"])
                if $opts.class != null { $args = ($args | append ["--class" $opts.class]) }
                if $opts.dir != null { $args = ($args | append ["--cwd" $opts.dir]) }
                $args = ($args | append $opts.term_args)
                if $opts.command != null {
                    $args = (
                        $args
                        | append ["--"]
                        | append [$opts.command]
                        | append $opts.args
                    )
                }
                $args
            }
        }
        {
            name: "wezterm-gui"
            args_for: {|opts| do (
                registry
                | where name == "wezterm"
                | get 0
                | get args_for
            ) $opts }
        }
        {
            name: "ghostty"
            # NOTE: flags are a best guess, ghostty's CLI has changed across
            # versions — verify with --help. Class must be dotted GTK-style.
            args_for: {|opts|
                mut args = []
                if $opts.class != null { $args = ($args | append [$"--class=($opts.class)"]) }
                if $opts.title != null { $args = ($args | append [$"--title=($opts.title)"]) }
                if $opts.dir != null { $args = ($args | append [$"--working-directory=($opts.dir)"]) }
                if $opts.config != null { $args = ($args | append [$"--config-file=($opts.config)"]) }
                $args = ($args | append $opts.term_args)
                if $opts.command != null {
                    $args = ($args | append ["-e" $opts.command] | append $opts.args)
                }
                $args
            }
        }
    ]
}

# Returns the argv a terminal would run, without launching anything.
# Useful for testing a registry entry before wiring it into a real action.
export def build-args [
    term_name?: string
    --class: string
    --title: string
    --dir: string
    --config: string
    --term-args: list<string> = []
    --command: string
    --args: list<string> = []
] {
    let name = $term_name | default ($env.TERMINAL? | default "kitty")
    let opts = {
        class: $class
        title: $title
        dir: $dir
        config: $config
        term_args: $term_args
        command: $command
        args: $args
    }
    let matches = registry | where name == $name
    if ($matches | is-empty) {
        error make {msg: $"Unknown terminal: ($name)"}
    }
    do ($matches | get 0 | get args_for) $opts
}

# Spawn a terminal window from the registry.
#   term_name : e.g. "kitty", "alacritty", "wezterm" — defaults to $env.TERMINAL
#   --class   : window class / app-id (dotted GTK-style, e.g. "project.chooser")
#   --title   : window title (use instead of --class for a plain title)
#   --dir     : working directory
#   --config  : custom config file (support varies per terminal)
#   --term-args: raw passthrough flags for anything not covered above.
#               Not portable across terminals — a deliberate escape hatch.
#   --detached: fork-and-detach via setsid, so the caller doesn't block
#   --command : program to run (omit for a plain shell)
#   --args    : args for --command
export def open-terminal [
    term_name?: string
    --class: string
    --title: string
    --dir: string
    --config: string
    --term-args: list<string> = []
    --detached
    --command: string
    --args: list<string> = []
] {
    let name = $term_name | default ($env.TERMINAL? | default "kitty")
    let argv = (
        build-args $name --class=$class --title=$title --dir=$dir --config=$config --term-args=$term_args --command=$command --args=$args
    )
    if $detached {
        ^setsid -f $name ...$argv
    } else {
        ^$name ...$argv
    }
}
