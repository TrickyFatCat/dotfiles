# Fuzzy-pick a file or dir, returns the path
export def fp [] {
    ^fd --hidden --strip-cwd-prefix --exclude .git
    | tv
}

# Fuzzy-pick a file and open it in $env.EDITOR
export def fe [] {
    let file = (^tv text-files)
    if ($file | is-not-empty) {
        ^$env.EDITOR $file
    }
}
