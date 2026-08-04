#!/usr/bin/env -S nu --config ~/.config/nushell/config.nu 

const TELEGRAM_APPID = "org.telegram.desktop"

def --env main [] {
    if (mwm-is-client-opened $TELEGRAM_APPID) {
        mwm-focus-client $TELEGRAM_APPID --FocusBack
        return
    }
    ^Telegram
}
