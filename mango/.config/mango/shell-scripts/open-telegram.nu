#!/usr/bin/env -S nu --config ~/.config/nushell/config.nu 

const TELEGRAM_APPID = "org.telegram.desktop"

def --env main [] {
    if (mwm-is-client-opened $TELEGRAM_APPID) {
        let id = mwm-get-client-id $TELEGRAM_APPID
        mwm-focus-client $id --FocusBack
        return
    }

    ^Telegram
}
