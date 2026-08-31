# This module contains useful aliases and functions for arch-based linux distros

# Installs a package of a given name
#
# --froce (-f): skips package installation check
export def pacman-install [name: string, --force(-f)] {
    if not $force {
        if (pacman-is-package-installed $name) {
            let path = (which $name).path.0
            print $"(ansi blue)($name)(ansi reset) is installed at (ansi yellow)($path)(ansi reset)"
            return
        }
    }

    ^sudo pacman -S $name
}

# Removes a package of a given name
# NOTE. Also removes unused dependercies for this package
export def pacman-remove [name: string] {
    if not (pacman-is-package-installed $name) {
        print -e $"(ansi blue)($name)(ansi reset)(ansi red) is not installed.(ansi reset)"
        return
    }

    ^sudo pacman -Runs $name
}

# Updates all system packages
export def pacman-system-update [] {
    ^sudo pacman -Syu
}

# Synchronizes package databases
export def pacman-sync [] {
    ^sudo pacman -Sy
}

# Retrievs installed package data
export def pacman-get-package [name: string] {
    if not (is-name-valid $name) {
        error make ("Empty pakage name.")
    }

    let result = pacman-query $name

    if $result.exit_code != 0 {
        print $"(ansi red)Package ($name) not found.(ansi reset)"
    }

    $result.stdout | str trim
}

# Checks if package is installed
export def pacman-is-package-installed [name: string] {
    if not (is-name-valid $name) {
        error make ("Empty pakage name.")
    }

    (pacman-query $name).exit_code == 0
}

def is-name-valid [name: string] {
    if ($name | is-empty) {
        return false
    }

    return true
}

def pacman-query [name: string] {
    ^pacman -Q $name | complete
}
