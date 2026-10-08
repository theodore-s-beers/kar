Use a mock clipboard command to check the exact bytes without touching the system clipboard.

  $ cat > pbcopy <<'EOF'
  > #!/bin/sh
  > echo copy >> invocations
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
  kar: code point 1 ("D800"): expected a Unicode scalar (U+0000–U+10FFFF, excluding surrogates)
  [1]
  $ test ! -e clipboard
  $ ../bin/main.exe
  kar: expected at least one Unicode scalar value
  [1]
  $ ../bin/main.exe --help
  Usage: kar [--osc52] <hex-scalar>...
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
  kar: code point 1 ("D800"): expected a Unicode scalar (U+0000–U+10FFFF, excluding surrogates)
  [1]
  $ test ! -s output
  $ ../bin/main.exe --osc52
  kar: expected at least one Unicode scalar value
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
  >   ../bin/main.exe --osc52 41 42 "$flag" > actual-help || exit 1
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
  kar: expected at least one Unicode scalar value
  [1]
  $ ../bin/main.exe 41 --osc52 42
  kar: --osc52 requires standard output to be a terminal
  [1]
  $ test ! -e clipboard

The option terminator makes every subsequent argument positional.

  $ ../bin/main.exe -- --help
  kar: code point 1 ("--help"): expected hexadecimal digits, optionally prefixed by U+ or 0x
  [1]
  $ test ! -e clipboard
  $ ../bin/main.exe -- 41
  Copied to clipboard:
  U+0041 LATIN CAPITAL LETTER A
  $ printf A > expected
  $ cmp expected clipboard

Sequences preserve order and duplicates and use one clipboard operation.

  $ rm invocations
  $ ../bin/main.exe 48 65 6C 6C 6F
  Copied to clipboard:
  U+0048 LATIN CAPITAL LETTER H
  U+0065 LATIN SMALL LETTER E
  U+006C LATIN SMALL LETTER L
  U+006C LATIN SMALL LETTER L
  U+006F LATIN SMALL LETTER O
  $ printf Hello > expected
  $ cmp expected clipboard
  $ cat invocations
  copy

Combining marks are not normalized, and prefixes can be mixed.

  $ ../bin/main.exe U+0065 0x0301
  Copied to clipboard:
  U+0065 LATIN SMALL LETTER E
  U+0301 COMBINING ACUTE ACCENT
  $ printf 'e\314\201' > expected
  $ cmp expected clipboard

Emoji sequences retain their joiners and supplementary code points.

  $ ../bin/main.exe 1F469 200D 1F4BB
  Copied to clipboard:
  U+1F469 WOMAN
  U+200D ZERO WIDTH JOINER
  U+1F4BB PERSONAL COMPUTER
  $ printf '\360\237\221\251\342\200\215\360\237\222\273' > expected
  $ cmp expected clipboard

Control characters and NUL are preserved within a sequence.

  $ ../bin/main.exe -- 41 0 0A 42
  Copied to clipboard:
  U+0041 LATIN CAPITAL LETTER A
  U+0000 NULL
  U+000A END OF LINE
  U+0042 LATIN CAPITAL LETTER B
  $ printf 'A\000\nB' > expected
  $ cmp expected clipboard

Unseparated digits remain a single scalar.

  $ ../bin/main.exe 4142
  Copied to clipboard:
  U+4142 CJK UNIFIED IDEOGRAPH-4142
  $ printf '\344\205\202' > expected
  $ cmp expected clipboard

Invalid arguments at any position leave the existing clipboard untouched.

  $ cp clipboard expected
  $ rm invocations
  $ ../bin/main.exe D800 41 > output
  kar: code point 1 ("D800"): expected a Unicode scalar (U+0000–U+10FFFF, excluding surrogates)
  [1]
  $ test ! -s output
  $ ../bin/main.exe 41 nope 42 > output
  kar: code point 2 ("nope"): expected hexadecimal digits, optionally prefixed by U+ or 0x
  [1]
  $ test ! -s output
  $ ../bin/main.exe 41 42 110000 > output
  kar: code point 3 ("110000"): Unicode scalar exceeds U+10FFFF
  [1]
  $ test ! -s output
  $ ../bin/main.exe 41 '' > output
  kar: code point 2 (""): expected a Unicode scalar value
  [1]
  $ test ! -s output
  $ ../bin/main.exe '48 65' > output
  kar: code point 1 ("48 65"): expected hexadecimal digits, optionally prefixed by U+ or 0x
  [1]
  $ test ! -s output
  $ ../bin/main.exe 41 --osc52 D800 > output
  kar: code point 2 ("D800"): expected a Unicode scalar (U+0000–U+10FFFF, excluding surrogates)
  [1]
  $ test ! -s output
  $ test ! -e invocations
  $ cmp expected clipboard
