# gak

_Grab a karacter_: copy a Unicode character to the clipboard on Linux, macOS, or Windows.

## Build and run

In an initialized opam switch, install the Unicode data library, then build and run:

```sh
opam install uucp
dune build
dune exec gak -- U+1F600
```

The executable is built at `_build/default/bin/main.exe`.

## Usage

```sh
gak U+1F600  # 😀
gak 0x00E9   # é
gak 41       # A
```

Pass exactly one hexadecimal Unicode scalar value. The `U+` and `0x` prefixes are optional and case-insensitive. Bare numbers are also treated as hexadecimal. Valid values range from `0000` to `10FFFF`, excluding surrogates (`D800`–`DFFF`).

`gak` copies the character _without_ adding a newline and confirms success with the code point and its Unicode name:

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

## Development

```sh
dune fmt
dune runtest
```
