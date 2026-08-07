#!/usr/bin/env -S nu --config ~/.config/nushell/config.nu

const CLASS = "scratch.term"

def --env main [] {
    let term = (env-or "TERMINAL" "kitty")

    # This config is only valid for kitty terminal
    let config = if $term == "kitty" {
        env-or "KITTY_ALT_CONFIG" null
    } else {
        null
    }

    open-terminal --class=$CLASS --config=$config --detached
}
