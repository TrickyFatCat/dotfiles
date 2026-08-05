#!/usr/bin/env -S nu --config ~/.config/nushell/config.nu 

def --env main [appid: string = "zen", --newtab] {
    if (mwm-is-client-opened $appid) and not ($newtab) {
        let id = mwm-get-client-id $appid
        mwm-focus-client $id --FocusBack
        return
    }

    xdg-open about:blank
}
