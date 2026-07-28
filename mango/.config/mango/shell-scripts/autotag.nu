#!/usr/bin/env nu

# Allows to switch automatically to tag 1 if current tag is empty
mmsg watch all-monitors | lines | each {|line|
    let data = $line | from json
    let mon = $data.monitors | where active == true | first
    let tag = $mon.tags | where is_active == true | first

    if $tag.client_count == 0 and $tag.index != 1 {
        mmsg dispatch view,1
    }
}
