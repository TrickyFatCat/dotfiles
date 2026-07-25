#!/usr/bin/env nu

# A separate script to handle some fzf previews
# Path to this scrit must be added to .bashrc in order to work
def main [path: string] {
    if ($path | path type) == "dir" {
        eza --tree --color=always $path | head -n 200
    } else {
        bat -n --color=always --line-range :500 $path
    }
}
