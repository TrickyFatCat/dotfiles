#!/usr/bin/env -S nu --config ~/.config/nushell/config.nu 

def --env main [
    --class: string
    --title: string
    --detached
    --keybindings: string
    ...args: string
] {
    mut full_args = $args
    if $keybindings != null {
        $full_args = ($full_args | append $"--keybindings=($keybindings)")
    }
    open-terminal --class=$class --title=$title --detached=$detached --command=tv --args=$full_args
}
