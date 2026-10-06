let check ?(windows = false) tools environment expected =
  let result =
    Clipboard.select ~windows
      ~getenv:(fun name -> List.assoc_opt name environment)
      ~available:(fun name -> List.mem name tools)
  in
  match result, expected with
  | Error _, None -> ()
  | Ok backend, Some (program, arguments)
    when backend.program = program && backend.arguments = arguments -> ()
  | _ -> failwith "incorrect clipboard backend selection"

let () =
  let wayland = [ "WAYLAND_DISPLAY", "wayland-0"; "DISPLAY", ":0" ] in
  let x11 = [ "DISPLAY", ":0" ] in
  let xclip = Some ("xclip", [ "-selection"; "clipboard"; "-in" ]) in
  check [ "pbcopy" ] [] (Some ("pbcopy", []));
  check [ "wl-copy"; "xclip" ] wayland
    (Some ("wl-copy", [ "--type"; "text/plain;charset=utf-8" ]));
  check [ "xclip"; "xsel" ] wayland xclip;
  check [ "wl-copy"; "xclip" ] x11 xclip;
  check [ "xsel" ] x11 (Some ("xsel", [ "--clipboard"; "--input" ]));
  check [ "wl-copy"; "xclip"; "xsel" ] [] None;
  check [ "wl-copy"; "xclip" ] [ "WAYLAND_DISPLAY", ""; "DISPLAY", "" ] None;
  check [] wayland None;
  match Clipboard.select ~windows:true ~getenv:(fun _ -> None) ~available:(fun _ -> false) with
  | Ok backend when backend.program = "powershell.exe" ->
      if not (List.mem "-STA" backend.arguments) then failwith "PowerShell requires STA";
      if not (List.mem "-NonInteractive" backend.arguments) then failwith "PowerShell must not prompt"
  | _ -> failwith "Windows must use PowerShell"
