# Working with Taskmd Tasks

This project uses [taskmd](https://github.com/driangle/taskmd) for task management. Tasks are Markdown files with YAML frontmatter. See `TASKMD_SPEC.md` for the full field reference.

Taskmd manages task structure and lifecycle. The rules below define how agents may use tasks in this repository.

## Agent Eligibility

Agents may work only on tasks whose `owner` explicitly includes `agent`.

This is a hard safety boundary:

- Tasks with no owner are out of scope.
- Tasks owned only by another owner are out of scope.
- Do not change a task's owner to make it eligible.
- The restriction still applies when the user explicitly names a task. If the named task is ineligible, report that and do not modify it.

## Task File Format

```markdown
---
id: "001"
title: "Task title"
status: pending
priority: high
effort: medium
dependencies: ["002"]
owner: agent
tags: [feature]
created_at: 2026-01-15
context:
  - path/to/relevant-file
---

# Task Title

## Objective

What this task accomplishes.

## Tasks

- [ ] Subtask 1
- [ ] Subtask 2

## Acceptance Criteria

- Criterion 1
```

Files follow the pattern `NNN-descriptive-title.md`, for example `015-add-user-auth.md`.

## CLI Commands

```bash
taskmd list
taskmd list --status pending --priority high
taskmd next
taskmd validate
taskmd graph --format ascii
taskmd board
taskmd stats
taskmd set <id> --status in-progress
taskmd add "Task title"
taskmd verify <id>
taskmd worklog <id> --add "Progress note"
```

Use taskmd commands for task lifecycle operations when taskmd provides the corresponding operation. Do not manually create or manipulate task-management metadata when taskmd can manage it.

## Task Selection

When the user specifies a task:

1. Inspect that task.
2. Verify that its `owner` includes `agent`.
3. Do not work on it if it fails the ownership rule.

When the user does not specify a task:

1. Use `taskmd next` to identify the next actionable candidate.
2. Verify its owner before claiming it.
3. Skip tasks that do not satisfy the agent ownership rule without modifying them.

`taskmd next` identifies a candidate; it does not override repository eligibility rules.

## Starting a Task

Before changing a task to `in-progress`:

1. Read the complete task.
2. Confirm that `owner` includes `agent`.
3. Confirm that all blocking dependencies are satisfied.
4. Resolve the task Context:

    ```bash
    taskmd context --task-id <id> --format json --include-content --resolve
    ```

5. Confirm that Context exists, resolves successfully, and is sufficient to begin the work.

Task Context is required for agent work. Empty, unavailable, unreadable, or insufficient Context is a blocker.

Once all preconditions pass:

```bash
taskmd set <id> --status in-progress
```

Add a worklog entry when worklogs are enabled.

## Task Scope

Treat an eligible task as authorization to perform the work it explicitly defines.

Follow its:

- Objective;
- Must and Must NOT constraints;
- Tasks or ToDo items;
- Acceptance Criteria;
- Context;
- dependencies;
- verification requirements; and
- approval or review gates.

Do not silently expand or redefine the task.

While executing a task, agents may update execution state such as:

- status;
- existing checklist items;
- worklog entries;
- verification results; and
- completion metadata.

Do not silently change planning decisions such as:

- owner;
- dependencies;
- Objective;
- Must or Must NOT constraints;
- required Tasks or ToDo items;
- Acceptance Criteria; or
- overall task scope.

## Context

Resolved task Context is the primary evidence boundary for the task.

Use additional repository files only when they are necessary to supply context required to complete the active task correctly.

Inspecting an additional file does not expand task scope.

Do not infer missing facts or requirements. If necessary information cannot be established from available Context or approved supporting sources, request clarification.

## Blockers

When an agent cannot safely continue:

1. Set the task to `blocked`.
2. Add a worklog entry describing:
    - the blocker;
    - why work cannot continue; and
    - what is required to unblock it.
3. Do not guess, infer missing requirements, or rewrite the task to remove the blocker.

### Agent-Resolvable Blockers

If the blocker was caused by the agent and can be corrected within the existing task scope, the agent may:

1. resolve the cause;
2. record the resolution in the worklog; and
3. return the task to `in-progress`.

### User-Owned Blockers

Leave the task `blocked` when resolution requires the user, including:

- missing or insufficient Context;
- unclear or incorrect task description;
- conflicting requirements;
- missing user decision;
- required approval or review; or
- scope changes.

Do not self-unblock these cases by making assumptions.

## Approval Gates

Task authorization does not override explicit review or approval gates.

If a task contains a step such as:

- `Wait for user review`;
- `After approval`; or
- another explicit user decision;

complete work only up to that gate and stop.

Do not perform subsequent task steps until the required approval has been provided.

## Incidental Issues

A small incidental correction may be made when it is necessary to complete the active task correctly.

Do not fold larger, unrelated, risky, or scope-expanding issues into the active task.

Instead, create a separate task through taskmd using the repository bug template.

Agent-created bug tasks must use:

```yaml
type: bug
owner: tricky-fat-cat
```

Include concise evidence and Context sufficient for user triage.

Do not investigate the incidental issue beyond what is necessary for the active task, and do not claim the newly created human-owned bug task.

## Worklogs

When worklogs are enabled (`worklogs: true` in `.taskmd.yaml`), use:

```bash
taskmd worklog <id> --add "Started implementation. Approach: ..."
taskmd worklog <id>
```

Record meaningful progress, including:

- starting work;
- important implementation or documentation decisions;
- blockers;
- blocker resolution;
- verification results; and
- completion.

Keep entries concise and factual.

## Completing a Task

A task may be completed only when:

1. every required Task or ToDo item is complete; and
2. every Acceptance Criterion is satisfied.

Also complete any verification, review, or approval required by those sections.

### Solo Workflow

1. Confirm all Tasks or ToDo items are complete.
2. Confirm all Acceptance Criteria are satisfied.
3. Run `taskmd verify <id>` when verify checks are defined.
4. Obtain any required user approval.
5. Set the task to completed.
6. Run `taskmd validate`.

```bash
taskmd verify <id>
taskmd set <id> --status completed
taskmd validate
```

Do not complete a task merely because implementation or documentation has been created.

### PR-Review Workflow

When `workflow: pr-review` is configured in `.taskmd.yaml`:

1. Follow the repository PR workflow.
2. Open the pull request only when task requirements permit it.
3. Link it to the task:

    ```bash
    taskmd set <id> --status in-review --add-pr <url>
    ```

4. Stop when the workflow requires external review or merge.

## Git Workflow

Agents may commit and push completed task work only after:

1. all Tasks or ToDo items are complete;
2. all Acceptance Criteria are satisfied;
3. required verification and reviews have completed;
4. the user has fully approved the work; and
5. the task has been closed as `completed`.

After completion:

1. stage the task changes and completed task state;
2. use taskmd's task-aware commit-message workflow when available;
3. commit the completed work;
4. push the commit.

Do not commit or push task work while it is awaiting user approval or while the task remains incomplete, blocked, or in progress.

## Dependencies

- A task with unmet dependencies should remain `pending` or become `blocked`.
- Do not bypass dependencies to make a task actionable.
- Circular dependencies are invalid; use `taskmd validate` to detect them.

## Phases

When introducing a new phase, add it to the `phases` list in `.taskmd.yaml` before assigning it to tasks.

## Validation

Run:

```bash
taskmd validate
```

before committing completed task work.

Use it to detect missing fields, invalid values, duplicate IDs, circular dependencies, and broken references.

## Reference

- Full task structure and field reference: `TASKMD_SPEC.md`
- CLI help: `taskmd --help` or `taskmd <command> --help`
- Official taskmd documentation: https://driangle.github.io/taskmd/
