#!/usr/bin/env -S nu --config ~/.config/nushell/config.nu 

def main [...args: string] {
    if "gui" in $args {
        if ("/tmp/msnap-cast.pid" | path exists) {
            # actively recording -> this press means "stop"
            msnap cast --toggle
            return
        }

        # is a gui process genuinely still alive?
        let gui_pid = pgrep -f "qs -p.*msnap/gui" | complete
        let gui_alive = ($gui_pid.exit_code == 0)

        if $gui_alive {

            # lock file says busy AND a real process backs it up -> leave it alone
            # (it's genuinely open somewhere; a second press here would be a no-op anyway)
            return
        } else {
            # nothing alive - clear any stale lock/state and open fresh, automatically
            rm -f /tmp/msnap-gui.lock /tmp/msnap-cast.pid /tmp/msnap-cast.filepath /tmp/msnap-cast.starttime
            flock -n /tmp/msnap-gui.lock msnap ...$args
        }
    } else {
        ^setsid msnap ...$args
    }
}
