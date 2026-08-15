#!/usr/bin/env -S nu --config ~/.config/nushell/config.nu

const TITLE = "File Manager"

def --env main [dir?: string] {
    let appid = env-or "TERMINAL" "foot"
    let command = env-or "FILE_MANAGER_TUI" null

    if $command == null {
        return
    }

    if (mwm-is-client-opened $appid --title=$TITLE) {
        let focusing_id: int = mwm-get-focusing-client-id
        let id = mwm-get-client-id $appid --title=$TITLE

        if $focusing_id == $id {
            mwm-kill-client $id
            return
        }

        let tag = mwm-get-active-tag
        mwm-move-client-to-tag $id $tag
        return
    }

    let path = if $dir == null {
        $env.HOME
    } else if ($dir | path type) == "dir" {
        $dir
    } else {
        $env.HOME
    }

    open-terminal --class=$appid --title=$TITLE --detached --command=$command --args=[$path]
}
