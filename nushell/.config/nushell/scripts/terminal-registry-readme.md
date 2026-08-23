<h1>Terminal Registry and Detection Helpers</h1>

<!--toc:start-->

- [What this provides](#what-this-provides)
- [Files](#files)
- [Supported terminal names](#supported-terminal-names)
- [Importing the module](#importing-the-module)
- [Setting a default terminal](#setting-a-default-terminal)
- [`build-args`](#build-args)
- [`open-terminal`](#open-terminal)
- [Terminal-specific behavior](#terminal-specific-behavior)
- [Adding a new terminal](#adding-a-new-terminal)
- [Quick validation command](#quick-validation-command)

<!--toc:end-->

> [!attention]
>
> terminal-registry.nu and its documentation were built with AI assistance.
>
> Review and test before relying on them in your environment.

## About

- `terminal-registry.nu` defines a small Nushell registry for supported terminal emulators.
- `build-args` returns the argument list that would be passed to a terminal, without launching it.
- `open-terminal` launches a terminal using the same shared options.
- `detect-terminal.nu` can detect supported terminal names from process IDs and includes helpers for finding a terminal's current working directory.

## Files

```text
input/terminal-registry.nu
input/detect-terminal.nu
```

Treat the files in `input/` as source/reference copies. If you create edited versions, save them outside `input/`.

## Supported terminal names

`terminal-registry.nu` currently supports these registry names:

- `kitty`
- `foot`
- `footclient`
- `alacritty`
- `wezterm`
- `wezterm-gui`
- `ghostty`

`detect-terminal.nu` maps the same process names back to registry-compatible terminal names.

## Importing the module

From Nushell, load the registry commands with:

```nu
use input/terminal-registry.nu *
```

If using the detection helpers too:

```nu
use input/detect-terminal.nu *
```

Adjust the paths if the files are moved into your Nushell config or scripts directory.

## Setting a default terminal

`terminal-registry.nu` does not choose a fallback terminal automatically. If `term_name` is omitted, `$env.TERMINAL` must be set.

Example in `config.nu`:

```nu
$env.TERMINAL = "kitty"
```

Other valid examples:

```nu
$env.TERMINAL = "foot"
$env.TERMINAL = "alacritty"
$env.TERMINAL = "wezterm"
$env.TERMINAL = "ghostty"
```

If neither `term_name` nor `$env.TERMINAL` is available, the module raises:

```text
No terminal specified. Pass term_name or set $env.TERMINAL.
```

## `build-args`

Use `build-args` to inspect the generated terminal arguments without launching anything.

```nu
build-args kitty --class project.chooser --title "Project" --dir /tmp --command nu --args [--login]
```

Expected shape:

```nu
[--class project.chooser --title Project --directory /tmp -e nu --login]
```

General options:

- `term_name?`: optional registry name; defaults to `$env.TERMINAL`
- `--class`: window class / app-id where supported
- `--title`: window title where supported
- `--dir`: working directory where supported
- `--term-args`: list of raw terminal-specific flags
- `--command`: command/program to run inside the terminal
- `--args`: list of arguments for `--command`

Example with passthrough terminal flags:

```nu
build-args kitty --title "Scratch" --term-args [--single-instance] --command nu
```

## `open-terminal`

Use `open-terminal` to actually spawn a terminal.

```nu
open-terminal kitty --title "Project" --dir ~/project
```

Or use the default terminal from `$env.TERMINAL`:

```nu
open-terminal --title "Project" --dir ~/project
```

Run a command inside the new terminal:

```nu
open-terminal wezterm --dir ~/project --command nu --args [--login]
```

Detach from the current process using `setsid -f`:

```nu
open-terminal ghostty --title "Detached" --dir /tmp --detached
```

## Terminal-specific behavior

Current argument mapping:

| Registry name            | Generated terminal flags                                                            |
| ------------------------ | ----------------------------------------------------------------------------------- |
| `kitty`                  | `--class`, `--title`, `--directory`, then `-e <command> <args>`                     |
| `foot`, `footclient`     | `--app-id`, `--title`, `-D`, then command and args directly                         |
| `alacritty`              | `--class`, `--title`, `--working-directory`, then `-e <command> <args>`             |
| `wezterm`, `wezterm-gui` | `start`, `--class`, `--cwd`, passthrough args, then `-- <command> <args>`           |
| `ghostty`                | `--class=...`, `--title=...`, `--working-directory=...`, then `-e <command> <args>` |

Notes from the script:

- `kitty` and `ghostty` `--class` values are expected to use dotted GTK-style app IDs, such as `project.chooser`, not dashed names like `project-chooser`.
- `alacritty` requires `-e` to be the final terminal option; everything after it belongs to the command.
- `foot`, `wezterm`, and `ghostty` flag support should be verified against the installed version's `--help` output.

## Adding a new terminal

1. Add the name to the exported registry:

```nu
export const registry = [
    {name: "kitty"}
    {name: "new-terminal"}
]
```

2. Add a terminal-specific argument builder:

```nu
def new-terminal-args [opts: record] {
    argv [
        (flag "--title" $opts.title)
        (flag "--working-directory" $opts.dir)
        $opts.term_args
        (command-after ["-e"] $opts)
    ]
}
```

3. Dispatch to it from `args-for-terminal`:

```nu
def args-for-terminal [name: string, opts: record] {
    match $name {
        "new-terminal" => { new-terminal-args $opts }
        _ => { error make {msg: $"Unknown terminal: ($name)"} }
    }
}
```

4. If detection should recognize it, add a matching case in `detect-terminal-name`:

```nu
"new-terminal" => "new-terminal"
```

5. Test with `build-args` before launching:

```nu
build-args new-terminal --title Test --dir /tmp --command nu
```

## Quick validation command

A safe validation example that does not launch a terminal:

```nu
use input/terminal-registry.nu *
build-args kitty --class project.chooser --title Test --dir /tmp --command nu --args [--login]
```

This should return a Nushell list of argv strings.
