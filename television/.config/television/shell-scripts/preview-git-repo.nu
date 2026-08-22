#!/usr/bin/env nu

# ----- Theme -----

const colors = {
    text: "default"
    subtle: "light_gray"
    dim: "dark_gray"
    label: "light_gray"
    blue: "blue"
    green: "green"
    yellow: "yellow"
    red: "red"
    mauve: "magenta"
    pink: "magenta"
    rosewater: "light_magenta"
    maroon: "red"
    peach: "yellow"
    teal: "cyan"
}

const icons = {
    repository: "󰉋"
    path: ""
    remote: "󰖟"
    lfs: "󰋚"
    state: "󰊢"
    branch: ""
    upstream: "󰘬"
    tag: "󱈤"
    hash: ""
    subject: "󰈙"
    author: ""
    age: "󰥔"
    worktree: ""
    clean: ""
    warning: ""
    conflicts: "󱪗"
    ahead: ""
    behind: ""
    staged: "󰷊"
    modified: "󰷈"
    deleted: "󱪟"
    renamed: "󰤘"
    typechanged: "󰬲"
    untracked: "󱪝"
    stashed: "󰥥"
    submodules: "󰏗"
    changed: "󰜷"
}

const label_width = 10
const status_label_width = 12
const section_width = 28
const fetch_ttl_seconds = 300
const fetch_timeout = "0.3s"

# ----- Rendering primitives -----

def paint [fg: string, text: string] {
    $"(ansi {fg: $fg})($text)(ansi reset)"
}

def dim [text: string] {
    paint $colors.dim $text
}

def label [icon: string, name: string] {
    let padded = ($"($name):" | fill --alignment l --width $label_width)
    paint $colors.label $"($icon) ($padded)"
}

def section [name: string] {
    let icon = if $name == "Repository" {
        $icons.repository
    } else if $name == "Position" {
        $icons.branch
    } else if $name == "Worktree" {
        $icons.worktree
    } else if ($name | str starts-with "Submodules") {
        $icons.submodules
    } else {
        ""
    }
    dim ($" ($icon) ($name) " | fill --alignment c --character "─" --width $section_width)
}

def status_count_line [count: int, icon: string, name: string, fg: string] {
    if $count > 0 {
        let padded = $name | fill --alignment l --width $status_label_width
        $"(paint $fg $icon) (paint $fg $padded) (paint $colors.text ($count | into string))"
    } else {
        ""
    }
}

def status_text_line [icon: string, name: string, value: string, fg: string] {
    let padded = $name | fill --alignment l --width $status_label_width
    $"(paint $fg $icon) (paint $fg $padded) (paint $colors.text $value)"
}

# ----- Small helpers -----

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

def git_complete [repo: path, args: list<string>] {
    ^git -C $repo ...$args | complete
}

def git_stdout [repo: path, args: list<string>] {
    let result = git_complete $repo $args
    if $result.exit_code == 0 { $result.stdout | str trim } else { "" }
}

def git_success [repo: path, args: list<string>] {
    (git_complete $repo $args | get exit_code) == 0
}

# ----- Runtime fetch cache -----

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

# ----- Repository / remote data -----

def remote_display_value [repo: path, origin_url: string] {
    let fallback = $repo | path basename
    let origin_url = $origin_url | str trim

    if $origin_url == "" {
        return $fallback
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
        $origin_url
    } else {
        $"($parsed.site)/($parsed.user)/($parsed.repo)"
    }
}

def get_repository_info [repo: path] {
    let origin = git_complete $repo [remote get-url origin]
    let origin_url = if $origin.exit_code == 0 { $origin.stdout | str trim } else { "" }

    {
        path: $repo
        display_path: (compact_home $repo)
        has_origin: ($origin.exit_code == 0)
        origin_url: $origin_url
        remote_value: (remote_display_value $repo $origin_url)
    }
}

def fetch_remote_if_needed [repo: path, repo_info: record] {
    if not $repo_info.has_origin {
        return ""
    }

    if (which timeout | length) == 0 {
        return (paint $colors.yellow $"($icons.warning) remote check skipped")
    }

    if (fetch_cache_is_fresh $repo $fetch_ttl_seconds) {
        return ""
    }

    let fetch_result = (
        with-env { GIT_TERMINAL_PROMPT: "0" } {
            ^timeout $fetch_timeout git -C $repo fetch origin --quiet
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
        paint $colors.red $"($icons.warning) could not fetch remote"
    } else {
        $"(paint $colors.red $'($icons.warning) could not fetch remote') (dim $fetch_error)"
    }
}

# ----- LFS data -----

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
    let attrs = git_complete $repo [ls-files --cached --others --exclude-standard -- "**/.gitattributes" .gitattributes]
    let attr_paths = if $attrs.exit_code == 0 { $attrs.stdout | lines | uniq } else { [] }
    let worktree_attrs = $attr_paths | any {|attr| has_lfs_attribute ([$repo $attr] | path join) }

    let info_attr = git_stdout $repo [rev-parse --git-path info/attributes]
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

def get_lfs_info [repo: path] {
    let active = repo_uses_lfs $repo
    let installed = git_success $repo [lfs version]

    {active: $active, installed: $installed}
}

# ----- Repository state data -----

def git_path [repo: path, name: string] {
    let path = git_stdout $repo [rev-parse --git-path $name]

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

def get_repo_states [repo: path] {
    [
        (if (git_path_exists $repo "rebase-merge") or (git_path_exists $repo "rebase-apply") { "rebase" } else { "" })
        (if (git_path_exists $repo "MERGE_HEAD") { "merge" } else { "" })
        (if (git_path_exists $repo "CHERRY_PICK_HEAD") { "cherry-pick" } else { "" })
        (if (git_path_exists $repo "REVERT_HEAD") { "revert" } else { "" })
        (if (git_path_exists $repo "BISECT_LOG") { "bisect" } else { "" })
    ] | where {|state| $state != "" }
}

# ----- HEAD / position data -----

def get_position_info [repo: path] {
    let has_commits = git_success $repo [rev-parse --verify --quiet HEAD]
    let branch_name = git_stdout $repo [branch --show-current]
    let detached_ref = if $has_commits { git_stdout $repo [describe --tags --always HEAD] } else { "HEAD" }
    let branch = if $branch_name == "" { $"detached HEAD at ($detached_ref)" } else { $branch_name }
    let upstream = if $branch_name == "" { "" } else { git_stdout $repo [rev-parse --abbrev-ref --symbolic-full-name "@{upstream}"] }
    let tag = if $has_commits { git_stdout $repo [describe --tags --exact-match HEAD] } else { "" }
    let sep = char --unicode 1f
    let commit_fields = if $has_commits {
        git_stdout $repo [log -1 "--pretty=%h%x1f%s%x1f%an%x1f%cr"] | split row $sep
    } else { [] }

    {
        has_commits: $has_commits
        branch: $branch
        upstream: $upstream
        tag: $tag
        hash: ($commit_fields | get 0? | default "")
        subject: ($commit_fields | get 1? | default "")
        author: ($commit_fields | get 2? | default "")
        age: ($commit_fields | get 3? | default "")
    }
}

# ----- Worktree data -----

def is_conflict [line: string] {
    let xy = $line | str substring 0..1
    (($xy | str contains "U") or ($xy in ["AA" "DD"]))
}

def parse_count [text: string, pattern: string, column: string] {
    try {
        $text | parse -r $pattern | get 0 | get $column | into int
    } catch { 0 }
}

def get_worktree_info [repo: path] {
    let status = git_complete $repo [status --porcelain=v1 --branch]
    let status_lines = $status.stdout | lines
    let branch_line = $status_lines | where {|l| $l | str starts-with "##" } | get 0? | default ""
    let entries = $status_lines | where {|l| not ($l | str starts-with "##") }
    let normal_entries = $entries | where {|l| not (is_conflict $l) }

    {
        ahead: (parse_count $branch_line 'ahead (?P<ahead>\d+)' ahead)
        behind: (parse_count $branch_line 'behind (?P<behind>\d+)' behind)
        conflicts: ($entries | where {|l| is_conflict $l } | length)
        untracked: ($entries | where {|l| $l | str starts-with "??" } | length)
        staged: ($normal_entries | where {|l| ($l | str substring 0..0) in ["A" "M"] } | length)
        modified: ($normal_entries | where {|l| ($l | str substring 1..1) == "M" } | length)
        deleted: ($normal_entries | where {|l| (($l | str substring 0..0) == "D") or (($l | str substring 1..1) == "D") } | length)
        renamed: ($normal_entries | where {|l| ($l | str substring 0..0) in ["R" "C"] } | length)
        typechanged: ($normal_entries | where {|l| ($l | str substring 0..1 | str contains "T") } | length)
        stashed: (git_stdout $repo [stash list] | lines | length)
    }
}

# ----- Submodule data -----

def submodule_state [repo: path, submodule_path: string, prefix: string] {
    if $prefix == "-" {
        return {icon: $icons.warning, status: "not initialized", fg: $colors.yellow}
    }

    if $prefix == "U" {
        return {icon: $icons.conflicts, status: "conflict", fg: $colors.red}
    }

    if $prefix == "+" {
        return {icon: $icons.changed, status: "changed", fg: $colors.peach}
    }

    let full_path = [$repo $submodule_path] | path join

    if not ($full_path | path exists) {
        return {icon: $icons.warning, status: "missing", fg: $colors.red}
    }

    let sm_status = git_complete $full_path [status --porcelain=v1]

    if $sm_status.exit_code != 0 {
        return {icon: $icons.warning, status: "missing", fg: $colors.red}
    }

    let entries = $sm_status.stdout | lines

    if ($entries | length) == 0 {
        {icon: $icons.clean, status: "clean", fg: $colors.green}
    } else if ($entries | all {|line| $line | str starts-with "??" }) {
        {icon: $icons.untracked, status: "untracked", fg: $colors.mauve}
    } else {
        {icon: $icons.modified, status: "dirty", fg: $colors.peach}
    }
}

def get_submodule_info [repo: path] {
    let top_level = git_stdout $repo [rev-parse --show-toplevel]
    let repo_root = if $top_level == "" { $repo } else { $top_level }
    let gitmodules = [$repo_root ".gitmodules"] | path join

    if not ($gitmodules | path exists) {
        return {count: 0, issue_count: 0, lines: []}
    }

    let raw = git_complete $repo_root [submodule status --recursive]

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
            let state = submodule_state $repo_root $path $prefix
            let status = $state.status | fill --alignment l --width 16
            {
                status: $state.status,
                line: $"(paint $state.fg $state.icon) (paint $state.fg $status) (paint $colors.text $path)"
            }
        }
    } | where {|item| $item != null }

    if ($items | length) == 0 {
        {count: 0, issue_count: 0, lines: []}
    } else {
        {
            count: ($items | length)
            issue_count: ($items | where status != "clean" | length)
            lines: ($items | get line)
        }
    }
}

# ----- Section renderers -----

def render_repository_section [repo_info: record, lfs: record, states: list<string>, fetch_line: string] {
    let path_line = $"(label $icons.path 'path') (paint $colors.text $repo_info.display_path)"
    let remote_line = if $repo_info.has_origin {
        $"(label $icons.remote 'remote') (paint $colors.blue $repo_info.remote_value)"
    } else {
        $"(label $icons.remote 'remote') (paint $colors.yellow $'($icons.warning) not configured')"
    }
    let lfs_line = if $lfs.active and $lfs.installed {
        $"(label $icons.lfs 'lfs') (paint $colors.green 'active')"
    } else if $lfs.active {
        $"(label $icons.lfs 'lfs') (paint $colors.yellow 'configured; git-lfs missing')"
    } else {
        ""
    }
    let state_line = if ($states | length) == 0 {
        ""
    } else {
        $"(label $icons.state 'state') (paint $colors.yellow ($states | str join ', '))"
    }

    [
        (section "Repository")
        $path_line
        $remote_line
        $lfs_line
        $fetch_line
        $state_line
    ] | where {|line| $line != "" }
}

def render_position_section [head: record] {
    let rows = if $head.has_commits {
        [
            $"(label $icons.branch 'branch') (paint $colors.rosewater $head.branch)"
            (if $head.upstream == "" { "" } else { $"(label $icons.upstream 'upstream') (paint $colors.teal $head.upstream)" })
            (if $head.tag == "" { "" } else { $"(label $icons.tag 'tag') (paint $colors.rosewater $head.tag)" })
            $"(label $icons.hash 'hash') (paint $colors.maroon $head.hash)"
            $"(label $icons.subject 'subject') (paint $colors.text $head.subject)"
            $"(label $icons.author 'author') (paint $colors.mauve $head.author)"
            $"(label $icons.age 'age') (paint $colors.subtle $head.age)"
        ]
    } else {
        [
            $"(label $icons.branch 'branch') (paint $colors.rosewater $head.branch)"
            $"(label $icons.hash 'commit') (paint $colors.yellow $'($icons.warning) no commits yet')"
        ]
    }

    ["" (section "Position")] | append ($rows | where {|line| $line != "" })
}

def render_worktree_section [worktree: record] {
    let rows = [
        (status_count_line $worktree.conflicts $icons.conflicts "conflicts" $colors.red)
        (status_count_line $worktree.ahead $icons.ahead "ahead" $colors.green)
        (status_count_line $worktree.behind $icons.behind "behind" $colors.red)
        (status_count_line $worktree.staged $icons.staged "staged" $colors.blue)
        (status_count_line $worktree.modified $icons.modified "modified" $colors.peach)
        (status_count_line $worktree.deleted $icons.deleted "deleted" $colors.red)
        (status_count_line $worktree.renamed $icons.renamed "renamed" $colors.teal)
        (status_count_line $worktree.typechanged $icons.typechanged "typechanged" $colors.teal)
        (status_count_line $worktree.untracked $icons.untracked "untracked" $colors.mauve)
        (status_count_line $worktree.stashed $icons.stashed "stashed" $colors.yellow)
    ] | where {|line| $line != "" }

    let rows = if ($rows | length) == 0 { [ (paint $colors.green $"($icons.clean) clean") ] } else { $rows }

    ["" (section "Worktree")] | append $rows
}

def render_submodules_section [submodules: record] {
    if $submodules.count == 0 {
        return []
    }

    let issues_line = if $submodules.issue_count == 0 {
        ""
    } else {
        status_text_line $icons.warning "issues" ($submodules.issue_count | into string) $colors.yellow
    }
    let count = $submodules.count | into string | fill --alignment r --character "0" --width 2
    let summary = [
        $issues_line
    ] | where {|line| $line != "" }

    ["" (section $"Submodules ($count)")] | append $summary | append $submodules.lines
}

# ----- Main -----

def main [repo: path] {
    let repo = $repo | path expand

    if not (git_success $repo [rev-parse --is-inside-work-tree]) {
        return (paint $colors.red $"($icons.warning) Not a git repository: ($repo)")
    }

    let repo_info = get_repository_info $repo
    let fetch_line = fetch_remote_if_needed $repo $repo_info
    let lfs = get_lfs_info $repo
    let states = get_repo_states $repo
    let head = get_position_info $repo
    let worktree = get_worktree_info $repo
    let submodules = get_submodule_info $repo

    []
    | append (render_repository_section $repo_info $lfs $states $fetch_line)
    | append (render_position_section $head)
    | append (render_worktree_section $worktree)
    | append (render_submodules_section $submodules)
    | str join (char newline)
}
