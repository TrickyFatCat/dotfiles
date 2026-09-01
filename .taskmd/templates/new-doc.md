---
_template:
  name: new-doc
  description: "request with objective and tasks"
title: "{{title}}"
id: "{{id}}"
status: pending
priority: medium
type: docs
tags: []
context:
created_at: "{{date}}"
owner: tech-docs-writer
---

# Create readme for utility.nu

## Objective

<!-- Describe the goal of this feature -->

## Tasks

- [ ] Write <document>
- [ ] Run review with `tech-docs-reviewer` and `i-have-adhd` subagents
- [ ] Wait for user review
- [ ] After approval
    - [ ] Add a link to the file in parent
    - [ ] Create a usage report
    - [ ] Finish the task

## Acceptance Criteria

- <document> is created in `<directory>`
- The document is approved by the user
- Document is linked in `<parent-document>` <!-- Optional -->
