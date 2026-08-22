#!/usr/bin/env nu

def paint [fg: string, text: string] {
    $"(ansi {fg: $fg})($text)(ansi reset)"
}

def dim [text: string] {
    paint "#6c7086" $text
}

def label [icon: string, name: string] {
    let padded = ($"($name):" | fill --alignment l --width 10)
    paint "#a6adc8" $"($icon) ($padded)"
}

def section [name: string] {
    dim ($" ($name) " | fill --alignment c --character "─" --width 24)
}

def status_count_line [count: int, icon: string, name: string, fg: string] {
    if $count > 0 {
        let padded = $name | fill --alignment l --width 12
        $"(paint $fg $icon) (paint $fg $padded) (paint '#cdd6f4' ($count | into string))"
    } else {
        ""
    }
}

def status_text_line [icon: string, name: string, value: string, fg: string] {
    let padded = $name | fill --alignment l --width 12
    $"(paint $fg $icon) (paint $fg $padded) (paint '#cdd6f4' $value)"
}

def is_conflict [line: string] {
    let xy = $line | str substring 0..1
    (($xy | str contains "U") or ($xy in ["AA" "DD"]))
}

def has_lfs_attribute [file: path] {
    if not ($file | path exists) {
        return false
    }

    open --raw $file
    | lines
    | any {|line|
        let trimmed = $line | str trim
        ($trimmed != "") and (not ($trimmed | str starts-with "#")) and ($trimmed | str contains "filter=lfs")
    }
}

def repo_uses_lfs [repo: path] {
    let attrs_raw = (
        ^git -C $repo ls-files --cached --others --exclude-standard -- '**/.gitattributes' .gitattributes
        | complete
    )
    let attr_paths = if $attrs_raw.exit_code == 0 { $attrs_raw.stdout | lines | uniq } else { [] }
    let worktree_attrs = $attr_paths | any {|attr| has_lfs_attribute ([$repo $attr] | path join) }

    let info_attr_raw = (^git -C $repo rev-parse --git-path info/attributes | complete)
    let info_attr = if $info_attr_raw.exit_code == 0 { $info_attr_raw.stdout | str trim } else { "" }
    let info_attr_path = if $info_attr == "" {
        ""
    } else if ($info_attr | str starts-with "/") {
        $info_attr
    } else {
        [$repo $info_attr] | path join
    }
    let info_attrs = if $info_attr_path == "" { false } else { has_lfs_attribute $info_attr_path }

    $worktree_attrs or $info_attrs
}

def submodule_state [repo: path, submodule_path: string, prefix: string] {
    if $prefix == "-" {
        return {icon: "", status: "not initialized", fg: "#f9e2af"}
    }

    if $prefix == "U" {
        return {icon: "󱪗", status: "conflict", fg: "#f38ba8"}
    }

    if $prefix == "+" {
        return {icon: "󰜷", status: "changed", fg: "#fab387"}
    }

    let full_path = [$repo $submodule_path] | path join

    if not ($full_path | path exists) {
        return {icon: "", status: "missing", fg: "#f38ba8"}
    }

    let sm_status = (^git -C $full_path status --porcelain=v1 | complete)

    if $sm_status.exit_code != 0 {
        return {icon: "", status: "missing", fg: "#f38ba8"}
    }

    let entries = $sm_status.stdout | lines

    if ($entries | length) == 0 {
        {icon: "", status: "clean", fg: "#a6e3a1"}
    } else if ($entries | all {|line| $line | str starts-with "??" }) {
        {icon: "󱪝", status: "untracked", fg: "#cba6f7"}
    } else {
        {icon: "󰷈", status: "dirty", fg: "#fab387"}
    }
}

def submodule_section [repo: path] {
    let raw = (^git -C $repo submodule status --recursive | complete)

    if ($raw.exit_code != 0) or (($raw.stdout | str trim) == "") {
        return {count: 0, issue_count: 0, lines: []}
    }

    let items = $raw.stdout | lines | each {|line|
        let prefix = $line | str substring 0..0
        let parts = $line | str substring 1.. | str trim | split row " "
        let path = $parts | get 1? | default ""

        if $path == "" {
            null
        } else {
            let state = submodule_state $repo $path $prefix
            let status = $state.status | fill --alignment l --width 16
            {
                status: $state.status,
                line: $"(paint $state.fg $state.icon) (paint $state.fg $status) (paint '#cdd6f4' $path)"
            }
        }
    } | where {|item| $item != null }

    if ($items | length) == 0 {
        {count: 0, issue_count: 0, lines: []}
    } else {
        let rows = $items | get line
        let issue_count = $items | where status != "clean" | length
        {count: ($items | length), issue_count: $issue_count, lines: $rows}
    }
}

def preview_cache_dir [] {
    let uid_raw = ^id -u | complete
    let uid = if $uid_raw.exit_code == 0 { $uid_raw.stdout | str trim } else { $env.USER? | default "user" }
    let runtime_env = $env.XDG_RUNTIME_DIR? | default ""
    let runtime = if $runtime_env != "" {
        $runtime_env
    } else {
        let run_user = $"/run/user/($uid)"
        if ($run_user | path exists) { $run_user } else { "" }
    }

    if $runtime != "" {
        [$runtime "television-git-preview"] | path join
    } else {
        ["/tmp" $"television-git-preview-($uid)"] | path join
    }
}

def fetch_cache_file [repo: path] {
    let key = ($repo | path expand | hash md5)
    [(preview_cache_dir) $"($key).fetch"] | path join
}

def fetch_cache_is_fresh [repo: path, ttl_seconds: int] {
    let file = fetch_cache_file $repo

    if not ($file | path exists) {
        return false
    }

    let last_fetch = try { open --raw $file | str trim | into int } catch { 0 }
    let now = date now | format date "%s" | into int
    (($now - $last_fetch) < $ttl_seconds)
}

def record_fetch_cache [repo: path] {
    let dir = preview_cache_dir
    mkdir $dir
    ^chmod 700 $dir | complete | ignore

    let now = date now | format date "%s"
    $now | save --force (fetch_cache_file $repo)
}

def git_path [repo: path, name: string] {
    let raw = ^git -C $repo rev-parse --git-path $name | complete

    if $raw.exit_code != 0 {
        return ""
    }

    let path = $raw.stdout | str trim

    if $path == "" {
        ""
    } else if ($path | str starts-with "/") {
        $path
    } else {
        [$repo $path] | path join
    }
}

def git_path_exists [repo: path, name: string] {
    let path = git_path $repo $name
    ($path != "") and ($path | path exists)
}

def repo_state_line [repo: path] {
    let states = [
        (if (git_path_exists $repo "rebase-merge") or (git_path_exists $repo "rebase-apply") { "rebase" } else { "" })
        (if (git_path_exists $repo "MERGE_HEAD") { "merge" } else { "" })
        (if (git_path_exists $repo "CHERRY_PICK_HEAD") { "cherry-pick" } else { "" })
        (if (git_path_exists $repo "REVERT_HEAD") { "revert" } else { "" })
        (if (git_path_exists $repo "BISECT_LOG") { "bisect" } else { "" })
    ] | where {|state| $state != "" }

    if ($states | length) == 0 {
        ""
    } else {
        $"(label '󰊢' 'state') (paint '#f9e2af' ($states | str join ', '))"
    }
}

def compact_home [p: path] {
    let full = $p | path expand
    let home = $env.HOME | path expand

    if $full == $home {
        "~"
    } else if ($full | str starts-with $"($home)/") {
        let suffix = $full | str substring (($home | str length)..)
        $"~($suffix)"
    } else {
        $full
    }
}

def repo_display [repo: path, origin_url: string] {
    let fallback = $repo | path basename
    let origin_url = $origin_url | str trim

    if $origin_url == "" {
        return {label: "repo", value: $fallback}
    }

    let cleaned = $origin_url | str replace -r '\.git$' ''
    let parsed = if ($cleaned | str starts-with "git@") {
        $cleaned | parse -r '^git@(?P<site>[^:]+):(?P<user>.+)/(?P<repo>[^/]+)$' | get 0?
    } else if (($cleaned | str starts-with "http://") or ($cleaned | str starts-with "https://") or ($cleaned | str starts-with "ssh://")) {
        $cleaned | parse -r '^[a-z]+://(?:[^@/]+@)?(?P<site>[^/:]+)(?::\d+)?/(?P<user>.+)/(?P<repo>[^/]+)$' | get 0?
    } else {
        $cleaned | parse -r '^(?P<site>[^/:]+)/(?P<user>.+)/(?P<repo>[^/]+)$' | get 0?
    }

    if $parsed == null {
        {label: "repo", value: $fallback}
    } else {
        {label: "remote", value: $"($parsed.site)/($parsed.user)/($parsed.repo)"}
    }
}

def main [repo: path] {
    let repo = $repo | path expand
    let check = (^git -C $repo rev-parse --is-inside-work-tree | complete)

    if $check.exit_code != 0 {
        return (paint "#f38ba8" $" Not a git repository: ($repo)")
    }

    let origin_result = (^git -C $repo remote get-url origin | complete)
    let origin_url = if $origin_result.exit_code == 0 { $origin_result.stdout | str trim } else { "" }
    let display = repo_display $repo $origin_url
    let path_line = $"(label '' 'path') (paint '#cdd6f4' (compact_home $repo))"
    let state_line = repo_state_line $repo
    let has_commits = (^git -C $repo rev-parse --verify --quiet HEAD | complete | get exit_code) == 0
    let has_timeout = (which timeout | length) > 0
    let lfs_active = repo_uses_lfs $repo
    let lfs_installed = (^git lfs version | complete | get exit_code) == 0
    let lfs_line = if $lfs_active and $lfs_installed {
        $"(label '󰋚' 'lfs') (paint '#a6e3a1' 'active')"
    } else if $lfs_active {
        $"(label '󰋚' 'lfs') (paint '#f9e2af' 'configured; git-lfs missing')"
    } else {
        ""
    }

    let fetch_line = if $origin_result.exit_code != 0 {
        ""
    } else if not $has_timeout {
        paint "#f9e2af" " Remote check skipped"
    } else if (fetch_cache_is_fresh $repo 300) {
        ""
    } else {
        let fetch_result = (
            with-env { GIT_TERMINAL_PROMPT: "0" } {
                ^timeout 1s git -C $repo fetch origin --quiet
                | complete
            }
        )
        let fetch_error = $fetch_result.stderr | str trim | lines | get 0? | default ""

        if $fetch_result.exit_code == 0 {
            record_fetch_cache $repo
            ""
        } else if $fetch_result.exit_code == 124 {
            ""
        } else if $fetch_error == "" {
            paint "#f38ba8" " Could not fetch remote"
        } else {
            $"(paint '#f38ba8' ' Could not fetch remote') (dim $fetch_error)"
        }
    }

    let branch_raw = (^git -C $repo branch --show-current | complete)
    let branch_name = $branch_raw.stdout | str trim
    let detached_ref = if $has_commits {
        ^git -C $repo describe --tags --always HEAD | complete | get stdout | str trim
    } else { "HEAD" }
    let branch = if $branch_name == "" { $"detached HEAD at ($detached_ref)" } else { $branch_name }
    let upstream_raw = if $branch_name == "" {
        {stdout: "", stderr: "", exit_code: 1}
    } else {
        ^git -C $repo rev-parse --abbrev-ref --symbolic-full-name "@{upstream}" | complete
    }
    let upstream = if $upstream_raw.exit_code == 0 { $upstream_raw.stdout | str trim } else { "" }
    let upstream_line = if $upstream == "" { "" } else { $"(label '󰘬' 'upstream') (paint '#94e2d5' $upstream)" }

    let no_commits_line = ""

    let tag_raw = if $has_commits {
        ^git -C $repo describe --tags --exact-match HEAD | complete
    } else { {stdout: "", stderr: "", exit_code: 1} }
    let tag = if $tag_raw.exit_code == 0 {
        $tag_raw.stdout | str trim
    } else { "" }

    let commit = if $has_commits {
        ^git -C $repo rev-parse --short HEAD
        | complete
        | get stdout
        | str trim
    } else { "" }
    let subject = if $has_commits {
        ^git -C $repo log -1 --pretty=%s
        | complete
        | get stdout
        | str trim
    } else { "" }
    let age = if $has_commits {
        ^git -C $repo log -1 --pretty=%cr
        | complete
        | get stdout
        | str trim
    } else { "" }

    let status_raw = (^git -C $repo status --porcelain=v1 --branch | complete)
    let status_lines = $status_raw.stdout | lines
    let branch_line = (
        $status_lines
        | where {|l| $l | str starts-with "##" }
        | get 0?
        | default ""
    )
    let entries = $status_lines | where {|l| not ($l | str starts-with "##") }
    let normal_entries = $entries | where {|l| not (is_conflict $l) }

    let ahead = (
        try {
            $branch_line
            | parse -r 'ahead (?P<ahead>\d+)'
            | get 0.ahead
            | into int
        } catch { 0 }
    )
    let behind = (
        try {
            $branch_line
            | parse -r 'behind (?P<behind>\d+)'
            | get 0.behind
            | into int
        } catch { 0 }
    )

    let conflicted = $entries | where {|l| is_conflict $l } | length
    let untracked = $entries | where {|l| $l | str starts-with "??" } | length
    let staged = (
        $normal_entries
        | where {|l| ($l | str substring 0..0) in ["A" "M"] }
        | length
    )
    let modified = $normal_entries | where {|l| ($l | str substring 1..1) == "M" } | length
    let deleted = (
        $normal_entries
        | where {|l| (($l | str substring 0..0) == "D") or (($l | str substring 1..1) == "D") }
        | length
    )
    let renamed = (
        $normal_entries
        | where {|l| ($l | str substring 0..0) in ["R" "C"] }
        | length
    )
    let typechanged = (
        $normal_entries
        | where {|l| ($l | str substring 0..1 | str contains "T") }
        | length
    )
    let stashed = (
        ^git -C $repo stash list
        | complete
        | get stdout
        | lines
        | length
    )

    let worktree_status_rows = [
        (status_count_line $conflicted "󱪗" "conflicts" "#f38ba8")
        (status_count_line $ahead "" "ahead" "#a6e3a1")
        (status_count_line $behind "" "behind" "#f38ba8")
        (status_count_line $staged "󰷊" "staged" "#89b4fa")
        (status_count_line $modified "󰷈" "modified" "#fab387")
        (status_count_line $deleted "󱪟" "deleted" "#f38ba8")
        (status_count_line $renamed "󰤘" "renamed" "#94e2d5")
        (status_count_line $typechanged "󰬲" "typechanged" "#94e2d5")
        (status_count_line $untracked "󱪝" "untracked" "#cba6f7")
        (status_count_line $stashed "󰥥" "stashed" "#f9e2af")
    ] | where {|x| $x != "" }

    let worktree_status_rows = if ($worktree_status_rows | length) == 0 {
        [ (paint "#a6e3a1" " clean") ]
    } else {
        $worktree_status_rows
    }

    let tag_line = if $tag == "" { "" } else { $"(label '󱈤' 'tag') (paint '#f2cdcd' $tag)" }
    let hash_line = if $has_commits { $"(label '' 'hash') (paint '#eba0ac' $commit)" } else { "" }
    let name_line = if $has_commits { $"(label '󰎔' 'name') (paint '#cdd6f4' $subject)" } else { "" }
    let age_line = if $has_commits { $"(label '󰥔' 'age') (paint '#bac2de' $age)" } else { "" }
    let commit_line = if $has_commits { "" } else { $"(label '' 'commit') (paint '#f9e2af' ' No commits done')" }
    let submodules = submodule_section $repo
    let submodule_summary_rows = if $submodules.count == 0 {
        []
    } else {
        let issue_fg = if $submodules.issue_count == 0 { "#a6e3a1" } else { "#f9e2af" }
        [
            (status_text_line "󰏗" "number" ($submodules.count | into string) "#89b4fa")
            (status_text_line "" "issues" ($submodules.issue_count | into string) $issue_fg)
        ]
    }
    let submodule_lines = if $submodules.count == 0 {
        []
    } else {
        let rows = $submodule_summary_rows | append $submodules.lines | where {|line| $line != "" }
        ["" (section "Submodules")] | append $rows
    }

    let remote_line = if $origin_result.exit_code == 0 {
        let remote_value = if $display.label == "remote" { $display.value } else { $origin_url }
        $"(label '󰖟' 'remote') (paint '#89b4fa' $remote_value)"
    } else {
        $"(label '󰖟' 'remote') (paint '#f9e2af' ' Remote is not configured')"
    }

    let identity_lines = [
        (section "Repository")
        $path_line
        $remote_line
        $lfs_line
        $fetch_line
        $state_line
        $no_commits_line
    ] | where {|line| $line != "" }

    let head_rows = [
        $"(label '' 'branch') (paint '#f2cdcd' $branch)"
        $upstream_line
        $tag_line
        $hash_line
        $name_line
        $age_line
        $commit_line
    ] | where {|line| $line != "" }
    let head_lines = (["" (section "HEAD")] | append $head_rows)

    let status_lines = (["" (section "Status")] | append $worktree_status_rows)

    $identity_lines | append $head_lines | append $status_lines | append $submodule_lines | str join (char newline)
}
