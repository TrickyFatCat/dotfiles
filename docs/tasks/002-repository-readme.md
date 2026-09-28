---
id: "002"
title: "Create repository README.md"
status: pending
priority: high
dependencies: []
tags:
    - "docs"
created_at: 2026-08-31
owner: tech-docs-writer
type: docs
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

- [ ] Create `README.md` for the ropostory
- [ ] Run review with `tech-docs-writer` sub-agent and find a consensus.
- [ ] Wait for user review
- [ ] After approval
    - [ ] Finish the task
    - [ ] Commit
    - [ ] Merge to main
    - [ ] Remove worktree
    - [ ] Remove branch locally and in origin

## Acceptance Criteria

- `README.md` created
- The document is approved by the user
