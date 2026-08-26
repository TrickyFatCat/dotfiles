#!/usr/bin/env -S nu --config ~/.config/nushell/config.nu 

def --env main [--tui] {
    let discord_gui = env-or "DISCORD_GUI" null
    let discord_tui = env-or "DISCORD_TUI" null

    if $discord_gui == null and $discord_tui == null {
        error make ("DISCORD_GUI and DISCORD_TUI variables are not set.")
    }

    let is_gui_opened = mwm-is-client-opened $discord_gui
    let is_tui_opened = mwm-is-client-opened --title $discord_tui

    if $is_gui_opened {
        let id = mwm-get-client-id $discord_gui
        mwm-focus-client $id --focus-back
        return
    }

    if $is_tui_opened {
        let id = mwm-get-client-id --title $discord_tui
        mwm-focus-client $id --focus-back
        return
    }

    if $tui and $discord_tui != null {
        open-terminal --detached --title $discord_tui --command $discord_tui
        return
    }

    if $discord_gui != null {
        ^setsid -f $discord_gui
    }
}
