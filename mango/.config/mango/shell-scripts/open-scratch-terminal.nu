#!/usr/bin/env -S nu --config ~/.config/nushell/config.nu

const CLASS = "scratch.term"

def --env main [] {
    let term = (env-or "TERMINAL" "foot")

    open-terminal --class=$CLASS --detached
}
