#!/usr/bin/env -S nu --config ~/.config/nushell/config.nu

const CLASS = "scratch.todo"

def main [] {
    let todo_file = $env.HOME | path join "Documents/todo.txt"
    open-terminal --class=$CLASS --detached --command=tuxedo --args=[$todo_file]
}
