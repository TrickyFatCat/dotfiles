#!/usr/bin/env -S nu --stdin --config ~/.config/nushell/config.nu 

def --env main [dir: string] {
    if ($dir | path type) != dir {
        return
    }

    let terminal_pid = (find-ancestor-terminal)
    let session_name = $"Develop ⎥ ($dir | path basename)"
    let appid = env-or "TERMINAL" "foot"

    if (mwm-is-client-opened $appid --title=$session_name) {
        let id = mwm-get-client-id $appid --title=$session_name
        mwm-focus-client $id
    } else {
        let result = ^zellij list-sessions -s | complete
        let session_exists = $result.exit_code == 0 and ($result.stdout | lines | any {|s| $s == $session_name})

        let args = if $session_exists {
            ["attach" $session_name]
        } else {
            [
                "--new-session-with-layout" "default-dev"
                "--session" $session_name
            ]
        }

        open-terminal --title=$session_name --dir=$dir --detached --command=zellij --args=$args
    }

    if $terminal_pid != null {
        kill $terminal_pid
    }
}
