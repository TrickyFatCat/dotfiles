# Terminal registry for launching common terminal emulators.
#
# Each terminal gets a small `*-args` function that converts the same generic
# options record into that terminal's argv list.
#
# opts: { class, title, dir, term_args, command, args }
#
# Detaching is intentionally handled only by `open-terminal`, so registry entries
# only describe terminal-specific arguments.
#
# NOTE: kitty/ghostty --class sets the Wayland/X11 app-id, expected in dotted
# GTK form like "project.chooser", not dashed like "project-chooser".

# Add a two-part flag, e.g. ["--title" "My title"].
def flag [name: string, value] {
    if $value == null { [] } else { [$name $value] }
}

# Add a one-part flag, e.g. ["--title=My title"].
def equals-flag [name: string, value] {
    if $value == null { [] } else { [$"($name)=($value)"] }
}

# Add a command section when --command was supplied.
def command-after [prefix: list<string>, opts: record] {
    if $opts.command == null { [] } else {
        $prefix | append [$opts.command] | append $opts.args
    }
}

# Flatten a list of argv fragments into a single argv list.
def argv [fragments: list<any>] {
    $fragments | flatten
}

# NOTE: foot's flags are a best guess; verify against `foot --help`.
def foot-args [opts: record] {
    argv [
        (flag "--app-id" $opts.class)
        (flag "--title" $opts.title)
        (flag "-D" $opts.dir)
        $opts.term_args
        (command-after [] $opts)
    ]
}

def kitty-args [opts: record] {
    argv [
        (flag "--class" $opts.class)
        (flag "--title" $opts.title)
        (flag "--directory" $opts.dir)
        $opts.term_args
        (command-after ["-e"] $opts)
    ]
}

def alacritty-args [opts: record] {

    # -e must be the LAST terminal flag; everything after is the command.
    argv [
        (flag "--class" $opts.class)
        (flag "--title" $opts.title)
        (flag "--working-directory" $opts.dir)
        $opts.term_args
        (command-after ["-e"] $opts)
    ]
}

def wezterm-args [opts: record] {

    # NOTE: --class is a best guess; verify against `wezterm start --help`.
    argv [
        ["start"]
        (flag "--class" $opts.class)
        (flag "--cwd" $opts.dir)
        $opts.term_args
        (command-after ["--"] $opts)
    ]
}

def ghostty-args [opts: record] {

    # NOTE: flags vary across Ghostty versions; verify with `ghostty --help`.
    argv [
        (equals-flag "--class" $opts.class)
        (equals-flag "--title" $opts.title)
        (equals-flag "--working-directory" $opts.dir)
        $opts.term_args
        (command-after ["-e"] $opts)
    ]
}

# Static list of supported terminal names.
#
# Nushell constants cannot contain closures, so dispatch happens in
# `args-for-terminal` below instead of storing functions in this table.
export const registry = [
    {name: "kitty"}
    {name: "foot"}
    {name: "footclient"}
    {name: "alacritty"}
    {name: "wezterm"}
    {name: "wezterm-gui"}
    {name: "ghostty"}
]

def args-for-terminal [name: string, opts: record] {
    match $name {
        "kitty" => { kitty-args $opts }
        "foot" | "footclient" => { foot-args $opts }
        "alacritty" => { alacritty-args $opts }
        "wezterm" | "wezterm-gui" => { wezterm-args $opts }
        "ghostty" => { ghostty-args $opts }
        _ => { error make {msg: $"Unknown terminal: ($name)"} }
    }
}

def get-default-terminal [term_name] {
    let name = $term_name | default ($env.TERMINAL? | default null)

    if $name == null {
        error make {msg: "No terminal specified. Pass term_name or set $env.TERMINAL."}
    }

    $name
}

def options-record [class, title, dir, term_args, command, args] {
    {
        class: $class
        title: $title
        dir: $dir
        term_args: $term_args
        command: $command
        args: $args
    }
}

# Returns the argv a terminal would run, without launching anything.
# Useful for testing a registry entry before wiring it into a real action.
export def build-args [
    term_name?: string
    --class: string
    --title: string
    --dir: string
    --term-args: list<string> = []
    --command: string
    --args: list<string> = []
] {
    let name = get-default-terminal $term_name
    let opts = options-record $class $title $dir $term_args $command $args
    args-for-terminal $name $opts
}

# Spawn a terminal window from the registry.
#   term_name : e.g. "kitty", "alacritty", "wezterm" — defaults to $env.TERMINAL; errors if neither is set
#   --class   : window class / app-id; use dotted GTK-style when supported
#   --title   : window title
#   --dir     : working directory
#   --term-args: raw terminal-specific passthrough flags
#   --detached: fork-and-detach via setsid, so the caller doesn't block
#   --command : program to run; omit for a plain shell
#   --args    : args for --command
export def open-terminal [
    term_name?: string
    --class: string
    --title: string
    --dir: string
    --term-args: list<string> = []
    --detached
    --command: string
    --args: list<string> = []
] {
    let name = get-default-terminal $term_name
    let argv = build-args $name --class=$class --title=$title --dir=$dir --term-args=$term_args --command=$command --args=$args

    if $detached {
        ^setsid -f $name ...$argv
    } else {
        ^$name ...$argv
    }
}
