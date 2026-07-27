#
# ~/.bashrc
#

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

PS1='[\u@\h \W]\$ '

# Variables
export EDITOR=hx

# PATH
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

# Aliases
alias q='exit'
alias c='clear'

alias grep='grep --color=auto'

alias lg='lazygit'

alias ls="eza --color=always -a --git --no-filesize --icons=always --no-time --no-user --no-permissions"
alias lst="eza --color=always -a --long --git-ignore  --no-filesize --icons=always --no-time --no-user --no-permissions -T --level 3"

alias find='fd'

alias cat='bat'

alias cd='z'
alias cdi='zi'

alias y='yazi'

# Starship Prompt
eval "$(starship init bash)"

# Zoxide
eval "$(zoxide init bash)"

# Television

echo 'eval "$(tv init bash)"' >> ~/.bashrc
eval "$(tv init bash)"
