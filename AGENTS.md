# Purpose and Scope

This repository contains Linux dotfiles, configuration files, scripts, and related documentation.

These instructions apply repository-wide unless a more specific `AGENTS.md` adds narrower rules.

Agents should make minimal, task-focused changes and preserve existing repository conventions unless the active task explicitly requires otherwise.

# General Working Rules

- Treat the active task as the primary scope boundary.
- Do not silently expand task scope.
- Do not infer missing requirements, behavior, or intent.
- Ask for clarification when a required fact or decision is unsupported by available context.
- Make only changes necessary to complete the active task correctly.
- Preserve existing structure, terminology, formatting, and conventions unless changing them is part of the task.
- Do not perform opportunistic refactoring, cleanup, reformatting, or unrelated changes.
- Respect explicit approval and review gates before continuing past them.

# Task Management

This repository uses taskmd for work tracking.

Task files and task-specific workflow rules are maintained under `/docs/tasks`.

Before selecting, starting, modifying, or completing a task, follow:

- `/docs/tasks/AGENTS.md` for repository task workflow;
- `/docs/tasks/TASKMD_SPEC.md` for task structure and field semantics.

Repository-wide task safety rules:

- Agents may work only on tasks whose `owner` explicitly includes `agent`.
- The ownership restriction is a hard boundary and must not be bypassed, even when the user names an ineligible task.
- Agent tasks require usable task Context before work begins.
- Explicit user-review or approval gates must be respected.
- A task may be completed only when all required ToDo items and Acceptance Criteria are satisfied.

# Repository Changes

Keep changes minimal and limited to what the active task requires.

A small incidental issue may be fixed as part of the active task only when the fix is necessary for correctness and low-risk.

If an incidental issue is larger, unrelated, risky, or would materially expand task scope:

- do not fix it as part of the active task;
- create a separate `bug` task through taskmd;
- assign it to `tricky-fat-cat`;
- include concise evidence and Context sufficient for triage; and
- continue the active task when the issue does not block it.

Creating a bug task records the issue; it does not authorize the agent to work on that task.

# Git Safety

Do not commit or push incomplete or unapproved task work.

Follow `/docs/tasks/AGENTS.md` for the task completion, validation, commit, and push workflow.

Do not amend, rewrite, force-push, or otherwise alter published history unless the user explicitly authorizes it.

# Approved External Sources

Repository-wide external sources should be listed only when they directly support agent work across the repository.

## Task Management

- taskmd documentation: https://driangle.github.io/taskmd/
- taskmd repository: https://github.com/driangle/taskmd

Use these sources when taskmd behavior, commands, or workflow semantics need clarification.

Other software documentation should normally be provided by the active task or a more specific `AGENTS.md`.

# Safety and Precedence

Apply instructions in this order:

1. explicit user instructions;
2. the active task;
3. the most specific applicable `AGENTS.md`;
4. this repository-level `AGENTS.md`;
5. supporting references and documentation.

More specific instructions may add constraints but must not silently weaken repository-wide safety boundaries.

Hard safety boundaries include:

- agent task ownership requirements;
- required task Context;
- explicit approval and review gates;
- task completion requirements;
- restrictions on unrelated scope expansion; and
- restrictions on committing or pushing incomplete or unapproved work.

An explicit request to work on a task does not override the task-ownership boundary.

If instructions conflict in a way that changes scope, ownership, approval requirements, safety, or expected behavior, do not guess which rule to follow. Stop the affected work and ask the user to resolve the conflict.

Do not use examples, documentation, or reference material as authorization to bypass an explicit task or repository rule.
