#!/usr/bin/env -S nu --stdin --config ~/.config/nushell/config.nu 

def --env main [dir: string] {
    if ($dir | path type) != dir {
        return
    }

    let terminal_pid = (find-ancestor-terminal)
    let command = $env | get -o GIT_TUI | default null

    if $command == null {
        return
    }

    open-terminal --dir=$dir --detached --command=$command

    if $terminal_pid != null {
        kill $terminal_pid
    }
}
