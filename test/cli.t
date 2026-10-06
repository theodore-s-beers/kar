Use a mock clipboard command to check the exact bytes without touching the system clipboard.

  $ cat > pbcopy <<'EOF'
  > #!/bin/sh
  > cat > clipboard
  > exit "${CLIPBOARD_EXIT:-0}"
  > EOF
  $ chmod +x pbcopy
  $ export PATH="$PWD:$PATH"
  $ ../bin/main.exe U+1F600
  $ printf '\360\237\230\200' > expected
  $ cmp expected clipboard
  $ ../bin/main.exe 41
  $ printf A > expected
  $ cmp expected clipboard

Invalid input must fail before invoking the clipboard command.

  $ rm clipboard
  $ ../bin/main.exe D800
  gak: expected a Unicode scalar (U+0000–U+10FFFF, excluding surrogates)
  [1]
  $ test ! -e clipboard
  $ ../bin/main.exe
  Usage: gak <hex-scalar>
  Example: gak U+1F600
  [1]
  $ ../bin/main.exe 41 42
  Usage: gak <hex-scalar>
  Example: gak U+1F600
  [1]
  $ ../bin/main.exe --help
  Usage: gak <hex-scalar>
  Example: gak U+1F600

Clipboard failures must propagate to the caller.

  $ CLIPBOARD_EXIT=7 ../bin/main.exe 41
  gak: pbcopy exited with status 7
  [1]
  $ PATH=/nonexistent ../bin/main.exe 41
  gak: no clipboard backend available; on Linux, install wl-clipboard (Wayland) or xclip/xsel (X11) and run inside a graphical session; on macOS, ensure pbcopy is on PATH
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
  $ printf '\360\237\230\200' > expected
  $ cmp expected clipboard
  $ cat arguments
  --type
  text/plain;charset=utf-8
  $ PATH="$PWD/backends" WAYLAND_DISPLAY= DISPLAY=:0 ../bin/main.exe U+1F600
  $ cmp expected clipboard
  $ cat arguments
  -selection
  clipboard
  -in
  $ rm backends/xclip
  $ PATH="$PWD/backends" WAYLAND_DISPLAY= DISPLAY=:0 ../bin/main.exe U+1F600
  $ cmp expected clipboard
  $ cat arguments
  --clipboard
  --input

A failed Wayland command must not silently switch to X11.

  $ PATH="$PWD/backends" WAYLAND_DISPLAY=wayland-0 DISPLAY=:0 CLIPBOARD_EXIT=7 ../bin/main.exe 41
  gak: wl-copy exited with status 7
  [1]
  $ cat arguments
  --type
  text/plain;charset=utf-8
