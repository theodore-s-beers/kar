# kar

kar(acter): copy a Unicode character to the clipboard on Linux, macOS, or Windows.

## Build and run

In an initialized opam switch, install the project dependencies, then build and run:

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
kar U+1F600  # 😀
kar 0x00E9   # é
kar 41       # A
```

Pass exactly one hexadecimal Unicode scalar value. The `U+` and `0x` prefixes are optional and case-insensitive. Bare numbers are also treated as hexadecimal. Valid values range from `0000` to `10FFFF`, excluding surrogates (`D800`–`DFFF`).

`kar` copies the character _without_ adding a newline and confirms success with the code point and its Unicode name:

```text
Copied to clipboard:
U+1F600 GRINNING FACE
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
```

This requires a terminal that supports and permits [OSC 52](https://jvns.ca/til/vim-osc52/) clipboard writes. Multiplexers like tmux may require configuration. Output must go directly to a terminal. The status message reads `Sent to terminal clipboard:` because the terminal does not confirm whether the copy succeeded.

## Development

```sh
opam install --deps-only --with-test --with-dev-setup .
dune fmt
dune runtest
```
