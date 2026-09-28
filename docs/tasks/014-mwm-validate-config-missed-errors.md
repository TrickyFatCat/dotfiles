---
title: "mwm-validate-config misses errors when mango -p exits 0"
id: "014"
status: pending
priority: low
type: bug
owner: tricky-fat-cat
tags: ["mango", "nushell", "bug"]
created_at: "2026-09-28"
---

# mwm-validate-config misses errors when mango -p exits 0

## Description

`mwm-validate-config` sends the "Config is invalid" notification only when `mango -c <file> -p` exits with a code above 0. `mango -p` prints an `[ERROR]` line but exits 0 when a `source=` file is missing. So `reload-config.nu` does not warn when, for example, `noctalia.conf` is missing.

Evidence from a test with mangowm-git 0.17.3:

- A config with `source=<missing file>` prints `[ERROR]: Failed to open config file: ...` and exits 0.
- A config with an unknown keyword prints `[ERROR]: Unknown keyword: ...` and exits 1.

## Context

- `nushell/.config/nushell/scripts/mango-utils.nu`, `mwm-validate-config`, lines 180-196.
- `mango/.config/mango/shell-scripts/reload-config.nu`.
- `mango/.config/mango/config.conf:28` loads `noctalia.conf` with `source=`. `.gitignore` excludes that file.
- Found during task 007.
