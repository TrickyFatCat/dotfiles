#!/usr/bin/env -S nu --config ~/.config/nushell/config.nu

const CLASS = "scratch.term"
const CONFIG_FILE = "~/.config/kitty/kitty-no-tabs.conf"

def --env main [] {
    let term = (env-or "TERMINAL" "kitty")

    # This config is only valid for kitty terminal
    let config = if $term == "kitty" {
        $CONFIG_FILE | path expand -s
    } else {
        null
    }

    open-terminal --class=$CLASS --config=$config --detached
}
