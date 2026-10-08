let fail message =
  prerr_endline ("kar: " ^ message);
  exit 1

let run ~osc52 inputs =
  let scalars =
    List.mapi
      (fun index input ->
        match Scalar.of_string input with
        | Ok scalar -> scalar
        | Error message ->
            fail
              (Printf.sprintf "code point %d (%S): %s" (index + 1) input message))
      inputs
  in
  let buffer = Buffer.create (List.length scalars) in
  List.iter (Buffer.add_utf_8_uchar buffer) scalars;
  let text = Buffer.contents buffer in
  let result = if osc52 then Osc52.copy text else Clipboard.copy text in
  match result with
  | Error message -> fail message
  | Ok () ->
      print_endline
        (if osc52 then "Sent to terminal clipboard:" else "Copied to clipboard:");
      List.iter
        (fun scalar ->
          Printf.printf "U+%04X %s\n" (Uchar.to_int scalar) (Scalar.name scalar))
        scalars

let () =
  match Cli.parse Sys.argv with
  | Ok { inputs = []; _ } -> fail "expected at least one Unicode scalar value"
  | Ok { osc52; inputs } -> run ~osc52 inputs
  | Error (`Help message) -> print_string message
  | Error (`Error message) ->
      prerr_string message;
      exit 1
