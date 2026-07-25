# A function which allows to add a PATH to .bashrc from Nushell
# You can specify your path
# Or you can pipe it like pwd | add-to-bashrc-path
export def add-to-bashrc-path [dir?: string] {
    let dir = if ($dir | is-empty) { $in } else { $dir }
    let dir = $dir | path expand

    if not ($dir | path exists) {
        print $"(ansi red_bold)Error:(ansi reset) ($dir) does not exist"
        return
    }

    let type = $dir | path type

    if $type == "file" {
        let mode = ls -la $dir | get 0.mode
        let is_exec = $mode | str contains "x"

        if $is_exec {
            print $"(ansi red_bold)Error:(ansi reset) ($dir) is an (ansi yellow)executable file(ansi reset), not a directory"
        } else {
            print $"(ansi red_bold)Error:(ansi reset) ($dir) is a (ansi yellow)file(ansi reset), not a directory"
        }
        return
    }

    if $type != "dir" {
        print $"(ansi red_bold)Error:(ansi reset) ($dir) is not a directory (ansi purple)\(type: ($type)\)(ansi reset)"
        return
    }

    let bashrc = $env.HOME | path join ".bashrc"

    # Replace the home directory prefix with $HOME for portability
    let display_dir = if ($dir | str starts-with $env.HOME) {
        $dir | str replace $env.HOME "$HOME"
    } else {
        $dir
    }

    let line = $"export PATH=\"($display_dir):\$PATH\""

    let existing = open $bashrc | lines | any {|l| $l == $line}

    if $existing {
        print $"(ansi yellow)Already present(ansi reset) in ($bashrc)"
    } else {
        $line | save --append $bashrc
        print $"(ansi green_bold)Added(ansi reset) to (ansi cyan)($bashrc)(ansi reset): (ansi light_gray)($line)(ansi reset)"
    }
}
