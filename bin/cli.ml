type t = { osc52 : bool; inputs : string list }

let parse argv =
  let osc52 = ref false in
  let inputs = ref [] in
  let add_input input = inputs := input :: !inputs in
  let options =
    [
      ( "--osc52",
        Arg.Set osc52,
        " Send clipboard request to terminal (e.g. over SSH)" );
      ( "-h",
        Arg.Unit (fun () -> raise (Arg.Help "")),
        " Display this list of options" );
      ("--", Arg.Rest add_input, " Treat remaining arguments as code points");
    ]
  in
  let usage = "Usage: kar [--osc52] <hex-scalar>...\nExample: kar U+1F600" in
  try
    Arg.parse_argv ~current:(ref 0) argv options add_input usage;
    Ok { osc52 = !osc52; inputs = List.rev !inputs }
  with
  | Arg.Help _ -> Error (`Help (Arg.usage_string options usage))
  | Arg.Bad message -> Error (`Error message)
