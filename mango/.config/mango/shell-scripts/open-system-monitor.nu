#!/usr/bin/env -S nu --config ~/.config/nushell/config.nu

const TITLE = "System Monitor"

def --env main [] {
    let appid = env-or "TERMINAL" "foot"
    let command = env-or "SYS_MONITOR_TUI" null

    if (mwm-is-client-opened $appid --title=$TITLE) {
        let focusing_id: int = mwm-get-focusing-client-id
        let id = mwm-get-client-id $appid --title=$TITLE

        if $focusing_id == $id {
            mwm-kill-client $id
            return
        }

        # NOTE: At the moment system monitor isn't global.
        # TODO: Might be a good option to check if it's global, in case if it was made one
        let tag = mwm-get-active-tag
        mwm-move-client-to-tag $id $tag
        return
    }

    open-terminal --title=$TITLE --detached --command=$command
}
