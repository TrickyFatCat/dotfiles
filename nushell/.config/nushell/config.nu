# config.nu
#
# Installed by:
# version = "0.112.2"
#
# This file is used to override default Nushell settings, define
# (or import) custom commands, or run any other startup tasks.
# See https://www.nushell.sh/book/configuration.html
#
# Nushell sets "sensible defaults" for most configuration settings, 
# so your `config.nu` only needs to override these defaults if desired.
#
# You can open this file in your default editor using:
#     config nu
#
# You can also pretty-print and page through the documentation for configuration
# options using:
#     config nu --doc | nu-highlight | less -R

# ----------------------------- #
#           Defaults            #
# ----------------------------- #
# Default buffer editor
$env.config.buffer_editor = 'hx'

# Disable welcome
$env.config.show_banner = false

# ----------------------------- #
#             PATH              #
# ----------------------------- #
use std/util "path add"

path add "~/.local/bin/"
path add "~/.cargo/bin/"
path add ($nu.default-config-dir | path join "scripts")

# ----------------------------- #
#            Plugins            #
# ----------------------------- #
const NU_PLUGIN_DIRS = [
    ($nu.current-exe | path dirname)
    ($nu.data-dir | path join 'plugins' | path join (version).version)
    ($nu.config-path | path dirname | path join 'plugins')
]

# ----------------------------- #
#           Variables           #
# ----------------------------- #
$env.EDITOR = "hx"
$env.TERMINAL = "kitty"
$env.KITTY_ALT_CONFIG = "~/.config/kitty/kitty-no-tabs.conf" | path expand -s
$env.FILE_MANAGER = "yazi"

# ----------------------------- #
#            Modules            #
# ----------------------------- #
use std/dirs

$env.NU_LIB_DIRS = [
    ($nu.default-config-dir | path join "scripts")
]

use completers.nu *
register-completers

use utils.nu *
use terminal-registry.nu *
use detect-terminal.nu *
use completers.nu *
register-completers

use tv-utils.nu *

# ----------------------------- #
#            Aliases            #
# ----------------------------- #

# Show hidden files
alias core-ls = ls
alias ls = ls -a

# Copy/Paste
alias copy = wl-copy
alias paste = wl-paste

# Install/Remove
alias install = sudo pacman -S
alias remove = sudo pacman -Runs

# Swap cat and bat
alias core-cat = cat
alias cat = bat

# Quick exit
alias q = exit

# Quick clear
alias c = clear

# Fall back alias for CD
alias core-cd = cd

# Yazi wrapper
def --env y [...args] {
    let tmp = (mktemp -t "yazi-cwd.XXXXXX")
    ^yazi ...$args --cwd-file $tmp
    let cwd = (open $tmp)
    if $cwd != $env.PWD and ($cwd | path exists) {
        cd $cwd
    }
    rm -fp $tmp
}

# Laxy Git
alias lg = lazygit

# Git
alias gs = git status
alias ga = git add
alias gf = git fetch
alias gpl = git pull
alias gp = git push

# MPV with proper profiles
alias mpv = ^mpv --profile=linux-amd,no-av1

# Eza tree view
alias lst = ^eza -a -T -L 3 --git-ignore --icons always

# ----------------------------- #
#        Implementations        #
# ----------------------------- #
mkdir ($nu.default-config-dir | path join "autoload")

# Starship
starship init nu | save -f ($nu.default-config-dir | path join "autoload/starship.nu")

# Zoxide
zoxide init nushell --cmd cd | save -f ($nu.default-config-dir | path join "autoload" "_zoxide_integration.nu")

# fzf
fzf --nushell | save -f ($nu.default-config-dir | path join "autoload" "_fzf_integration.nu")

# Temp fix to remove annoying message on start
(open ~/.config/nushell/autoload/_fzf_integration.nu
| str replace --all 'str downcase' 'str lowercase'
| save -f ~/.config/nushell/autoload/_fzf_integration.nu)

# Television
tv init nu | save -f ($nu.default-config-dir | path join "autoload/tv.nu")
