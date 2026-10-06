let usage = "Usage: gak <hex-scalar>\nExample: gak U+1F600"

let fail message =
  prerr_endline ("gak: " ^ message);
  exit 1

let () =
  match Array.to_list Sys.argv with
  | [ _; ("--help" | "-h") ] -> print_endline usage
  | [ _; input ] -> (
      match Scalar.of_string input with
      | Ok scalar -> (
          let character = Scalar.to_utf8 scalar in
          match Clipboard.copy character with
          | Ok () ->
              Printf.printf "Copied to clipboard:\nU+%04X %s\n"
                (Uchar.to_int scalar) (Scalar.name scalar)
          | Error message -> fail message)
      | Error message -> fail message)
  | _ ->
      prerr_endline usage;
      exit 1
