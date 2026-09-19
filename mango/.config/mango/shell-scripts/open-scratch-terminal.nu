#!/usr/bin/env -S nu --config ~/.config/nushell/config.nu

const CLASS = "scratch.term"

def --env main [] {
    open-terminal --class=$CLASS --detached
}
