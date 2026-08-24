#!/usr/bin/env -S nu --stdin --config ~/.config/nushell/config.nu 

def --env main [dir: string] {
    let path = $dir | path expand

    if ($path | path type) != dir {
        return
    }

    let terminal_pid = (find-ancestor-terminal)
    let editor = env-or "EDITOR" "hx"
    let title = $"Edit ⎥ ($dir | path basename)"

    if (mwm-is-client-opened --title=$title) {
        let id = mwm-get-client-id --title=$title
        mwm-focus-client $id
    } else {
        open-terminal --title=$title --dir=$dir --detached --command=$editor --args=["."]
    }

    if $terminal_pid != null {
        kill $terminal_pid
    }
}
