#!/usr/bin/env -S nu --stdin --config ~/.config/nushell/config.nu 

def --env main [layout: string] {
    let layout = $layout | str snake-case

    let layouts = mwm-get-layouts-names

    if $layout not-in $layouts {
        error make {msg: $"Layout ($layout) is not MangoWM layout."}
    }

    let terminal_pid = (find-ancestor-terminal)

    mmsg dispatch setlayout,($layout) o+e>| ignore

    if $terminal_pid != null {
        kill $terminal_pid
    }
}
