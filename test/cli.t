Use a mock clipboard command to check the exact bytes without touching the system clipboard.

  $ cat > pbcopy <<'EOF'
  > #!/bin/sh
  > cat > clipboard
  > exit "${CLIPBOARD_EXIT:-0}"
  > EOF
  $ chmod +x pbcopy
  $ export PATH="$PWD:$PATH"
  $ ../bin/main.exe U+1F600
  Copied to clipboard:
  U+1F600 GRINNING FACE
  $ printf '\360\237\230\200' > expected
  $ cmp expected clipboard
  $ ../bin/main.exe 41
  Copied to clipboard:
  U+0041 LATIN CAPITAL LETTER A
  $ printf A > expected
  $ cmp expected clipboard

Control characters are identified without printing the control character itself.

  $ ../bin/main.exe 0A
  Copied to clipboard:
  U+000A END OF LINE
  $ printf '\n' > expected
  $ cmp expected clipboard

Unnamed scalars still have a two-line confirmation.

  $ ../bin/main.exe E000
  Copied to clipboard:
  U+E000 (no Unicode name)
  $ printf '\356\200\200' > expected
  $ cmp expected clipboard

Invalid input must fail before invoking the clipboard command.

  $ rm clipboard
  $ ../bin/main.exe D800
  kar: expected a Unicode scalar (U+0000–U+10FFFF, excluding surrogates)
  [1]
  $ test ! -e clipboard
  $ ../bin/main.exe
  kar: expected exactly one Unicode scalar value
  [1]
  $ ../bin/main.exe 41 42
  kar: expected exactly one Unicode scalar value
  [1]
  $ ../bin/main.exe --help
  Usage: kar [--osc52] <hex-scalar>
  Example: kar U+1F600
    --osc52  Send clipboard request to terminal (e.g. over SSH)
    -h  Display this list of options
    --  Treat remaining arguments as code points
    -help  Display this list of options
    --help  Display this list of options

Clipboard failures must propagate to the caller.

  $ CLIPBOARD_EXIT=7 ../bin/main.exe 41
  kar: pbcopy exited with status 7
  [1]
  $ PATH=/nonexistent ../bin/main.exe 41
  kar: no clipboard backend available; on Linux, install wl-clipboard (Wayland) or xclip/xsel (X11) and run inside a graphical session; on macOS, ensure pbcopy is on PATH
  [1]

Use an isolated PATH to exercise Linux backends even on macOS.

  $ mkdir backends
  $ cat > backends/wl-copy <<'EOF'
  > #!/bin/sh
  > printf '%s\n' "$@" > arguments
  > /bin/cat > clipboard
  > exit "${CLIPBOARD_EXIT:-0}"
  > EOF
  $ chmod +x backends/wl-copy
  $ cp backends/wl-copy backends/xclip
  $ cp backends/wl-copy backends/xsel
  $ PATH="$PWD/backends" WAYLAND_DISPLAY=wayland-0 DISPLAY=:0 ../bin/main.exe U+1F600
  Copied to clipboard:
  U+1F600 GRINNING FACE
  $ printf '\360\237\230\200' > expected
  $ cmp expected clipboard
  $ cat arguments
  --type
  text/plain;charset=utf-8
  $ PATH="$PWD/backends" WAYLAND_DISPLAY= DISPLAY=:0 ../bin/main.exe U+1F600
  Copied to clipboard:
  U+1F600 GRINNING FACE
  $ cmp expected clipboard
  $ cat arguments
  -selection
  clipboard
  -in
  $ rm backends/xclip
  $ PATH="$PWD/backends" WAYLAND_DISPLAY= DISPLAY=:0 ../bin/main.exe U+1F600
  Copied to clipboard:
  U+1F600 GRINNING FACE
  $ cmp expected clipboard
  $ cat arguments
  --clipboard
  --input

A failed Wayland command must not silently switch to X11.

  $ PATH="$PWD/backends" WAYLAND_DISPLAY=wayland-0 DISPLAY=:0 CLIPBOARD_EXIT=7 ../bin/main.exe 41
  kar: wl-copy exited with status 7
  [1]
  $ cat arguments
  --type
  text/plain;charset=utf-8

OSC 52 requires terminal output and never invokes a desktop clipboard backend.

  $ rm clipboard
  $ ../bin/main.exe --osc52 41 > output
  kar: --osc52 requires standard output to be a terminal
  [1]
  $ test ! -s output
  $ test ! -e clipboard
  $ ../bin/main.exe 41 --osc52 > output
  kar: --osc52 requires standard output to be a terminal
  [1]
  $ test ! -s output
  $ ../bin/main.exe --osc52 D800 > output
  kar: expected a Unicode scalar (U+0000–U+10FFFF, excluding surrogates)
  [1]
  $ test ! -s output
  $ ../bin/main.exe --osc52
  kar: expected exactly one Unicode scalar value
  [1]

Help works alongside options and positional arguments without touching the clipboard.

  $ ../bin/main.exe --help > expected-help
  $ for flag in --help -h -help; do
  >   ../bin/main.exe --osc52 "$flag" > actual-help || exit 1
  >   cmp expected-help actual-help || exit 1
  >   ../bin/main.exe "$flag" --osc52 > actual-help || exit 1
  >   cmp expected-help actual-help || exit 1
  >   ../bin/main.exe "$flag" 41 > actual-help || exit 1
  >   cmp expected-help actual-help || exit 1
  >   ../bin/main.exe 41 "$flag" > actual-help || exit 1
  >   cmp expected-help actual-help || exit 1
  >   ../bin/main.exe --osc52 41 "$flag" > actual-help || exit 1
  >   cmp expected-help actual-help || exit 1
  > done
  $ test ! -e clipboard

Unknown options fail as options, including after a positional argument.

  $ ../bin/main.exe --bogus > output 2> error
  [1]
  $ head -n 1 error
  ../bin/main.exe: unknown option '--bogus'.
  $ test ! -s output
  $ ../bin/main.exe 41 --bogus > output 2> error
  [1]
  $ head -n 1 error
  ../bin/main.exe: unknown option '--bogus'.
  $ test ! -s output
  $ test ! -e clipboard

Repeated boolean flags are harmless; a scalar is still required.

  $ ../bin/main.exe --osc52 41 --osc52 > output
  kar: --osc52 requires standard output to be a terminal
  [1]
  $ test ! -s output
  $ ../bin/main.exe --osc52 --osc52
  kar: expected exactly one Unicode scalar value
  [1]
  $ ../bin/main.exe 41 --osc52 42
  kar: expected exactly one Unicode scalar value
  [1]
  $ test ! -e clipboard

The option terminator makes every subsequent argument positional.

  $ ../bin/main.exe -- --help
  kar: expected hexadecimal digits, optionally prefixed by U+ or 0x
  [1]
  $ test ! -e clipboard
  $ ../bin/main.exe -- 41
  Copied to clipboard:
  U+0041 LATIN CAPITAL LETTER A
  $ printf A > expected
  $ cmp expected clipboard
