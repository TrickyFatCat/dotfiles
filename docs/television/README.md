<h1>Television Setup</h1>

<!--toc:start-->

- [Overview](#overview)
- [Custom Channels](#custom-channels)
    - [explorer-configs](#explorer-configs)
    - [explorer-gitrepos](#explorer-gitrepos)
    - [mango-layout-picker](#mango-layout-picker)
- [Shell Scripts](#shell-scripts)

<!--toc:end-->

## Overview

This document describes my custom Television channels and the scripts in `shell-scripts`. The custom channels are utility channels for [MangoWM](https://github.com/mangowm/mango), and the setup needs it.

> [!NOTE]
>
> More information about Television can be found on these pages:
>
> - [Official Site and Documentation](https://alexpasmantier.github.io/television/)
> - [GitHub Repo](https://github.com/alexpasmantier/television)

The files live in these folders:

| **FOLDER**                           | **CONTENT**                            |
| ------------------------------------ | -------------------------------------- |
| `~/.config/television/cable`         | Channel files, one `.toml` per channel |
| `~/.config/television/shell-scripts` | Nushell scripts that channels run      |

## Custom Channels

This setup has these custom channels:

- [explorer-configs](#explorer-configs) — opens a config folder from `~/.config`.
- [explorer-gitrepos](#explorer-gitrepos) — opens a Git repository from the home folder.
- [mango-layout-picker](#mango-layout-picker) — switches the MangoWM layout of the current tag.

> [!WARNING]
> The keys that open or switch something also stop the terminal that runs `tv`, with every window of that terminal process.

### explorer-configs

`explorer-configs` lists the folders and symlinks in `~/.config`, and opens the selected one.

<!-- TODO: Add a screenshot of explorer-configs. -->

#### Requirements

The channel needs:

- The Nushell config from this repository in `~/.config/nushell`. See [Nushell Configuration](../nushell/README.md).
- [eza](https://github.com/eza-community/eza) for the preview.

The channel reads these environment variables:

| **VARIABLE**            | **USED FOR**                                                                                          | **WHEN NOT SET**      |
| ----------------------- | ----------------------------------------------------------------------------------------------------- | --------------------- |
| `$env.TERMINAL`         | New terminal windows. See [Terminal Support](../nushell/terminal-registry-readme.md#terminal-support) | Nothing opens         |
| `$env.EDITOR`           | The editor                                                                                            | `hx` opens            |
| `$env.FILE_MANAGER_TUI` | The file manager                                                                                      | A shell opens instead |

The Nushell config sets these variables. See [Variables](../nushell/README.md#variables).

#### Keys

The channel uses these keys:

| **KEY**               | **ACTION**                                                    |
| --------------------- | ------------------------------------------------------------- |
| `Tab`, `Ctrl-J`       | Select the next entry                                         |
| `Shift-Tab`, `Ctrl-K` | Select the previous entry                                     |
| `Enter`               | Open the editor in the folder, in a new terminal window       |
| `Ctrl-E`              | Open the file manager in the folder, in a new terminal window |
| `Ctrl-C`              | Open a shell in the folder, in a new terminal window          |
| `q`                   | Quit                                                          |

### explorer-gitrepos

`explorer-gitrepos` lists the folders in your home folder that hold a `.git` folder, up to 9 levels deep, and opens the selected one. It skips folders named `.cache`, `.cargo`, `.repos` and `.local`.

> [!NOTE]
> Git worktrees and submodules do not appear in the list, because they hold a `.git` file instead of a folder.

For the preview, see [Television Git Repository Preview](./preview-git-repo-readme.md).

<!-- TODO: Add a screenshot of explorer-gitrepos. -->

#### Requirements

The channel needs:

- The Nushell config from this repository in `~/.config/nushell`. See [Nushell Configuration](../nushell/README.md).
- [fd](https://github.com/sharkdp/fd) for the list.
- [Zellij](https://zellij.dev/) with the `default-dev` layout from this repository's `zellij` package, for `Enter`.
- The [preview requirements](./preview-git-repo-readme.md#requirements).

The channel reads these environment variables:

| **VARIABLE**    | **USED FOR**                                                                                          | **WHEN NOT SET**                     |
| --------------- | ----------------------------------------------------------------------------------------------------- | ------------------------------------ |
| `$env.TERMINAL` | New terminal windows. See [Terminal Support](../nushell/terminal-registry-readme.md#terminal-support) | Nothing opens                        |
| `$env.GIT_TUI`  | The Git client                                                                                        | Nothing happens, and `tv` stays open |

The Nushell config sets these variables. See [Variables](../nushell/README.md#variables).

#### Keys

The channel uses these keys:

| **KEY**               | **ACTION**                                                          |
| --------------------- | ------------------------------------------------------------------- |
| `Tab`, `Ctrl-J`       | Select the next entry                                               |
| `Shift-Tab`, `Ctrl-K` | Select the previous entry                                           |
| `Enter`               | Open the Zellij session of the repository, in a new terminal window |
| `Ctrl-G`              | Open the Git client in the repository, in a new terminal window     |
| `Ctrl-E`              | Open a shell in the repository, in a new terminal window            |
| `q`                   | Quit                                                                |

### mango-layout-picker

`mango-layout-picker` lists the MangoWM layouts, and switches the current tag to the selected one.

<!-- TODO: Add a screenshot of mango-layout-picker. -->

#### Requirements

The channel needs:

- The Nushell config from this repository in `~/.config/nushell`. See [Nushell Configuration](../nushell/README.md).

#### Keys

The channel uses these keys:

| **KEY**               | **ACTION**                    |
| --------------------- | ----------------------------- |
| `Tab`, `Ctrl-J`       | Select the next entry         |
| `Shift-Tab`, `Ctrl-K` | Select the previous entry     |
| `Enter`               | Switch to the selected layout |
| `q`                   | Quit                          |

## Shell Scripts

The scripts in `~/.config/television/shell-scripts` do this:

| **SCRIPT**               | **WHAT IT DOES**                     |
| ------------------------ | ------------------------------------ |
| `open-directory.nu`      | Opens a shell in a folder            |
| `open-editor.nu`         | Opens the editor in a folder         |
| `open-git.nu`            | Opens the Git client in a folder     |
| `open-zellij.nu`         | Opens the Zellij session of a folder |
| `preview-git-repo.nu`    | Prints the Git repository preview    |
| `switch-mango-layout.nu` | Switches MangoWM to the given layout |

With `--use-file-manager`, `open-directory.nu` opens the file manager instead of a shell. For the preview output, see [Television Git Repository Preview](./preview-git-repo-readme.md).

After it succeeds, every script except `preview-git-repo.nu` stops the terminal that runs it.
