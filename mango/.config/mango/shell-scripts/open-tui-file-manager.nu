#!/usr/bin/env -S nu --config ~/.config/nushell/config.nu

const TITLE = "File Manager"

def --env main [] {
    let appid = env-or "TERMINAL" "foot"
    let command = env-or "FILE_MANAGER_TUI" null

    if $command == 0 {
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

    open-terminal --class=$appid --title=$TITLE --detached --command=$command
}
