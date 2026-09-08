# Documentation Work

These instructions apply to documentation work under `/docs` in addition to the repository-level `AGENTS.md`.

# Evidence and Context

Treat resolved task Context as the primary evidence for generated documentation.

- Describe only facts and behavior supported by task Context or necessary supporting repository files.
- Do not infer missing configuration behavior, intent, requirements, or relationships between files.
- Inspect additional repository files only when necessary to provide context required by the requested document.
- Additional inspection does not expand the active task's scope.
- Preserve the scope and level of detail requested by the task. Do not broaden documentation merely because more information is available.

If required information cannot be established from available sources:

- do not guess;
- ask the user for clarification; and
- follow the task blocker workflow when the missing information prevents progress.

# External Sources

Use external sources only when they are:

- explicitly provided by the active task;
- approved by the user; or
- listed as approved repository-wide sources in the root `AGENTS.md`.

Prefer direct official documentation over broad web search.

Do not substitute unapproved sources when approved sources do not provide the required information. Ask for clarification or additional source authorization instead.

# Documentation Changes

Keep documentation changes limited to the active task.

- Do not add unrelated sections, guides, examples, or background information.
- Do not document behavior that cannot be verified from available evidence.
- Preserve established terminology and document structure unless the task requires changing them.
- Do not modify configuration or implementation files merely to make documentation easier to write unless the active task explicitly authorizes those changes.

# Task Workflow

Documentation tasks still follow `/docs/tasks/AGENTS.md` for task selection, Context resolution, blockers, approval gates, completion, validation, and Git workflow.
