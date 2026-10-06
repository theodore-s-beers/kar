let sequence text =
  let alphabet =
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
  in
  let length = String.length text in
  let encoded = Bytes.make ((length + 2) / 3 * 4) '=' in
  let byte index = if index < length then Char.code text.[index] else 0 in
  for block = 0 to ((length + 2) / 3) - 1 do
    let source = block * 3 and target = block * 4 in
    let a = byte source and b = byte (source + 1) and c = byte (source + 2) in
    Bytes.set encoded target alphabet.[a lsr 2];
    Bytes.set encoded (target + 1) alphabet.[((a land 3) lsl 4) lor (b lsr 4)];
    if source + 1 < length then
      Bytes.set encoded (target + 2)
        alphabet.[((b land 15) lsl 2) lor (c lsr 6)];
    if source + 2 < length then
      Bytes.set encoded (target + 3) alphabet.[c land 63]
  done;
  "\x1b]52;c;" ^ Bytes.to_string encoded ^ "\x07"

let copy character =
  if not (Unix.isatty Unix.stdout) then
    Error "--osc52 requires standard output to be a terminal"
  else
    try
      output_string stdout (sequence character);
      flush stdout;
      Ok ()
    with Sys_error message -> Error ("could not write to terminal: " ^ message)
