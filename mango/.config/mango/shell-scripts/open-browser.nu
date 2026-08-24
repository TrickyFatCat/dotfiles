#!/usr/bin/env -S nu --config ~/.config/nushell/config.nu 

def --env main [url?: string] {
    let browser = env-or "BROWSER" "xdg-open"

    if $browser == "xdg-open" {
        print -e $"BROWSER is not configured. Using xdg-open fallback"
        ^setsid -f xdg-open ($url | default "about:blank")
        return
    }

    let appid = env-or "BROWSER_APPID" $browser

    if (mwm-is-client-opened $appid) {
        let id = mwm-get-client-id $appid
        mwm-focus-client $id --focus-back
        return
    }

    if $url == null {
        ^setsid -f $browser
        return
    }

    ^setsid -f $browser $url
}
