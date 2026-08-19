#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

PS1='[\u@\h \W]\$ '

# Variables
export EDITOR=helix
export TERMINAL=foot

# PATH
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

# Aliases
alias hx='helix'

alias q='exit'
alias c='clear'

alias copy='wl-copy'
alias paste='wl-paste'

alias install='sudo pacman -S'
alias remove='sudo pacman -Runs'

alias grep='grep --color=auto'

alias lg='lazygit'

alias ls="eza --color=always -a --git --no-filesize --icons=always --no-time --no-user --no-permissions"
alias lst="eza --color=always -a --long --git-ignore  --no-filesize --icons=always --no-time --no-user --no-permissions -T --level 3"

alias find='fd'

alias cat='bat'

alias cd='z'
alias cdi='zi'

# Cd cwd on exit yazi
function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	command yazi "$@" --cwd-file="$tmp"
	IFS= read -r -d '' cwd < "$tmp"
	[ "$cwd" != "$PWD" ] && [ -d "$cwd" ] && builtin cd -- "$cwd"
	command rm -f -- "$tmp"
}

# Starship Prompt
eval "$(starship init bash)"

# Zoxide
eval "$(zoxide init bash)"

# Television
eval "$(tv init bash)"

source /home/tricky-fat-cat/.config/broot/launcher/bash/br
