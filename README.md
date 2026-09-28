# Dotfiles

My personal Linux configuration files, one folder per app.

These configs are made for my own machine. They may need changes before they
work on yours.

> [!WARNING]
> The configuration and documentation in this repository are made with AI
> assistance and can contain errors.

Check the files in the chosen package before you link them into your system.

## Apps

This table lists the main configured apps. The package is the top-level folder
that holds the app's config. The Docs column links to the app's documentation
in this repository.

| Package      | App                                                        | Purpose                                    | Docs                                            |
| ------------ | ---------------------------------------------------------- | ------------------------------------------ | ----------------------------------------------- |
| `dprint`     | [dprint](https://dprint.dev/)                              | Code formatter                             |                                                 |
| `fastfetch`  | [Fastfetch](https://github.com/fastfetch-cli/fastfetch)    | System information tool                    |                                                 |
| `foot`       | [foot](https://codeberg.org/dnkl/foot)                     | Wayland terminal emulator                  |                                                 |
| `helix`      | [Helix](https://helix-editor.com/)                         | Text editor                                |                                                 |
| `kanata`     | [kanata](https://github.com/jtroo/kanata)                  | Keyboard remapping                         |                                                 |
| `leaf`       | [leaf](https://leaf.rivolink.mg/)                          | Terminal Markdown previewer                |                                                 |
| `mango`      | [MangoWM](https://github.com/mangowm/mango)                | Wayland compositor                         |                                                 |
| `marksman`   | [Marksman](https://github.com/artempyanykh/marksman)       | Markdown language server                   |                                                 |
| `mpv`        | [mpv](https://mpv.io/)                                     | Media player                               |                                                 |
| `msnap`      | [msnap](https://github.com/xtheeq/msnap)                   | Screenshot and screencast tool for MangoWM |                                                 |
| `nushell`    | [Nushell](https://www.nushell.sh/)                         | Shell                                      | [Nushell Configuration](docs/nushell/README.md) |
| `starship`   | [Starship](https://starship.rs/)                           | Shell prompt                               |                                                 |
| `television` | [television](https://alexpasmantier.github.io/television/) | Fuzzy finder                               | [Television Setup](docs/television/README.md)   |
| `zellij`     | [Zellij](https://zellij.dev/)                              | Terminal workspace                         |                                                 |

## Linking with Stow

This repository uses [GNU Stow](https://www.gnu.org/software/stow/) to link
configs into the home folder. Each package mirrors the location of the app's
config in the home folder. For example, `helix/.config/helix` matches
`~/.config/helix`.

When a folder does not exist in the home folder yet, Stow links the whole
folder. For example, if `~/.config/helix` does not exist, it becomes a link to
`helix/.config/helix`. When the folder exists, Stow links each file inside it.

Files that an app creates in a linked folder are stored in the repository.

The commands below use these options:

| Option | Effect                          |
| ------ | ------------------------------- |
| `-n`   | Previews and makes no changes.  |
| `-v`   | Prints each link.               |
| `-t ~` | Links into the home folder.     |
| `-D`   | Removes the links of a package. |

1. Clone the repository and go into it.

    ```bash
    git clone https://github.com/TrickyFatCat/dotfiles.git ~/dotfiles
    cd ~/dotfiles
    ```

    Run the Stow commands below from this folder.

2. Preview the links for one package.

    ```bash
    stow -n -v -t ~ helix
    ```

    Replace `helix` with any package from the [Apps](#apps) table.

3. Create the links.

    ```bash
    stow -v -t ~ helix
    ```

4. Remove the links when you no longer need them.

    ```bash
    stow -D -v -t ~ helix
    ```

    The files in the repository stay.

## Troubleshooting

### Existing File Conflict

**Symptom**

The Stow preview ends with `All operations aborted.`

```text
LINK: .config/helix/ignore => ../../dotfiles/helix/.config/helix/ignore
LINK: .config/helix/languages.toml => ../../dotfiles/helix/.config/helix/languages.toml
WARNING! stowing helix would cause conflicts:
  * cannot stow dotfiles/helix/.config/helix/config.toml over existing target .config/helix/config.toml since neither a link nor a directory and --adopt not specified
All operations aborted.
```

**Cause**

A file already exists where Stow needs to put a link. Here it is
`~/.config/helix/config.toml`. Stow creates none of the listed links.

**Fix**

1. Move the file named after `existing target` to another folder.
2. Run the preview again. It no longer ends with `All operations aborted.`
