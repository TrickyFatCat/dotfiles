#!/usr/bin/env -S nu --stdin --config ~/.config/nushell/config.nu 

def --env main [dir: string] {
    let path = $dir | path expand

    if ($path | path type) != dir {
        return
    }

    let config = get-kitty-alt-config
    let title = $dir | path basename
    let editor = env-or "EDITOR" "hx"
    let terminal_pid = (find-ancestor-terminal)

    open-terminal --config=$config --title=$title --dir=$dir --detached --command=$editor --args=["."]

    if $terminal_pid != null {
        kill $terminal_pid
    }
}
