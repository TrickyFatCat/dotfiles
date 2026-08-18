#!/usr/bin/env -S nu --config ~/.config/nushell/config.nu

const CLASS = "file.manager"

def --env main [dir?: string] {
    let appid = (env-or "TERMINAL" "foot") | append $CLASS | str join "."

    let command = env-or "FILE_MANAGER_TUI" null

    if $command == null {
        return
    }

    if (mwm-is-client-opened $appid) {
        let id = mwm-get-client-id $appid
        mwm-focus-client $id --FocusBack
        return
    }

    let path = if $dir == null {
        $env.HOME
    } else if ($dir | path type) == "dir" {
        $dir
    } else {
        $env.HOME
    }

    open-terminal --class=$appid --detached --command=$command --args=[$path]
}
