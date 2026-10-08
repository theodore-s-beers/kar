# kar

_kar(acter)_: copy one or more Unicode chars to the clipboard on Linux, macOS, or Windows.

## Build and run

In an initialized opam switch, install the project deps, then build and run:

```sh
opam install --deps-only .
dune build
dune exec kar -- U+1F600
```

The executable is built at `_build/default/bin/main.exe`.

## Install

From a local clone:

```sh
opam install .
```

Or directly from GitHub:

```sh
opam pin add kar git+https://github.com/theodore-s-beers/kar.git
```

## Usage

Assuming `kar` is in `PATH`:

```sh
kar U+1F600         # 😀
kar 0x00E9          # é
kar 41              # A
kar 48 65 6C 6C 6F  # Hello
kar U+0065 U+0301   # e followed by acute accent
```

Pass one or more hexadecimal Unicode scalar values, one per argument, separated by spaces. The `U+` and `0x` prefixes are optional and case-insensitive. Bare numbers are also treated as hexadecimal. Valid values range from `0000` to `10FFFF`, excluding surrogates (`D800`–`DFFF`).

Quoted lists like `kar "48 65"` are currently not supported.

Options can appear before, between, or after the code points. Use `kar --help` (or `kar -h`) to list them, and `--` to end option parsing.

`kar` concatenates the code points in the supplied order, without normalization or added spaces or newlines, and sends the full sequence to the clipboard in one operation. If any arg is invalid, no copy takes place.

The confirmation message lists each code point and its Unicode name. For example, for `kar U+0065 U+0301`:

```text
Copied to clipboard:
U+0065 LATIN SMALL LETTER E
U+0301 COMBINING ACUTE ACCENT
```

## Clipboard support

The backend is selected automatically:

| Platform        | Requirement                   |
| --------------- | ----------------------------- |
| macOS           | `pbcopy`                      |
| Linux / Wayland | `wl-copy` from `wl-clipboard` |
| Linux / X11     | `xclip` or `xsel`             |
| Windows         | `powershell.exe`              |

On Linux, run in a graphical session. Use a UTF-8 locale with `xsel`.

For SSH or terminal-only environments, you can request the terminal's clipboard instead:

```sh
kar --osc52 U+1F600
kar --osc52 1F469 200D 1F4BB
```

This requires a terminal that supports and permits [OSC 52](https://jvns.ca/til/vim-osc52/) clipboard writes. Multiplexers like tmux may require configuration. Output must go directly to a terminal.

In `--osc52` mode, the status message reads `Sent to terminal clipboard:` because the terminal does not confirm whether the copy succeeded.

## Development

```sh
opam install --deps-only --with-test --with-dev-setup .
dune fmt
dune runtest
```
