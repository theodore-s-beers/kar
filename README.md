# gak

Grab a karacter: copy a Unicode character to the clipboard on macOS, Linux, or Windows.

## Development

Install OCaml and Dune (on macOS, `brew install ocaml dune`). In an initialized opam switch, install the Unicode data library, then build and run:

```sh
opam install uucp
dune build
dune runtest
dune exec gak -- U+1F600
```

The executable is built at `_build/default/bin/main.exe`.

## Usage

```sh
gak U+1F600  # 😀
gak 0x00E9  # é
gak 41      # A
```

Pass exactly one hexadecimal Unicode scalar value. The `U+` and `0x` prefixes are optional and case-insensitive. Bare numbers are also hexadecimal. Valid values range from `0000` to `10FFFF`, excluding surrogates (`D800`–`DFFF`).

`gak` copies the character without adding a newline and confirms success with its code point and Unicode name:

```text
Copied to clipboard:
U+1F600 GRINNING FACE
```

Names come from the Unicode data bundled with `uucp`; no network lookup is needed. Control characters use a Unicode control-name alias when available. Scalars without a name, including private-use and unassigned values, show `(no Unicode name)`. The character itself is never printed in the confirmation.

Invalid input or clipboard errors produce a nonzero exit status. Use `gak --help` for a usage reminder.

## Clipboard support

The backend is selected automatically:

| Platform        | Requirement                                                                                                                                                                         |
| --------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| macOS           | Built-in `pbcopy` on `PATH`                                                                                                                                                         |
| Linux / Wayland | [`wl-copy`](https://github.com/bugaevc/wl-clipboard) from `wl-clipboard`                                                                                                            |
| Linux / X11     | [`xclip`](https://github.com/astrand/xclip), or `xsel` as a fallback                                                                                                                |
| Windows         | Windows PowerShell (`powershell.exe`) with [`Set-Clipboard`](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.management/set-clipboard?view=powershell-5.1) |

On Linux, run in a graphical session with `WAYLAND_DISPLAY` or `DISPLAY` set. Wayland is preferred when `wl-copy` is installed; otherwise an available X11 backend is used if `DISPLAY` is set. For example, on Debian/Ubuntu, install `wl-clipboard` or `xclip` with your package manager. Use a UTF-8 locale with `xsel`. Backend failures return an error instead of silently trying another clipboard.

Windows input is explicitly decoded as UTF-8 by PowerShell. Clipboard consumers may not preserve control characters such as U+0000, even though they are valid scalars.

Tests cover scalar encoding, backend selection, and mocked clipboard commands. Actual desktop clipboard interoperability must be checked on each target platform.
