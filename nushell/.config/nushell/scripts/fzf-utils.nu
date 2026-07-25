# fzf-utils: fuzzy-finder helper commands built on fzf + fd + bat + eza + zoxide

# Sets FZF_* env vars
# Call once from config.nu
export def --env fzf-utils-setup [] {
    $env.FZF_DEFAULT_COMMAND = "fd --hidden --strip-cwd-prefix --exclude .git"
    $env.FZF_CTRL_T_COMMAND = $env.FZF_DEFAULT_COMMAND
    $env.FZF_ALT_C_COMMAND = "fd --type=d --hidden --strip-cwd-prefix --exclude .git"
    $env.FZF_CTRL_T_OPTS = "--height 40% --layout reverse --border --preview 'fzf-preview.nu {}'"
    $env.FZF_CTRL_R_OPTS = "--height 40% --layout reverse --border"
}

# Native Nushell list
export def fzf-preview-options [] {
    [
        --height
        40%
        --layout
        reverse
        --border
        --preview
        'fzf-preview.nu {}'
    ]
}

def fzf-cd-preview [] {
    [
        --height
        40%
        --layout
        reverse
        --border
        --preview
        'eza --tree --color=always {} | head -200'
    ]
}

# Fuzzy-cd across the whole system
export def --env cda [] {
    let dir = (
        zoxide query -l
        | lines
        | str join "\n"
        | fzf ...(fzf-cd-preview)
    )
    if ($dir | is-not-empty) {
        cd $dir
    }
}

# Fuzzy-cd in local tree
export def --env cdl [] {
    let dir = (
        ^fd --type=d --hidden --strip-cwd-prefix --exclude .git
        | fzf ...(fzf-cd-preview)
    )
    if ($dir | is-not-empty) {
        cd $dir
    }
}

# Fuzzy-pick a file or dir, returns the path
export def fp [] {
    ^fd --hidden --strip-cwd-prefix --exclude .git
    | fzf ...(fzf-preview-options)
}

# Fuzzy-pick a file and open it in $env.EDITOR
export def fe [] {
    let file = (fp)
    if ($file | is-not-empty) {
        ^$env.EDITOR $file
    }
}

# Fuzzy-pick a running process and kill it
export def fkill [] {
    let proc = (
        ps
        | each {|p| $"($p.pid)\t($p.name)"}
        | str join "\n"
        | fzf ...(fzf-preview-options) 
    )
    if ($proc | is-not-empty) {
        let pid = (
            $proc
            | split column "\t"
            | get column1.0
            | into int
        )
        kill $pid
    }
}
