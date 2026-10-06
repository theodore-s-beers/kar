type backend = { program : string; arguments : string list }

let select ~windows ~getenv ~available =
  let has_display name =
    match getenv name with Some value -> value <> "" | None -> false
  in
  if windows then
    Ok { program = "powershell.exe";
         arguments =
           [ "-NoLogo"; "-NoProfile"; "-NonInteractive"; "-STA"; "-Command";
             "[Console]::InputEncoding = [System.Text.UTF8Encoding]::new($false); \
              Set-Clipboard -Value ([Console]::In.ReadToEnd()) -ErrorAction Stop" ] }
  else if available "pbcopy" then
    Ok { program = "pbcopy"; arguments = [] }
  else if has_display "WAYLAND_DISPLAY" && available "wl-copy" then
    Ok { program = "wl-copy"; arguments = [ "--type"; "text/plain;charset=utf-8" ] }
  else if has_display "DISPLAY" && available "xclip" then
    Ok { program = "xclip"; arguments = [ "-selection"; "clipboard"; "-in" ] }
  else if has_display "DISPLAY" && available "xsel" then
    Ok { program = "xsel"; arguments = [ "--clipboard"; "--input" ] }
  else
    Error "no clipboard backend available; on Linux, install wl-clipboard (Wayland) or xclip/xsel (X11) and run inside a graphical session; on macOS, ensure pbcopy is on PATH"

let available program =
  let path = Option.value (Sys.getenv_opt "PATH") ~default:"" in
  String.split_on_char ':' path
  |> List.exists (fun directory ->
         let file = Filename.concat (if directory = "" then "." else directory) program in
         try
           Unix.access file [ Unix.X_OK ];
           (Unix.stat file).Unix.st_kind = Unix.S_REG
         with Unix.Unix_error _ -> false)

let run backend character =
  (* pbcopy and xsel interpret text using the locale. Leave the Linux user's
     locale intact; macOS always supplies en_US.UTF-8. *)
  if backend.program = "pbcopy" then Unix.putenv "LC_ALL" "en_US.UTF-8";
  if not Sys.win32 then Sys.set_signal Sys.sigpipe Sys.Signal_ignore;
  try
    let arguments = Array.of_list (backend.program :: backend.arguments) in
    let channel = Unix.open_process_args_out backend.program arguments in
    set_binary_mode_out channel true;
    let write_error =
      try
        output_string channel character;
        flush channel;
        None
      with Sys_error message -> Some message
    in
    let status = Unix.close_process_out channel in
    match status, write_error with
    | Unix.WEXITED 0, None -> Ok ()
    | Unix.WEXITED 0, Some message -> Error message
    | Unix.WEXITED code, _ ->
        Error (Printf.sprintf "%s exited with status %d" backend.program code)
    | (Unix.WSIGNALED signal | Unix.WSTOPPED signal), _ ->
        Error (Printf.sprintf "%s interrupted by signal %d" backend.program signal)
  with
  | Unix.Unix_error (error, _, _) ->
      Error (backend.program ^ ": " ^ Unix.error_message error)
  | Sys_error message -> Error (backend.program ^ ": " ^ message)

let copy character =
  match select ~windows:Sys.win32 ~getenv:Sys.getenv_opt ~available with
  | Error _ as error -> error
  | Ok backend -> run backend character
