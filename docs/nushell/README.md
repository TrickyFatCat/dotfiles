<h1>Nushell Configuration</h1>

<!--toc:start-->

- [Overview](#overview)
- [Config Location](#config-location)
- [Directories Layout](#directories-layout)
- [Main Configuration File](#main-configuration-file)
- [Variables](#variables)
- [Modules](#modules)
- [Aliases](#aliases)
- [App Integrations](#app-integrations)
- [Related Docs](#related-docs)

<!--toc:end-->

## Overview

This document explains how my personal Nushell setup is organised, maintained, and can be extended.

> [!NOTE]
>
> More information about Nushell can be found on this pages:
>
> - [Official Site](https://www.nushell.sh/)
> - [GitHub Repo](https://github.com/nushell/nushell)
> - [Documentation](https://www.nushell.sh/book/)
> - [Cookbook](https://www.nushell.sh/cookbook/)
> - [Command Reference](https://www.nushell.sh/commands/)
> - [Language Reference](https://www.nushell.sh/lang-guide/)

## Config Location

Nushell config files from this repository should be located in `~/.config/nushell`

To check if config is valid use this read-only command:

```bash
nu --config ~/.config/nushell/config.nu -c 'true'
```

Successful check will print `true`.

## Directories Layout

The basic layout example:

```text
nushell
├── autoload
│   ├── _fzf_integration.nu
│   ├── _zoxide_integration.nu
│   ├── starship.nu
│   └── tv.nu
├── config.nu
├── env.nu
├── history.txt
└── scripts
    ├── browsers-registry.nu
    ├── completers.nu
    ├── detect-terminal.nu
    ├── mango-utils.nu
    ├── terminal-registry.nu
    └── utils.nu
```

| **DIRECTORY** | **DESCRIPTION**                                                     |
| ------------- | ------------------------------------------------------------------- |
| _autoload_    | Used for startup integrations loaded automatically by related tools |
| _scripts_     | Use for custom modules loaded from `config.nu` for global use       |

## Main Configuration File

Basic configuration can be done in `config.nu`.

> [!NOTE]
> `env.nu` is kept only for backwards compatibility.
> Do not add configuration there; use `config.nu` instead.

`config.nu` has basic structure which allows to keep it clean and maintainable:

| **SECTION**    | **DESCRIPTION**                                          |
| -------------- | -------------------------------------------------------- |
| _Defaults_     | Use to configure Nushell specific variables              |
| _PATH_         | Use to adjust PATH variable                              |
| _Plugins_      | Use to setup Nushell plugins                             |
| _Variables_    | Use to add and adjust environment variables              |
| _Modules_      | Use to register custom modules from `scripts/` directory |
| _Aliases_      | Use to add simple aliases                                |
| _Integrations_ | Use to add app specific implementations                  |

## Variables

This section lists evironment variables specific for this configuration.

They are used by various helper scripts, and integrations, e.g. mangoWM and Television.

| **VARIABLE**            | **DESCRIPTION**                     |
| ----------------------- | ----------------------------------- |
| `$env.EDITOR`           | Default text editor                 |
| `$env.TERMINAL`         | Default terminal                    |
| `$env.FILE_MANAGER_TUI` | Default file manager for terminal   |
| `$env.GIT_TUI`          | Default git client for terminal     |
| `$env.SYS_MONITOR_TUI`  | Default system monitor for terminal |

System-defined Nushell variables can be found in the official Nushell documentation.

## Modules

To add a new module:

1. Create it in `scripts/` directory
2. Register in `config.nu` by adding `use my-cool-module.nu *`
   - More about modules in Nushell can be found [**here**](https://www.nushell.sh/book/modules.html#modules)

> [!NOTE]
> `config.nu` adds `scripts/` to `$env.NU_LIB_DIRS`
> So modules in that directory can be imported by filename

## Aliases

Add simple aliases directly to `config.nu`.

For more complex logic consider creating a separate module.

> [!WARNING]
> Read the Nushell [**alias documentation**](https://www.nushell.sh/book/aliases.html) before shadowing existing commands with aliases.

## App Integrations

Some apps can require to add specific implementation code to `config.nu`.

Check it structure, and make sure that it uses `autoload/` directory.

> [!NOTE]
> If an integration suggests `vendor/autoload`.
> Adapt it to use `autoload/` directory.
> Most of the time it should work without any issues.

## Related Docs

- [Terminal Registry](./terminal-registry-readme.md) — helper module for opening terminal apps through `$env.TERMINAL`.
