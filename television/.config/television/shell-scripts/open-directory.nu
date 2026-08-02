#!/usr/bin/env -S nu --stdin --config ~/.config/nushell/config.nu 

def --env main [dir: string, --use-file-manager] {
    if ($dir | path type) != dir {
        return
    }

    let terminal_pid = (find-ancestor-terminal)
    let command = if $use_file_manager {
        $env | get -o FILE_MANAGER
    } else {
        null
    }

    open-terminal --dir=$dir --detached --command=$command

    if $terminal_pid != null {
        kill $terminal_pid
    }
}
