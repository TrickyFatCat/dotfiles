#!/usr/bin/env -S nu --config ~/.config/nushell/config.nu 

def --env main [url?: string, --private] {
    let appid = get-browser-appid

    if (mwm-is-client-opened $appid) {
        let id = mwm-get-client-id $appid
        mwm-focus-client $id --focus-back
        return
    }

    open-browser $url
}
