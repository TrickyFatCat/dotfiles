<h1>MangoWM Setup</h1>

<!--toc:start-->

- [Overview](#overview)
- [Tricky Configs](#tricky-configs)
- [Noctalia Shell Configs](#noctalia-shell-configs)
- [Shell Scripts](#shell-scripts)

<!--toc:end-->

## Overview

This document lists the files of my [MangoWM](https://github.com/mangowm/mango) config, and says what each one holds.

> [!NOTE]
> The official site and documentation of MangoWM are in its [GitHub Repo](https://github.com/mangowm/mango).

The setup needs [Noctalia](https://github.com/noctalia-dev/noctalia), a desktop shell for Wayland. `config.conf` starts Noctalia and loads its colour file.

The files live in `~/.config/mango`:

```text
~/.config/mango/
├── config.conf        main file: session variables (Vulkan renderer),
│                      starts Noctalia, loads the other .conf files
├── tricky-*.conf      my settings, one file per topic
├── noctalia.conf      theme colours, created by Noctalia (not in the repository)
├── noctalia/          optional Noctalia shell configs
└── shell-scripts/     Nushell scripts
```

## Tricky Configs

`tricky-` marks my own settings. `config.conf` loads these files in this order:

| **FILE**                 | **WHAT IT HOLDS**                                                                                                                   |
| ------------------------ | ----------------------------------------------------------------------------------------------------------------------------------- |
| `tricky-general.conf`    | Tags, scratchpads, cursor, focus, security, idle, window drag and snapping                                                          |
| `tricky-monitors.conf`   | Monitors and graphical settings                                                                                                     |
| `tricky-inputs.conf`     | Keyboard, mouse and trackpad. US and Russian layouts                                                                                |
| `tricky-appearance.conf` | Cursor theme, borders, gaps, colours, jump labels and the group tab bar                                                             |
| `tricky-effects.conf`    | Opacity, dim, blur and shadows                                                                                                      |
| `tricky-animations.conf` | Animation types, durations, curves, fade and zoom                                                                                   |
| `tricky-layouts.conf`    | Layout settings                                                                                                                     |
| `tricky-tags.conf`       | Tag settings                                                                                                                        |
| `tricky-bindings.conf`   | Key, mouse and gesture bindings. Many of them run the [shell scripts](#shell-scripts). Some need other apps, listed below the table |
| `tricky-overview.conf`   | Overview hot corner, gaps and jump label characters                                                                                 |
| `tricky-rules.conf`      | Window rules: floating windows, the tag of some apps, and the named scratchpads that `tricky-bindings.conf` opens                   |

`tricky-bindings.conf` needs these apps:

- [Nautilus](https://apps.gnome.org/Nautilus/) for the file manager scratchpad.
- [brightnessctl](https://github.com/Hummer12007/brightnessctl) for the brightness keys.
- `wpctl` from [WirePlumber](https://pipewire.pages.freedesktop.org/wireplumber/) for the volume and microphone keys.
- [playerctl](https://github.com/altdesktop/playerctl) for the media playback keys.

## Noctalia Shell Configs

`config.conf` loads these Noctalia files after the tricky configs:

| **FILE**                          | **WHAT IT HOLDS**                                                                                                                                                                          | **OPTIONAL** |
| --------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------ |
| `noctalia/noctalia-bindings.conf` | Keys for the Noctalia session menu, lock screen, launcher, control center, settings and clipboard                                                                                          | Yes          |
| `noctalia/noctalia-rules.conf`    | Window and layer rules for Noctalia                                                                                                                                                        | Yes          |
| `noctalia.conf`                   | Theme colours. Created by Noctalia, not in the repository. Overrides the colours in `tricky-appearance.conf`. MangoWM starts without it, and `reload-config.nu` does not report it missing | No           |

An optional file is loaded only when it exists.

## Shell Scripts

The scripts in `~/.config/mango/shell-scripts` are Nushell scripts. The scripts below need the Nushell config from this repository in `~/.config/nushell`. See [Nushell Configuration](../nushell/README.md).

Environment variables from the Nushell config choose the browser, editor, file manager, system monitor and Discord client. See [Variables](../nushell/README.md#variables).

The scripts do this:

| **SCRIPT**                 | **WHAT IT DOES**                                                                                                                                                                 |
| -------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `open-browser.nu`          | Opens the browser. When it is open, focuses its window                                                                                                                           |
| `open-cliamp.nu`           | Opens [cliamp](https://github.com/bjarneo/cliamp) in a terminal, for the music scratchpad                                                                                        |
| `open-discord.nu`          | Opens the Discord desktop or terminal client. When it is open, focuses its window                                                                                                |
| `open-editor.nu`           | Opens the editor in a new terminal, in the folder of the focused terminal or in the home folder. No binding runs it                                                              |
| `open-file-manager-tui.nu` | Opens the file manager in a terminal. When it is open, focuses its window                                                                                                        |
| `open-notes.nu`            | Opens `~/Documents/Notes` in the editor, for the notes scratchpad. Runs [`ob sync`](https://obsidian.md/help/sync/headless) on the folder while the window is open               |
| `open-scratch-terminal.nu` | Opens a terminal for the terminal scratchpad                                                                                                                                     |
| `open-scratch-todo.nu`     | Opens `~/Documents/todo.txt` in [tuxedo](https://github.com/webstonehq/tuxedo#install), for the to-do scratchpad                                                                 |
| `open-system-monitor.nu`   | Opens the system monitor in a terminal. When it is open, moves it to the current tag. When it has focus, closes it                                                               |
| `open-telegram.nu`         | Opens Telegram. When it is open, focuses its window                                                                                                                              |
| `open-terminal.nu`         | Opens a new terminal. Can open it in the folder of the focused terminal                                                                                                          |
| `reload-config.nu`         | Reloads the MangoWM config, shows a notification, and checks the config for errors. When the config is invalid, shows the error in a notification and copies it to the clipboard |
| `take-screenshot.nu`       | Takes a screenshot or a recording with [msnap](https://github.com/xtheeq/msnap)                                                                                                  |
| `turn-on-tv.nu`            | Opens a [Television](../television/README.md) channel in a terminal. When it is open, moves it to the current tag. When it has focus, closes it                                  |
