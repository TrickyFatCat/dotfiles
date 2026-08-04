# Returns an id of a given appid and optional title
export def mwm-get-client-id [appid: string, --title: string] {
    let clients = mmsg get all-clients | from json | get clients
    mut id = -1

    let matches = (
        $clients
        | where {|c| ($c.appid == $appid) and ($title == null or $c.title == $title) }
    )

    if ($matches | is-empty) {
        null
    } else {
        $matches | get id | first
    }
}

# Checks if there's a client of a given appid and/or title is opened
export def mwm-is-client-opened [appid: string, --title: string] {
    ((mwm-get-client-id $appid --title=$title) != null)
}

# Returns a list of clients field names
export def mwm-get-clients-field-names [] {
    mmsg get all-clients | from json | get clients | each { columns } | flatten | uniq
}

# Returns a table of currently running clients
export def mwm-get-all-clients [fields?: list<string>] {
    let clients = mmsg get all-clients | from json | get clients

    if ($fields | is-empty) {
        $clients
    }

    $clients | select ...$fields
}

# Returns focused client details
export def mwm-get-focusing-client [] {
    mmsg get focusing-client | from json
}

# Returns focusing client id
export def mwm-get-focusing-client-id [] {
    mwm-get-focusing-client | get id
}

# Returns a list of tags for a given monitor
export def mwm-get-tags [monitor: string, --active-only] {
    let monitor_data = mmsg get tags $monitor | from json

    if $active_only {
        $monitor_data | get active_tags
    }

    $monitor_data | get tags
}

# Focus a client by a given appid and/or title
export def mwm-focus-client [appid: string, --title: string, --FocusBack] {
    let id = mwm-get-client-id $appid --title=$title

    if $id == null {
        return
    }

    let focusing_id: int = mwm-get-focusing-client-id

    if $focusing_id == $id {
        if $FocusBack {
            mmsg dispatch focuslast
        }
        return
    }
    mmsg dispatch focusid client,($id)
    return
}
