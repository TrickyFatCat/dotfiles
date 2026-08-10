#!/usr/bin/env -S nu --config ~/.config/nushell/config.nu 

def --env main [
    --class: string
    --title: string
    --keybindings: string
    ...args: string
] {
    let appid = if ($class | is-empty) {
        env-or "TERMINAL" "kitty"
    } else {
        $class
    }

    if (mwm-is-client-opened $appid --title=$title) {
        let focusing_id: int = mwm-get-focusing-client-id
        let id = mwm-get-client-id $appid --title=$title

        if $focusing_id == $id {
            mwm-kill-client $id
            return
        }

        # TODO: Either make it optioanal or remove. Clients can be global.
        let tag = mwm-get-active-tag
        mwm-move-client-to-tag $id $tag
        return
    }

    # This config is only valid for kitty terminal
    let config = if $appid == "kitty" {
        $env | get -o "KITTY_ALT_CONFIG" | default null
    } else {
        null
    }

    mut full_args = $args
    if $keybindings != null {
        $full_args = ($full_args | append $"--keybindings=($keybindings)")
    }
    open-terminal --class=$appid --title=$title --config=$config --detached --command=tv --args=$full_args
}
