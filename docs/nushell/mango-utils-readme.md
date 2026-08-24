<h1>Mango Utils Readme</h1>

<!--toc:start-->

- [Overview](#overview)
- [Load the Module](#load-the-module)
- [Quick Examples](#quick-examples)
- [Command Reference](#command-reference)
  - [Client Lookup](#client-lookup)
  - [Client Information](#client-information)
  - [Utility Commands](#utility-commands)
  - [Tag Information](#tag-information)
  - [Client Actions](#client-actions)
  - [Configuration Validation](#configuration-validation)
- [Useful Links](#useful-links)

<!--toc:end-->

## Overview

`mango-utils.nu` is a helper Nushell module that provides functions for communicating with MangoWM IPC through the `mmsg` command.

It is used by scripts in `~/.config/mango/shell-scripts/`, including:

- `open-browser.nu`
- `open-file-manager-tui.nu`
- `open-system-monitor.nu`
- `open-telegram.nu`
- `turn-on-tv.nu`

## Load the Module

This Nushell config adds `~/.config/nushell/scripts` to `$env.NU_LIB_DIRS`, so modules in `scripts/` can be imported by filename.

For global use, `config.nu` imports the module with:

```nu
use mango-utils.nu *
```

For one-off local use, import the file directly:

```nu
use ~/.config/nushell/scripts/mango-utils.nu *
```

List available Mango helper commands in a compact table:

```nu
mwm-list-commands
```

## Quick Examples

```nu
# Lists available Mango helper commands.
mwm-list-commands

# Returns the first matching client ID, or null.
mwm-get-client-id firefox

# Returns true when a matching client exists; otherwise false.
mwm-is-client-opened --title "Terminal"

# Returns a table with only the selected fields.
mwm-get-all-clients [id appid title]

# Validates the default Mango config.
mwm-validate-config
```

## Command Reference

The commands use the `mwm-` prefix.

Reference sections:

- [Client Lookup](#client-lookup) — find clients by app ID or title.
- [Client Information](#client-information) — inspect clients and focused-client data.
- [Utility Commands](#utility-commands) — rediscover available Mango helper commands.
- [Tag Information](#tag-information) — inspect active tags and monitor tags.
- [Client Actions](#client-actions) — focus, kill, and move clients.
- [Configuration Validation](#configuration-validation) — validate Mango config files.

### Client Lookup

`appid` and `title` arguments are regex patterns, so values such as `firefox`, `org\.wezfurlong\.wezterm`, or `.*Docs.*` work as matches.

| Syntax                                         | Returns                                                     |
| ---------------------------------------------- | ----------------------------------------------------------- |
| `mwm-get-client-id <appid>`                    | First matching client ID, or `null` when no client matches. |
| `mwm-get-client-id --title <title>`            | First matching client ID by title only, or `null`.          |
| `mwm-get-client-id <appid> --title <title>`    | First client ID matching both patterns, or `null`.          |
| `mwm-is-client-opened <appid>`                 | `true` when a matching client exists; otherwise `false`.    |
| `mwm-is-client-opened --title <title>`         | `true` when a title match exists; otherwise `false`.        |
| `mwm-is-client-opened <appid> --title <title>` | `true` when both patterns match; otherwise `false`.         |

Examples:

```nu
# Returns an ID or null.
mwm-get-client-id firefox
mwm-get-client-id --title "GitHub"
mwm-get-client-id firefox --title "GitHub"

# Returns true or false.
mwm-is-client-opened kitty
mwm-is-client-opened --title "Mango"
mwm-is-client-opened chromium --title "Mango"
```

> [!WARNING]
> `mwm-get-client-id` and `mwm-is-client-opened` require at least one lookup value: `appid`, `--title`, or both.
> Calling either command without a lookup value raises an error.

### Client Information

| Syntax                                 | Returns                                                |
| -------------------------------------- | ------------------------------------------------------ |
| `mwm-get-all-clients`                  | Full client table from `mmsg get all-clients`.         |
| `mwm-get-all-clients [id appid title]` | Client table with the user-selected fields.            |
| `mwm-get-client-field-names`           | Unique list of available client fields.                |
| `mwm-get-focusing-client`              | Focused client record from `mmsg get focusing-client`. |
| `mwm-get-focusing-client-id`           | ID of the focused client.                              |
| `mwm-get-last-open-surface`            | Record from `mmsg get last_open_surface`.              |

Examples:

```nu
# Returns available fields for client tables.
mwm-get-client-field-names

# Returns clients with only these fields.
mwm-get-all-clients [id appid title tag]

# Returns the focused client record.
mwm-get-focusing-client

# Returns the focused client ID.
mwm-get-focusing-client-id

# Returns data for the last opened surface.
mwm-get-last-open-surface
```

Use `mwm-get-client-field-names` first when you are not sure which fields your Mango version exposes.

### Utility Commands

| Syntax              | Returns                                                      |
| ------------------- | ------------------------------------------------------------ |
| `mwm-list-commands` | Compact table of available `mwm-` commands and descriptions. |

Examples:

```nu
# Returns command names and descriptions for Mango helpers.
mwm-list-commands
```

### Tag Information

| Syntax                            | Returns                            |
| --------------------------------- | ---------------------------------- |
| `mwm-get-active-tag`              | Active tag index as an integer.    |
| `mwm-get-tags <monitor>`          | List of tags for a monitor.        |
| `mwm-get-tags <monitor> --active` | List of active tags for a monitor. |

Examples:

```nu
# Returns the active tag index.
mwm-get-active-tag

# Returns all tags for a monitor.
mwm-get-tags HDMI-A-1

# Returns active tags for a monitor.
mwm-get-tags HDMI-A-1 --active
```

Replace `HDMI-A-1` with the monitor name used by Mango.

### Client Actions

These commands dispatch actions through `mmsg`, so they can change focus, move windows, or close clients.

Tag-moving helpers only accept tags from `1` through `9`.

| Syntax                               | Effect                                                    |
| ------------------------------------ | --------------------------------------------------------- |
| `mwm-focus-client <id>`              | Focuses a client by ID.                                   |
| `mwm-focus-client <id> --focus-back` | If the target is already focused, dispatches `focuslast`. |
| `mwm-kill-client <id>`               | Kills the client by ID.                                   |
| `mwm-kill-client <id> --force`       | Dispatches the forced kill path and returns.              |
| `mwm-move-to-tag <tag>`              | Moves the focused client to a tag.                        |
| `mwm-move-client-to-tag <id> <tag>`  | Moves a specific client to a tag.                         |

Examples:

```nu
# Focuses Firefox when it is open.
let id = mwm-get-client-id firefox
if $id != null {
  mwm-focus-client $id
}
```

```nu
# Moves Kitty to tag 2 when it is open.
let id = mwm-get-client-id kitty
if $id != null {
  mwm-move-client-to-tag $id 2
}
```

```nu
# Moves the focused client to tag 3.
mwm-move-to-tag 3
```

```nu
# Closes the matching temporary Firefox window.
let id = mwm-get-client-id firefox --title "Temporary"
if $id != null {
  mwm-kill-client $id
}
```

> [!CAUTION]
> `mwm-kill-client` closes windows.
> Use `mwm-get-client-id` or `mwm-get-all-clients [id appid title]` first to confirm the target ID.

### Configuration Validation

| Syntax                         | Returns                                         |
| ------------------------------ | ----------------------------------------------- |
| `mwm-validate-config`          | Runs `mango -c ~/.config/mango/config.conf -p`. |
| `mwm-validate-config <config>` | Runs `mango -c <config> -p`.                    |

Examples:

```nu
# Validates the default Mango config.
mwm-validate-config

# Validates a config in the current directory.
mwm-validate-config ./config.conf

# Validates the main Mango config.
mwm-validate-config ~/.config/mango/config.conf
```

> [!NOTE]
> `mwm-validate-config` expands the config path before passing it to Mango.
> If the file does not exist, it raises an error with the expanded path.

## Useful Links

- [Nushell official site](https://www.nushell.sh/)
- [Nushell GitHub repo](https://github.com/nushell/nushell)
- [Nushell modules documentation](https://www.nushell.sh/book/modules.html#modules)
- [Mango GitHub repo](https://github.com/mangowm/mango)
- [Nushell Configuration](./README.md)
