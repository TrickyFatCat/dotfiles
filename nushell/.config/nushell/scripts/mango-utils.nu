# Returns an id of a given appid or a title
# Both appid and title are regex patterns
#
# appid: appid/class of a target app
# --title: title of a target app
export def mwm-get-client-id [appid?: string, --title: string] {
    if ($appid == null) and ($title == null) {
        error make ("Invalid function call. Provide at least appid or --title.")
    }

    let clients = mmsg get all-clients | from json | get clients

    let matches = (
        $clients
        | where {|c| ($appid == null or ($c.appid =~ $appid)) and ($title == null or ($c.title =~ $title))}
    )

    if ($matches | is-empty) {
        null
    } else {
        $matches | get id | first
    }
}

# Checks if there's a client of a given appid and/or title is opened
# 
# appid: appid/class of a target app
# # --title: title of a target app
export def mwm-is-client-opened [appid?: string, --title: string] {
    ((mwm-get-client-id $appid --title=$title) != null)
}

# Returns a table of currently running clients
#
# fields: a list of fields to show, use mwm-get-client-field-names to see options
export def mwm-get-all-clients [fields?: list<string>] {
    let clients = mmsg get all-clients | from json | get clients

    if ($fields | is-empty) {
        $clients
    }

    $clients | select ...$fields
}

# Returns a current tag of a focused monitorm
export def mwm-get-active-tag [] {
    mmsg get all-tags
    | from json
    | get all_tags
    | flatten tags
    | flatten
    | where is_active == true
    | get index
    | first
    | into int
}

# Returns focusing client id
export def mwm-get-focusing-client-id [] {
    mwm-get-focusing-client | get id
}

#------------------------------------------
# CLIENT MANIPULATION
#------------------------------------------

# Focus a client by a given id
# 
# --focus-back: allows to focus last focusing client back
export def mwm-focus-client [id: int, --focus-back] {
    let focusing_id: int = mwm-get-focusing-client-id

    if $focusing_id == $id {
        if $focus_back {
            mmsg dispatch focuslast
        }
        return
    }
    mmsg dispatch focusid client,($id)
    return
}

# Kill a client of a given id
export def mwm-kill-client [id: int, --force] {
    if $force {
        mmsg dispatch killclient,force client,($id)
        return
    }
    mmsg dispatch killclient client,($id)
    return
}

# Moves currently focused client to tag
export def mwm-move-to-tag [tag: int] {
    if not (is-valid-tag $tag) {
        return
    }

    mmsg dispatch tag ($tag)
}

# Moves client of a given id to a given tag
export def mwm-move-client-to-tag [id: int, tag: int] {
    if not (is-valid-tag $tag) {
        return
    }

    mmsg dispatch tag,($tag) client,($id)
}

#------------------------------------------
# UTILITY
#------------------------------------------

# Returns a list of tags for a given monitor
#
# --active: will return only active tags
export def mwm-get-tags [monitor: string, --active] {
    let monitor_data = mmsg get tags $monitor | from json

    if $active {
        $monitor_data | get active_tags
        return
    }

    $monitor_data | get tags
}

# Returns a list of clients field names
export def mwm-get-client-field-names [] {
    mmsg get all-clients | from json | get clients | each { columns } | flatten | uniq
}

# Returns focused client details
export def mwm-get-focusing-client [] {
    mmsg get focusing-client | from json
}

# Returns data about last opened surfaces
export def mwm-get-last-open-surface [] {
    mmsg get last_open_surface | from json
}

# Checks if tag value is valid
def is-valid-tag [tag: int] {
    if ($tag <= 0) or ($tag > 9) {
        # error make {msg: $"tag must be greater than 0 and less or equal 9, got ($tag)"}
        print -e $"tag must be greater than 0 and less or equal 9, got ($tag)"
        return false
    }
    return true
}

# Validates a given mango config
export def mwm-validate-config [config: string = "~/.config/mango/config.conf"] {
    let path = $config | path expand

    if not ($path | path exists) {
        error make ({msg: $"Invalid mango config path: ($path)"})
    }

    ^mango -c $path -p
}

# Prints the list of existing commands
export def mwm-list-commands [] {
    help commands | where name starts-with mwm- | select name description
}
