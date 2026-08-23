<h1>Terminal Registry</h1>

<!--toc:start-->

- [Overview](#overview)
- [Requirements](#requirements)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
  - [Default Terminal](#default-terminal)
  - [Global Use](#global-use)
  - [Local Use](#local-use)
- [Common Usage](#common-usage)
  - [Launch Terminal](#launch-terminal)
  - [Run Command](#run-command)
  - [Set Class and Title](#set-class-and-title)
  - [Detach Terminal](#detach-terminal)
  - [Pass Terminal Args](#pass-terminal-args)
  - [Inspect Arguments](#inspect-arguments)
- [Command Reference](#command-reference)
  - [Build Args](#build-args)
  - [Open Terminal](#open-terminal)
- [Terminal Support](#terminal-support)
  - [Argument Mapping](#argument-mapping)
- [Detection Helpers](#detection-helpers)
- [Extend Registry](#extend-registry)
- [Troubleshooting](#troubleshooting)

<!--toc:end-->

> **AI Notice:** This script and documentation were created with AI assistanse. Test and review before using in your environment.

## Overview

`terminal-registry.nu` is a Nushell module for building and launching terminal emulator commands from one shared set of options.

Use it when a script needs to support several terminal emulators without repeating terminal-specific flags in multiple places.

The companion `detect-terminal.nu` module is optional. Use it only when a workflow needs to detect a terminal from a process ID or infer a terminal's current working directory.

## Requirements

> **Note:** These scripts were created specifically for Linux.

- Nushell
- One or more terminal emulators listed in [Terminal Support](#terminal-support)
- `setsid`, if you use detached terminal launching
- Linux `/proc/<pid>/cwd` support, if you use process current-directory detection

## Quick Start

From the directory containing `terminal-registry.nu`, load the module and inspect generated arguments:

```nu
use ./terminal-registry.nu *
build-args foot --title Baz --dir /tmp | to nuon
```

Expected result:

```nu
[--title, Baz, -D, /tmp]
```

This command does not launch a terminal. It only shows the argument list that would be passed to `foot`.

## Configuration

To use this module:

1. Set `$env.TERMINAL`. See [Default Terminal](#default-terminal).
2. Configure global loading. See [Global Use](#global-use).
3. For scripts or one-off sessions, load it locally. See [Local Use](#local-use).

### Default Terminal

`terminal-registry.nu` does not choose a fallback terminal automatically.

If you call `build-args` or `open-terminal` without passing a terminal name, set `$env.TERMINAL` first.

For a persistent default, add this to `config.nu`:

```nu
$env.TERMINAL = "foot"
```

Other supported values include:

```nu
$env.TERMINAL = "kitty"
$env.TERMINAL = "alacritty"
$env.TERMINAL = "wezterm"
$env.TERMINAL = "ghostty"
```

If neither a terminal name nor `$env.TERMINAL` is available, the module returns this error:

```text
No terminal specified. Pass term_name or set $env.TERMINAL.
```

### Global Use

For regular use, store `terminal-registry.nu` in the `scripts` directory under your Nushell config directory and add that directory to `$env.NU_LIB_DIRS` in `config.nu`:

```nu
use std/dirs

$env.NU_LIB_DIRS = (
    $env.NU_LIB_DIRS?
    | default []
    | append ($nu.default-config-dir | path join "scripts")
    | uniq
)

use terminal-registry.nu *
```

This preserves existing library directories, adds the Nushell `scripts` directory, removes duplicates, and lets Nushell load the module without a relative or full path.

Load the optional detection helpers the same way only if you need them:

```nu
use detect-terminal.nu *
```

### Local Use

For a script or one-off Nushell session, load the registry module by relative path from the directory where the file is stored:

```nu
use ./terminal-registry.nu *
```

Load the optional detection helpers only when needed:

```nu
use ./detect-terminal.nu *
```

You can also use a full path if the files are stored elsewhere:

```nu
use ~/.config/nushell/scripts/terminal-registry.nu *
use ~/.config/nushell/scripts/detect-terminal.nu *
```

## Common Usage

- Use `open-terminal` to launch a terminal.
- Use `build-args` to inspect generated arguments without launching anything.

### Launch Terminal

Open `foot` with `/tmp` as the requested working directory:

```nu
open-terminal foot --dir /tmp
```

### Run Command

Start `foot` and run `nu --login` inside the new terminal:

```nu
open-terminal foot --class foo.bar --title Baz --dir /tmp --command nu --args [--login]
```

Treat `--command` like any other command execution.

### Set Class and Title

Set a terminal class or app-id for window rules and request an initial window title:

- `--class` sets the class or app-id where supported.
- `--title` requests the initial window title.

```nu
open-terminal foot --class foo.bar --title Baz --dir /tmp
```

Remember:

- Both options are optional.
- A dotted value such as `foo.bar` is a good app-id convention.
- Programs running inside the terminal can change the title. Tools such as `yazi` or `zellij` do this after they start.

### Detach Terminal

Launch the terminal without waiting for it from the caller:

```nu
open-terminal foot --class foo.bar --title Baz --dir /tmp --detached
```

This runs the terminal through `setsid -f`. Detached terminals are intentionally disconnected from the current process.

### Pass Terminal Args

Pass raw terminal-specific flags with `--term-args`.

Pass one `foot` flag:

```nu
build-args foot --term-args [--hold] | to nuon
```

Expected result:

```nu
[--hold]
```

Pass a flag with a value:

```nu
build-args foot --term-args [--log-level info] | to nuon
```

Expected result:

```nu
[--log-level, info]
```

Pass several terminal arguments in one list and then run a command:

```nu
build-args foot --term-args [--hold --log-level info --log-colorize never] --command nu | to nuon
```

Expected result:

```nu
[--hold, --log-level, info, --log-colorize, never, nu]
```

Do not pass `--term-args` multiple times. If repeated, the last value wins:

```nu
build-args foot --term-args [--hold] --term-args [--log-level info] | to nuon
```

Expected result:

```nu
[--log-level, info]
```

Combine shared options, terminal-specific flags, and command arguments:

```nu
build-args foot --title Baz --dir /tmp --term-args [--hold] --command nu --args [--login] | to nuon
```

Expected result:

```nu
[--title, Baz, -D, /tmp, --hold, nu, --login]
```

### Inspect Arguments

Preview the argument list for `foot` before launching a terminal:

```nu
build-args foot --title Baz --dir /tmp | to nuon
```

Expected result:

```nu
[--title, Baz, -D, /tmp]
```

This is the safest way to check how shared options are translated into terminal-specific flags.

## Command Reference

The following reference lists command syntax, available options, and default behavior.

### Build Args

```nu
build-args [term_name?] [--class <string>] [--title <string>] [--dir <string>] [--term-args <list>] [--command <string>] [--args <list>]
```

Returns the argument list that would be passed to the selected terminal. It does not start a terminal process.

| Option        | Description                                                                                                               |
| ------------- | ------------------------------------------------------------------------------------------------------------------------- |
| `term_name?`  | Optional terminal registry name. Defaults to `$env.TERMINAL` when omitted.                                                |
| `--class`     | Optional window class or app-id where supported.                                                                          |
| `--title`     | Optional window title where supported.                                                                                    |
| `--dir`       | Working directory where supported.                                                                                        |
| `--term-args` | Raw terminal-specific arguments to pass through. Review these before using them in automation. Defaults to an empty list. |
| `--command`   | Program to run inside the terminal. Treat this like command execution.                                                    |
| `--args`      | Arguments for `--command`. Defaults to an empty list.                                                                     |

### Open Terminal

```nu
open-terminal [term_name?] [--class <string>] [--title <string>] [--dir <string>] [--term-args <list>] [--detached] [--command <string>] [--args <list>]
```

Launches the selected terminal emulator.

| Option        | Description                                                                                    |
| ------------- | ---------------------------------------------------------------------------------------------- |
| `term_name?`  | Optional terminal registry name. Defaults to `$env.TERMINAL` when omitted.                     |
| `--class`     | Optional window class or app-id where supported.                                               |
| `--title`     | Optional window title where supported.                                                         |
| `--dir`       | Working directory where supported.                                                             |
| `--term-args` | Raw terminal-specific arguments to pass through. Review these before using them in automation. |
| `--detached`  | Launch through `setsid -f` so the caller does not block.                                       |
| `--command`   | Program to run inside the terminal. Treat this like command execution.                         |
| `--args`      | Arguments for `--command`.                                                                     |

## Terminal Support

The registry currently supports these terminal names:

- `foot`
- `footclient`
- `kitty`
- `alacritty`
- `wezterm`
- `wezterm-gui`
- `ghostty`

### Argument Mapping

The table below shows how the shared options are translated into terminal-specific flags.

| Registry name            | Generated terminal flags                                                            |
| ------------------------ | ----------------------------------------------------------------------------------- |
| `foot`, `footclient`     | `--app-id`, `--title`, `-D`, then `<command> <args>` directly                       |
| `kitty`                  | `--class`, `--title`, `--directory`, then `-e <command> <args>`                     |
| `alacritty`              | `--class`, `--title`, `--working-directory`, then `-e <command> <args>`             |
| `wezterm`, `wezterm-gui` | `start`, `--class`, `--cwd`, passthrough terminal args, then `-- <command> <args>`  |
| `ghostty`                | `--class=...`, `--title=...`, `--working-directory=...`, then `-e <command> <args>` |

Important notes:

- For `alacritty`, `-e` must be the final terminal option. Everything after `-e` is treated as the command and its arguments.
- `foot`, `wezterm`, and `ghostty` option support can vary by version. Check the installed terminal's help output if an option fails.
- For `ghostty`, prefer a dotted class or app-id value such as `foo.bar`; its class/app-id behavior is unique compared with the other supported terminals.

## Detection Helpers

`detect-terminal.nu` exports helper commands for process and directory detection. These helpers are optional and are only needed when a workflow needs process-name detection, title-based directory detection, or `/proc` current-directory lookup.

| Command                      | Purpose                                                                                                             |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| `process-name <pid>`         | Returns the process name for a PID, or an empty string if the PID is not found.                                     |
| `expand-tilde <path>`        | Expands `~` or `~/...` using `$env.HOME`.                                                                           |
| `title-cwd <title>`          | Attempts to extract a directory path from a terminal window title. Returns `null` when no valid directory is found. |
| `find-fg-pid <start_pid>`    | Walks down a process tree and returns the deepest child PID it finds.                                               |
| `proc-cwd <pid>`             | Resolves `/proc/<pid>/cwd` and returns the process working directory, or `null` on failure.                         |
| `detect-terminal-name <pid>` | Maps supported terminal process names to registry-compatible names. Returns `null` for unsupported processes.       |

`proc-cwd` reads `/proc/<pid>/cwd`; access may fail for processes owned by another user or restricted by system permissions.

Example:

```nu
detect-terminal-name 12345
```

Possible result:

```nu
kitty
```

## Extend Registry

Add support for another terminal by registering its name, writing an argument builder, and adding a dispatch case.

Every terminal-specific argument builder receives the same `opts` record:

| Field       | Meaning                                      |
| ----------- | -------------------------------------------- |
| `class`     | Optional class or app-id value.              |
| `title`     | Optional window title.                       |
| `dir`       | Optional working directory.                  |
| `term_args` | Raw terminal-specific passthrough arguments. |
| `command`   | Optional program to run inside the terminal. |
| `args`      | Arguments for `command`.                     |

The builder must return a flat argv list for the terminal.

1. Add the `bart` terminal name to the exported registry:

```nu
export const registry = [
    {name: "foot"}
    {name: "bart"}
]
```

2. Add a terminal-specific argument builder:

```nu
def bart-args [opts: record] {
    argv [
        (flag "--title" $opts.title)
        (flag "--working-directory" $opts.dir)
        $opts.term_args
        (command-after ["-e"] $opts)
    ]
}
```

3. Add a dispatch case in `args-for-terminal`:

```nu
def args-for-terminal [name: string, opts: record] {
    match $name {
        "bart" => { bart-args $opts }
        _ => { error make {msg: $"Unknown terminal: ($name)"} }
    }
}
```

4. If the detection helpers should recognize the terminal, add a matching case in `detect-terminal-name`:

```nu
"bart" => "bart"
```

5. Test the new entry with `build-args` before launching it:

```nu
build-args bart --title Baz --dir /tmp --command nu
```

## Troubleshooting

| Problem                                                       | Likely cause                                                                                                 | Suggested check                                                                           |
| ------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ | ----------------------------------------------------------------------------------------- |
| `No terminal specified. Pass term_name or set $env.TERMINAL.` | No terminal name was passed and `$env.TERMINAL` is unset.                                                    | Pass a terminal name, such as `build-args foot`, or set `$env.TERMINAL` in `config.nu`.   |
| `Unknown terminal: <name>`                                    | The terminal name is not in the registry dispatch table.                                                     | Check `registry` or add support for the terminal in `args-for-terminal`.                  |
| Terminal opens but ignores the directory                      | The terminal may not support the mapped directory flag, or the installed version may use a different option. | Run the terminal's help command and verify its working-directory option.                  |
| Terminal opens but does not run the command                   | The terminal may require a different command separator or execution flag.                                    | Test with `build-args` and compare the generated argv with the terminal's help output.    |
| Terminal title changes unexpectedly                           | A program inside the terminal changes the title.                                                             | Check whether tools such as `yazi`, `zellij`, shells, prompts, or integrations set title. |
| `proc-cwd` returns `null`                                     | `/proc/<pid>/cwd` is unavailable or permission-restricted.                                                   | Confirm the PID exists and belongs to a process you can inspect.                          |
| `title-cwd` returns `null`                                    | The title does not contain an existing directory path.                                                       | Check the terminal title format or use `proc-cwd` as a fallback.                          |
