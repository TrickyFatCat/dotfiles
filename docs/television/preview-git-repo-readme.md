<h1>Television Git Repository Preview</h1>

<!--toc:start-->

- [Overview](#overview)
- [Requirements](#requirements)
- [Preview Output](#preview-output)
- [Sections](#sections)
  - [Repository](#repository)
  - [Position](#position)
  - [Worktree](#worktree)
  - [Submodules](#submodules)
- [Remote Fetch Check](#remote-fetch-check)
- [Runtime Cache](#runtime-cache)

<!--toc:end-->

## Overview

`preview-git-repo.nu` prints the preview for repositories selected by the `explorer-gitrepos` Television channel.

The preview summarizes:

- repository path and `origin` remote;
- current branch, upstream, tag, commit, author, and commit age;
- worktree counts such as staged, modified, untracked, ahead, and behind;
- Git operation state such as merge, rebase, cherry-pick, revert, or bisect;
- Git LFS status when LFS attributes are configured;
- submodule state when `.gitmodules` exists.

## Requirements

- Git
- Nerd Font

A Nerd Font is required for the preview icons to render correctly.

> [!NOTE]
> GNU `timeout` is used for the bounded remote fetch check.
> If it is not available, the preview still works and only the remote check is skipped.

## Preview Output

Example output:

```text
─────── 󰉋 Repository ───────
 path:      ~/Projects/project
󰖟 remote:    github.com/user/project

────────  Position ────────
 branch:    main
󰘬 upstream:  origin/main
󱈤 tag:       v1.2.0
 hash:      a1b2c3d
󰈙 subject:   Fix parser bug
 author:    Alice Example
󰥔 age:       3 days ago

────────  Worktree ────────
 clean

───── 󰏗 Submodules (02) ─────
 issues       1
 clean            libs/foo
 not initialized  libs/bar
```

## Sections

The preview is split into these sections:

- [Repository](#repository) — path, remote, LFS, operation state, and remote-check messages.
- [Position](#position) — branch, upstream, tag, and latest commit details.
- [Worktree](#worktree) — clean state or worktree status counts.
- [Submodules](#submodules) — submodule count and per-submodule state.

### Repository

The repository section shows identity and high-level repository state.

| Row      | Meaning                                                                |
| -------- | ---------------------------------------------------------------------- |
| `path`   | Selected repository path, with `$HOME` compacted to `~`.               |
| `remote` | Compact `origin` remote display, or `not configured` when absent.      |
| `lfs`    | Shown only when LFS attributes are found.                              |
| `state`  | Shown during merge, rebase, cherry-pick, revert, or bisect operations. |

The remote value is shortened for these Git URL formats:

- `git@host:user/repo.git`
- `https://host/user/repo.git`
- `http://host/user/repo.git`
- `ssh://host/user/repo.git`
- `host/user/repo`

A repository with an `origin` remote shows the compact remote value:

```text
─────── 󰉋 Repository ───────
 path:      ~/Projects/project
󰖟 remote:    github.com/user/project
```

A repository without an `origin` remote shows `not configured`:

```text
─────── 󰉋 Repository ───────
 path:      ~/Projects/project
󰖟 remote:     not configured
```

When LFS attributes exist, the `lfs` row shows one of these states:

- `active` when Git LFS is available;
- `configured; git-lfs missing` when LFS attributes exist but `git lfs version` fails.

```text
󰋚 lfs:       active
```

During Git operations, the `state` row shows the active operation state:

```text
󰊢 state:     rebase
```

Remote-check warnings also appear in the repository section:

```text
 remote check skipped
 could not fetch remote
```

See [Remote Fetch Check](#remote-fetch-check) for the fetch behavior behind these messages.

### Position

The position section shows the current Git position.

| Row        | Meaning                                             |
| ---------- | --------------------------------------------------- |
| `branch`   | Current branch, or detached HEAD context.           |
| `upstream` | Upstream branch, when configured.                   |
| `tag`      | Exact tag at `HEAD`, when present.                  |
| `hash`     | Short commit hash.                                  |
| `subject`  | Latest commit subject.                              |
| `author`   | Latest commit author.                               |
| `age`      | Relative commit age from Git, such as `3 days ago`. |

For a repository without commits, the position section shows:

```text
────────  Position ────────
 branch:    main
 commit:     no commits yet
```

### Worktree

The worktree section shows `clean` when there are no worktree changes, ahead/behind counts, or stashes:

```text
────────  Worktree ────────
 clean
```

When there is activity, it shows one row per non-zero status count:

```text
────────  Worktree ────────
 ahead       1
󰷊 staged      2
󰷈 modified    3
󱪝 untracked   4
󰥥 stashed     1
```

Rows appear in this order:

1. conflicts
2. ahead
3. behind
4. staged
5. modified
6. deleted
7. renamed
8. typechanged
9. untracked
10. stashed

### Submodules

This section is visible when a repository has submodules.

When all submodules are clean, the section contains only clean rows:

```text
───── 󰏗 Submodules (02) ─────
 clean            libs/foo
 clean            libs/bar
```

When one or more submodules are not clean, an `issues` row appears before the submodule list:

```text
───── 󰏗 Submodules (03) ─────
 issues       2
 clean            libs/foo
 not initialized  libs/bar
󰜷 changed          vendor/baz
```

Supported submodule states:

| State             | Meaning                                                         |
| ----------------- | --------------------------------------------------------------- |
| `clean`           | Submodule status is clean.                                      |
| `not initialized` | `git submodule status` marks the submodule with `-`.            |
| `changed`         | `git submodule status` marks the submodule with `+`.            |
| `conflict`        | `git submodule status` marks the submodule with `U`.            |
| `dirty`           | Submodule has tracked worktree changes.                         |
| `untracked`       | Submodule has only untracked files.                             |
| `missing`         | Submodule path is missing or cannot be inspected as a Git repo. |

## Remote Fetch Check

For repositories with an `origin` remote, the script attempts a bounded remote check:

```text
git fetch origin --quiet
```

Important behavior:

- fetch timeout is `300ms`;
- fetch uses `GIT_TERMINAL_PROMPT=0`, so it should not wait for credentials;
- successful fetch output is hidden;
- timeout output is hidden;
- non-timeout fetch errors are shown in the repository section;
- successful fetches are cached for 5 minutes per repository;
- fetch updates remote-tracking refs only;
- fetch does not merge, rebase, or modify checked-out files.

If GNU `timeout` is missing, the script shows this warning instead of running `git fetch`:

```text
 remote check skipped
```

If `git fetch` fails for a non-timeout reason, the script shows a fetch error in the repository section:

```text
 could not fetch remote
```

## Runtime Cache

Successful fetch timestamps are cached to avoid repeated fetch delays while moving through Television results.

Cache location priority:

1. `$XDG_RUNTIME_DIR/television-git-preview`
2. `/run/user/$UID/television-git-preview`
3. `/tmp/television-git-preview-$UID`

The cache stores timestamp files named from an MD5 hash of the repository path. It does not store remote URLs, branch names, commit hashes, credentials, or file contents.

Inspect cache files before deleting them:

```bash
uid="$(id -u)"
for dir in "${XDG_RUNTIME_DIR:-}" "/run/user/$uid" "/tmp"; do
  case "$dir" in
    "") continue ;;
    "/tmp") cache_dir="/tmp/television-git-preview-$uid" ;;
    *) cache_dir="$dir/television-git-preview" ;;
  esac

  if [ -d "$cache_dir" ]; then
    find "$cache_dir" -maxdepth 1 -type f -name '*.fetch' -print
  fi
done
```

Delete cached fetch timestamp files:

```bash
uid="$(id -u)"
for dir in "${XDG_RUNTIME_DIR:-}" "/run/user/$uid" "/tmp"; do
  case "$dir" in
    "") continue ;;
    "/tmp") cache_dir="/tmp/television-git-preview-$uid" ;;
    *) cache_dir="$dir/television-git-preview" ;;
  esac

  if [ -d "$cache_dir" ]; then
    find "$cache_dir" -maxdepth 1 -type f -name '*.fetch' -delete
  fi
done
```

The cleanup command deletes only `.fetch` files directly inside the preview cache directories.
