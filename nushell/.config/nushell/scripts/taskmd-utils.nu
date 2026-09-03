#---------------------
# TASKMD UTILITY MODULE
#---------------------
# Provides utility furctions for taskmd
# Requires taskmd https://driangle.github.io/taskmd/ 

export-env {
    $env.TMD_CONFIG = "~/.taskmd.yaml"
}

# Taskmd alias
export alias tmd = ^taskmd

# Starts web view
export def 'tmd view' [] {
    ^taskmd web start --open
}

# Validates given task id
#
# id: id to check
def is-valid-task-id [id: string] {
    taskmd snapshot | from json | get tasks | get id | any {|e| $e == $id}
}

# Prints task data into stdout
#
# task: id, title, file path, or fuzzy search of a task
# --json: Enables json output format
export def 'tmd show' [task: string, --json] {
    mut args = [$task]

    if $json {
        $args = ($args | append $"--format=json")
    }

    ^taskmd get ...$args
}

# Changes title of a given task
# TODO: Add --file-name option
#
# id: id of a task
# title: New title of a task. Does not affect file name
# --dry-run: Preview changes without writing to disk
export def 'tmd rename' [id: string, title: string, --dry-run] {
    mut args = [$id, "--title", $title]

    if $dry_run {
        $args = ($args | append $"--dry-run")
    }

    tmd set ...$args
}

# Sets status of the given task
# 
# id: id of a given task
# status: New status
# dry_run: Preview changes without writing to disk
def 'set status' [id: string, status: string, dry_run: bool = false] {
    if not (is-valid-task-id $id) {
        print -e $"(ansi red)Invalid task id ($id) or task list is empty(ansi reset)"
        return
    }

    let cur_status = tmd show $id --json | from json | get status

    if $status == $cur_status {
        print -e $"Task is already has status ($status)."
        return
    }

    mut args = [$id, "--status", $status]

    if $dry_run {
        $args = ($args | append $"--dry-run")
    }

    tmd set ...$args
}

# Sets status of a given task to in-progress
#
# id: id of a given task
# --dry-run: Preview changes without writing to disk
export def 'tmd start' [id: string, --dry-run, --quiet] {
    set status $id in-progress $dry_run
}

# Sets status of a given task to completed
# 
# id: id of a given task
# --dry-run: Preview changes without writing to disk
export def 'tmd complete' [id: string, --dry-run, --quiet] {
    set status $id completed $dry_run
}

# Sets status of a given task to blocked
# 
# id: id of a given task
# --dry-run: Preview changes without writing to disk
export def 'tmd block' [id: string, --dry-run, --quiet] {
    set status $id blocked $dry_run
}

# Sets status of a given task to cancelled
# 
# id: id of a given task
# --dry-run: Preview changes without writing to disk
export def 'tmd cancel' [id: string, --dry-run, --quiet] {
    set status $id cancelled $dry_run
}

# Sets status of a given task to in-review
# 
# id: id of a given task
# --dry-run: Preview changes without writing to disk
export def 'tmd review' [id: string, --dry-run, --quiet] {
    set status $id in-review $dry_run
}

# Sets status of a given task to pending
# 
# id: id of a given task
# --dry-run: Preview changes without writing to disk
export def 'tmd pending' [id: string, --dry-run, --quiet] {
    set status $id pending $dry_run
}

# Sets priority of a given task
# Possible priorities: low, medium, high, critical
#
# id: id of a task
# priority: New priority
# dry_run: Preview changes without writing to disk
def 'tmd set priority' [id: string, priority: string, dry_run: bool = false] {
    if not (is-valid-task-id $id) {
        print -e $"(ansi red)Invalid task id ($id) or task list is empty(ansi reset)"
        return
    }

    let cur_priority = tmd show $id --json | from json | get priority

    if $priority == $cur_priority {
        print -e $"Task is already has priority ($priority)."
        return
    }

    mut args = [$id, "--priority", $priority]

    if $dry_run {
        $args = ($args | append "--dry-run")
    }

    ^taskmd set ...$args
}

# Sets priority of a given task to low
# 
# id: id of a given task
# --dry-run: Preview changes without writing to disk
export def 'tmd low' [id: string, --dry-run, --quiet] {
    tmd set priority $id low $dry_run
}

# Sets priority of a given task to medium
# 
# id: id of a given task
# --dry-run: Preview changes without writing to disk
export def 'tmd medium' [id: string, --dry-run, --quiet] {
    tmd set priority $id medium $dry_run
}

# Sets priority of a given task to high
# 
# id: id of a given task
# --dry-run: Preview changes without writing to disk
export def 'tmd high' [id: string, --dry-run, --quiet] {
    tmd set priority $id high $dry_run
}

# Sets priority of a given task to critical
# 
# id: id of a given task
# --dry-run: Preview changes without writing to disk
export def 'tmd critical' [id: string, --dry-run, --quiet] {
    tmd set priority $id critical $dry_run
}
