let of_string input =
  let length = String.length input in
  let start =
    if length >= 2 then
      match String.sub input 0 2 with "U+" | "u+" | "0x" | "0X" -> 2 | _ -> 0
    else 0
  in
  let rec parse index value =
    if index = length then
      if Uchar.is_valid value then Ok (Uchar.of_int value)
      else
        Error
          "expected a Unicode scalar (U+0000–U+10FFFF, excluding surrogates)"
    else
      let digit =
        match input.[index] with
        | '0' .. '9' as c -> Char.code c - Char.code '0'
        | 'a' .. 'f' as c -> Char.code c - Char.code 'a' + 10
        | 'A' .. 'F' as c -> Char.code c - Char.code 'A' + 10
        | _ -> -1
      in
      if digit < 0 then
        Error "expected hexadecimal digits, optionally prefixed by U+ or 0x"
      else if value > (0x10ffff - digit) / 16 then
        Error "Unicode scalar exceeds U+10FFFF"
      else parse (index + 1) ((value * 16) + digit)
  in
  if start = length then Error "expected a Unicode scalar value"
  else parse start 0

let to_utf8 scalar =
  let buffer = Buffer.create 4 in
  Buffer.add_utf_8_uchar buffer scalar;
  Buffer.contents buffer
