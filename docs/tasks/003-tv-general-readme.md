---
id: "003"
title: "Television. Create README.md"
status: completed
priority: low
dependencies: ["002"]
tags:
  - "television"
  - "docs"
context:
  - "television/.config/television/cable/explorer-configs.toml"
  - "television/.config/television/cable/explorer-gitrepos.toml"
  - "television/.config/television/cable/mango-layout-picker.toml"
  - "television/.config/television/shell-scripts/"
created_at: 2026-08-31
owner: tech-docs-writer
type: docs
completed_at: 2026-09-28
---

# Create television README.md

## Objective

Create the main `README.md` file for television setup.

Must have:

1. Links to the official site and documentation
2. Concise description of custom cable files:
    - `explorer-configs.toml`
    - `explorer-gitrepos.toml`
    - `mango-layout-picker.toml`
3. Concise description of shell-scripts in `shell-scripts` directory
4. Link to `~/dotfiles/docs/television/preview-git-repo-readme.md`

Must NOT:

1. Describe how to install `television`
2. How to config television
3. Description and mention of other cable channels
4. Detailed description of `preview-git-repo.nu`

## Tasks

- [x] Create `README.md` for television setup
- [x] Run review with `tech-docs-writer` sub-agent and find consensus
- [x] Wait for user review
- [x] After approval
    - [x] Add a link to the file in repository `README.md`
    - [x] Finish the task
    - [x] Commit changes
    - [x] Merge to main
    - [x] Delete worktree
    - [x] Delete local and origin branches

## Acceptance Criteria

- `README.md` created in `/docs/television`
- The document is approved by the user
- Document is linked in repository `README.md`
