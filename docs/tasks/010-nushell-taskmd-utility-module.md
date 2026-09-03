---
id: "010"
title: "Nushell. Create taskmd utility module"
status: completed
priority: high
owner: tricky-fat-cat
dependencies: []
tags:
  - "nushell"
  - "taskmd"
  - "config"
context:
  - "nushell/.config/nushell/config.nu"
  - "nushell/.config/nushell/scripts"
created_at: 2026-09-01
---

# Nushell. Create taskmd utility module

## Objective

Create nushell module with helper functions for taskmd

Candidates:

1. Script which validates context for tasks
    - All opened tasks
    - For specific subdirecttory
2. Quick status change
3. Start next task

## Tasks

- [x] Evaluate the list of the most used commands
- [x] Implement functions in `nushell/.config/nushell/scripts`
- [x] Add module to `nushell/.config/nushell/config.nu`
- [x] Validate config
- [x] Commit and push changes

## Acceptance Criteria

- Module is created
- Module is added to `config.nu`
- `config.nu` is validated
