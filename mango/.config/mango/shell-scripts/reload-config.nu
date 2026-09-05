#!/usr/bin/env -S nu --config ~/.config/nushell/config.nu

def --env main [] {
    mmsg dispatch reload_config
    notify-send "MangoWM" $"Config has been reloaded."
    mwm-validate-config
}
