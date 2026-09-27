<h1>Utils</h1>

<!--toc:start-->

- [Overview](#overview)
- [Load the Module](#load-the-module)
- [Command Reference](#command-reference)
    - [Environment](#environment)
    - [Processes](#processes)
    - [Misc](#misc)
    - [Kanata](#kanata)

<!--toc:end-->

## Overview

`utils.nu` is a helper Nushell module with general commands for this Nushell configuration.

> [!NOTE]
> This configuration is made for Linux: `find-ancestor-by-name` and `find-ancestor-terminal` read `/proc`.

## Load the Module

`config.nu` adds `~/.config/nushell/scripts` to `$env.NU_LIB_DIRS`, and imports the module for global use:

```nu
use utils.nu *
```

In a script or shell that does not load `config.nu`, import the file directly:

```nu
use ~/.config/nushell/scripts/utils.nu *
```

> [!WARNING]
> `utils.nu` imports `terminal-registry.nu`, so keep both files in `~/.config/nushell/scripts/`.

## Command Reference

Reference sections:

- [Environment](#environment) — get an environment variable or a fallback value.
- [Processes](#processes) — find running processes and parent processes.
- [Misc](#misc) — make a file executable, and open `~/.bashrc`.
- [Kanata](#kanata) — stop or start the kanata keyboard remapper.

### Environment

This command returns an environment variable when it is set, and a fallback value when it is not:

| Syntax                     | Returns                                          |
| -------------------------- | ------------------------------------------------ |
| `env-or <name> <fallback>` | `$env.<name>`, or `<fallback>` when it is unset. |

`<fallback>` must be a string or `null`.

Examples:

```nu
# Returns $env.TERMINAL, or "foot" when TERMINAL is not set.
env-or TERMINAL foot

# Returns null when FILE_MANAGER_TUI is not set.
env-or FILE_MANAGER_TUI null

# Returns "foot" even when HOME is set, because <name> is case-sensitive.
env-or home foot
```

### Processes

These commands find running processes and their parent processes:

| Syntax                                | Returns                                                |
| ------------------------------------- | ------------------------------------------------------ |
| `is-process-running <name>`           | `true` when a process name matches; otherwise `false`. |
| `get-process-list <name>`             | `ps` rows that match, or an empty table.               |
| `find-ancestor-by-name <pid> <names>` | First matching PID from `<pid>` upward, or `null`.     |
| `find-ancestor-terminal`              | PID of this shell's terminal, or `null`.               |

`<name>` in `is-process-running` and `get-process-list` is a regex pattern. It matches anywhere in the process name.

`<names>` in `find-ancestor-by-name` is a list of exact process names, such as `[foot kitty]`.

`find-ancestor-by-name` checks `<pid>` itself first, then each parent process in turn. It returns the first PID whose process name is in `<names>`.

It returns `null` when:

- no process before PID 1 matches (PID 1 itself is never checked);
- `<pid>` or one of its parents no longer exists;
- `<pid>` is 1 or lower.

> [!NOTE]
> Linux stores at most 15 characters of a process name in `/proc`, so a name in `<names>` longer than 15 characters never matches.

`find-ancestor-terminal` searches the parent processes of the current shell for a terminal from the [terminal registry](./terminal-registry-readme.md#terminal-support). It returns `null` when none of them is a registered terminal.

> [!WARNING]
> Scripts in `~/.config/television/shell-scripts/` kill the PID that `find-ancestor-terminal` returns, so a change to this command affects them.

Examples:

```nu
# Returns true for kanata and for kanata-tray.
is-process-running kanata

# Returns true only for a process named exactly kanata.
is-process-running '^kanata$'

# Returns only the processes named exactly "foot".
get-process-list '^foot$'

# Returns the PID of the nearest foot or kitty process above this shell, or null.
find-ancestor-by-name $nu.pid [foot kitty]

# Returns the PID of the terminal that runs this shell, or null.
find-ancestor-terminal
```

### Misc

These commands make a file executable or open `~/.bashrc` for editing:

| Syntax          | Effect                                     |
| --------------- | ------------------------------------------ |
| `mkexec <file>` | Makes `<file>` executable with `chmod +x`. |
| `config bash`   | Opens `~/.bashrc` in `$env.EDITOR`.        |

> [!NOTE]
> `config bash` needs `$env.EDITOR` to be set.

Examples:

```nu
# Makes a new script executable.
mkexec ./open-notes.nu

# Opens ~/.bashrc in the editor from $env.EDITOR.
config bash
```

### Kanata

[Kanata](https://github.com/jtroo/kanata) is the keyboard remapper this configuration runs as a systemd user service.

This command stops or starts kanata:

| Syntax          | Effect                                          |
| --------------- | ----------------------------------------------- |
| `toggle kanata` | Stops kanata when it runs; otherwise starts it. |

> [!NOTE]
> `toggle kanata` needs `notify-send` and the systemd user unit `kanata.service`.
