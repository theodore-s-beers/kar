let fail message =
  prerr_endline ("kar: " ^ message);
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
  match Cli.parse Sys.argv with
  | Ok { osc52; inputs = [ input ] } -> run ~osc52 input
  | Ok _ -> fail "expected exactly one Unicode scalar value"
  | Error (`Help message) -> print_string message
  | Error (`Error message) ->
      prerr_string message;
      exit 1
