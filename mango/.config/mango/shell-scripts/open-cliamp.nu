#!/usr/bin/env -S nu --config ~/.config/nushell/config.nu

const CLASS = "scratch.music"

def --env main [] {
    let term = (env-or "TERMINAL" "foot")

    open-terminal --class=$CLASS --detached --command="cliamp"
}
