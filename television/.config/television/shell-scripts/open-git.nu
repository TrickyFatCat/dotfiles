#!/usr/bin/env -S nu --stdin --config ~/.config/nushell/config.nu 

def --env main [dir: string] {
    let path = $dir | path expand

    if ($path | path type) != dir {
        return
    }

    let terminal_pid = (find-ancestor-terminal)
    let command = env-or "GIT_TUI" null

    if $command == null {
        return
    }

    let title = $"Git ⎥ ($dir | path basename)"

    if (mwm-is-client-opened --title=$title) {
        let id = mwm-get-client-id --title=$title
        mwm-focus-client $id
    } else {
        open-terminal --title=$title --dir=$dir --detached --command=$command
    }

    if $terminal_pid != null {
        kill $terminal_pid
    }
}
