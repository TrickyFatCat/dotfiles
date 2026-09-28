---
title: "Create MangoWM general README"
id: "007"
status: completed
priority: medium
type: docs
tags:
    - mango
    - docs
context:
    - "mango/.config/mango/"
created_at: "2026-09-01"
owner: tech-docs-writer
completed_at: 2026-09-29
---

# Create readme for utility.nu

## Objective

Create general README.md for MangoWM configuration

Must have:

1. List of tricky configs with concise description
2. List of optional shell configs
3. Links to official site
4. List of shell-scripts with concise description
5. Lings to official documentation

Must NOT:

1. Describe how to install MangoWM
2. Describe how to configure MangoWM
3. Describe referece for each shell-script

## Tasks

- [x] Write `README.md` for MangoWM conifiguration
- [x] Run review with `tech-docs-reviewer` sub-agent as a review partner
    - [x] Give a document for review before a cold reader, find consensus
    - [x] Asses changes based on cold reader questions, find consensus
- [x] Wait for user review
- [x] After approval
    - [x] Add a link to the file in parent readme.md
    - [x] Commit changes
    - [x] Merge to main
    - [x] Remove a worktree
    - [x] Deled local and oringin branches

## Acceptance Criteria

- `README.md` is created in `docs/mango`
- The document is approved by the user
- Document is linked in repository `README.md`
