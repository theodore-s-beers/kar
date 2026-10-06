let usage =
  "Usage: gak [--osc52] <hex-scalar>\n\
   Example: gak U+1F600\n\
  \  --osc52  Send a clipboard request to the terminal (e.g. over SSH)"

let fail message =
  prerr_endline ("gak: " ^ message);
  exit 1

let run ~osc52 input =
  match Scalar.of_string input with
  | Error message -> fail message
  | Ok scalar -> (
      let character = Scalar.to_utf8 scalar in
      let result =
        if osc52 then Osc52.copy character else Clipboard.copy character
      in
      match result with
      | Error message -> fail message
      | Ok () ->
          let status =
            if osc52 then "Sent to terminal clipboard:"
            else "Copied to clipboard:"
          in
          Printf.printf "%s\nU+%04X %s\n" status (Uchar.to_int scalar)
            (Scalar.name scalar))

let () =
  match Array.to_list Sys.argv with
  | [ _; ("--help" | "-h") ] | [ _; "--osc52"; ("--help" | "-h") ] ->
      print_endline usage
  | [ _; input ] when input <> "--osc52" -> run ~osc52:false input
  | [ _; "--osc52"; input ] | [ _; input; "--osc52" ] -> run ~osc52:true input
  | _ ->
      prerr_endline usage;
      exit 1
