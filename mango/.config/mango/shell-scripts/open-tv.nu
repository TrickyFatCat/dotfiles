#!/usr/bin/env -S nu --config ~/.config/nushell/config.nu 

def --env main [--keybindings: string, ...args: string] {
    mut full_args = $args
    if $keybindings != null {
        $full_args = ($full_args | append $"--keybindings=($keybindings)")
    }
    open-terminal --class=project-chooser --detached --command=tv --args=$full_args
}
