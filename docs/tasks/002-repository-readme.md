---
id: "002"
title: "Create repository README.md"
status: completed
priority: high
dependencies: []
tags:
    - "docs"
created_at: 2026-08-31
owner: tech-docs-writer
type: docs
context:
    - "bash"
    - "dprint"
    - "fastfetch"
    - "foot"
    - "helix"
    - "kanata"
    - "leaf"
    - "mango"
    - "marksman"
    - "mpv"
    - "msnap"
    - "nushell"
    - "starship"
    - "systemd"
    - "television"
    - "zellij"
    - ".gitignore"
    - "docs/nushell/README.md"
completed_at: 2026-09-28
---

# Create repository README.md

## Objective

Create `README.md` for the repository.

A concise document whith general description of the repository.

Must have:

- List of configured apps
- Stow instructions
- Warning of AI assited configuration and documentation
- Links to gerenal `README.md` for each docs section

Must NOT:

- Have instructions how to install apps

The goal is a high-quality documentation for humans.

## Tasks

- [x] Create `README.md` for the ropostory
- [x] Run review with `tech-docs-writer` sub-agent and find a consensus.
- [x] Wait for user review
- [x] After approval
    - [x] Finish the task
    - [x] Commit
    - [x] Merge to main
    - [x] Remove worktree
    - [x] Remove branch locally and in origin

## Acceptance Criteria

- `README.md` created
- The document is approved by the user
