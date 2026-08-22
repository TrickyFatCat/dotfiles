#!/usr/bin/env nu

def paint [fg: string, text: string] {
    $"(ansi {fg: $fg})($text)(ansi reset)"
}

def dim [text: string] {
    paint "#6c7086" $text
}

def label [icon: string, name: string] {
    paint "#a6adc8" $"($icon) ($name):"
}

def status_part [count: int, icon: string, fg: string] {
    if $count > 0 { paint $fg $"($count)($icon)" } else { "" }
}

def is_conflict [line: string] {
    let xy = $line | str substring 0..1
    (($xy | str contains "U") or ($xy in ["AA" "DD"]))
}

def main [repo: path] {
    let repo = $repo | path expand
    let check = (^git -C $repo rev-parse --is-inside-work-tree | complete)

    if $check.exit_code != 0 {
        return (paint "#f38ba8" $" Not a git repository: ($repo)")
    }

    let fetch_result = (
        with-env { GIT_TERMINAL_PROMPT: "0" } {
            ^git -C $repo fetch --all --quiet
            | complete
        }
    )
    let fetch_error = $fetch_result.stderr | str trim | lines | get 0? | default ""
    let fetch_text = if $fetch_result.exit_code == 0 {
        paint "#a6e3a1" " ok"
    } else if $fetch_error == "" {
        paint "#f38ba8" " failed"
    } else {
        $"(paint '#f38ba8' ' failed') (dim $fetch_error)"
    }

    let branch_raw = (^git -C $repo branch --show-current | complete)
    let branch = $branch_raw.stdout | str trim
    let branch = if $branch == "" { "detached HEAD" } else { $branch }

    let tag_raw = (^git -C $repo describe --tags --exact-match HEAD | complete)
    let tag = if $tag_raw.exit_code == 0 {
        $tag_raw.stdout | str trim
    } else { "" }

    let commit = (
        ^git -C $repo rev-parse --short HEAD
        | complete
        | get stdout
        | str trim
    )
    let subject = (
        ^git -C $repo log -1 --pretty=%s
        | complete
        | get stdout
        | str trim
    )

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

    let status_bits = [
        (status_part $conflicted "󱪗" "#f38ba8")
        (status_part $ahead "" "#a6e3a1")
        (status_part $behind "" "#f38ba8")
        (status_part $untracked "󰷊" "#cba6f7")
        (status_part $stashed "󰥥" "#f9e2af")
        (status_part $modified "󰷈" "#fab387")
        (status_part $staged "󱪝" "#89b4fa")
        (status_part $renamed "󰤘" "#94e2d5")
        (status_part $deleted "󱪟" "#f38ba8")
        (status_part $typechanged "󰬲" "#94e2d5")
    ] | where {|x| $x != "" }

    let status_text = if ($status_bits | length) == 0 {
        paint "#a6e3a1" " clean"
    } else {
        $status_bits | str join " "
    }

    let tag_line = if $tag == "" { dim "none at HEAD" } else { paint "#f2cdcd" $tag }

    [
        $"(paint '#cdd6f4' '') (paint '#cdd6f4' ($repo | path basename))"
        $"(label '󰓦' 'fetch') ($fetch_text)"
        $"(label '' 'branch') (paint '#f2cdcd' $branch)"
        $"(label '󱈤' 'tag') ($tag_line)"
        $"(label '' 'commit') (paint '#eba0ac' $commit) (dim $subject)"
        $"(label '' 'status') ($status_text)"
    ] | str join (char newline)
}
