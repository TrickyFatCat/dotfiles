#!/usr/bin/env nu

const HOME_TAG: int = 1
const EXCLUDED_TAGS = []

# Allows to switch automatically to HOME_TAG if current tag is empty
# NOTE: whitout excluded tags script will bock the ability to switch to an empty tag
mmsg watch all-monitors | lines | each {|line|
    let data = $line | from json
    let mon = $data.monitors | where active == true | first
    let tag = $mon.tags | where is_active == true | first
    let is_excluded: bool = $EXCLUDED_TAGS | any {|t| $t == $tag.index}
    if $tag.client_count == 0 and ($tag.index != $HOME_TAG and not $is_excluded) {
        mmsg dispatch view,($HOME_TAG)
    }
}
