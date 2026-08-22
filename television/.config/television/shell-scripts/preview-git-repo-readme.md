# Git Repository Preview for Television

A Nushell preview script for browsing Git repositories in [Television](https://github.com/alexpasmantier/television).

The script shows repository identity, current Git position, worktree state, LFS state, and submodule information in a compact terminal-friendly layout.

> Disclaimer: this script and documentation were developed with AI assistance. Review and test before using it in your own environment.

## Files

Main script:

```text
output/preview-git-repo.nu
```

## Requirements

Required:

- `nu` / Nushell
- `git`
- Television

Optional:

- `timeout` from GNU coreutils, used to bound remote fetch checks
- `git-lfs`, only needed if repositories use Git LFS
- Nerd Font, recommended for icons

## Installation

Copy the script into Television's config directory:

```bash
mkdir -p ~/.config/television/shell-scripts
cp output/preview-git-repo.nu ~/.config/television/shell-scripts/preview-git-repo.nu
chmod +x ~/.config/television/shell-scripts/preview-git-repo.nu
```

Use this preview configuration in the Television channel TOML:

```toml
[preview]
command = "~/.config/television/shell-scripts/preview-git-repo.nu '{}'"
shell = "nu"
```

## Layout

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
```

If the repo has submodules, a fourth section appears:

```text
─────── 󰏗 Submodules ───────
󰏗 number       2
 issues       1
 clean            libs/foo
 not initialized  libs/bar
```

## Sections

### Repository

Shows:

- local path, with `$HOME` compacted to `~`
- `origin` remote, if configured
- warning if no remote is configured
- LFS status, only when LFS attributes are found
- Git operation state, such as merge/rebase/cherry-pick/revert/bisect
- remote fetch warning, only if a non-timeout fetch error occurs

### Position

Shows:

- branch name or detached HEAD context
- upstream branch, when configured
- exact tag at `HEAD`, when present
- commit hash
- commit subject
- commit author
- commit age

If the repository has no commits, this section shows:

```text
 commit:     no commits yet
```

### Worktree

Shows clean state or non-zero worktree status rows.

Status order:

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

Hidden when the repository has no `.gitmodules` file.

When present, shows:

- total number of submodules
- number of submodule issues
- per-submodule state

Supported submodule states:

- `clean`
- `not initialized`
- `changed`
- `conflict`
- `dirty`
- `untracked`
- `missing`

## Remote fetch behavior

The script performs a bounded remote check:

```text
git fetch origin --quiet
```

Important details:

- fetch timeout is `300ms`
- successful fetch output is hidden
- fetch timeout is hidden
- non-timeout fetch errors are shown
- fetch uses `GIT_TERMINAL_PROMPT=0`, so it should not wait for credentials
- fetch updates remote-tracking refs only; it does not merge, rebase, or modify checked-out files

## Runtime cache

To avoid repeated fetch delays while browsing, successful fetch timestamps are cached for 5 minutes.

Cache location priority:

1. `$XDG_RUNTIME_DIR/television-git-preview`
2. `/run/user/$UID/television-git-preview`
3. `/tmp/television-git-preview-$UID`

The cache stores only timestamp files named from an MD5 hash of the repo path. It does not store remote URLs, branch names, commit hashes, credentials, or file contents.

To clear the runtime cache:

```bash
find "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/television-git-preview" -type f -name '*.fetch' -delete
```

## Performance notes

The script is optimized for preview use:

- commit hash, subject, author, and age are collected with one `git log` command
- submodule inspection is skipped when `.gitmodules` does not exist
- remote fetch is bounded to `300ms`
- successful fetches are cached for the current runtime session

If first-selection delay is still noticeable, the next likely optimization is making remote fetch optional or disabled by default.

## Troubleshooting

### Icons look wrong

Install and select a Nerd Font in your terminal.

### Colors look different than expected

The script uses standard terminal colors rather than fixed hex colors, so colors follow your active terminal theme.

### Preview says `not configured`

The repository does not have an `origin` remote:

```bash
git -C /path/to/repo remote -v
```

### Submodules do not show

The section is hidden when `.gitmodules` does not exist. Check:

```bash
test -f /path/to/repo/.gitmodules && echo has-submodules
```

### LFS does not show

The LFS line is hidden unless LFS attributes are found in `.gitattributes` or `.git/info/attributes`.
