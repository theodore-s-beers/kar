let () =
  List.iter
    (fun (text, expected) ->
      if Osc52.sequence text <> "\x1b]52;c;" ^ expected ^ "\x07" then
        failwith "incorrect OSC 52 encoding")
    [
      ("A", "QQ==");
      ("\xc3\xa9", "w6k=");
      ("\xe2\x82\xac", "4oKs");
      ("\xf0\x9f\x98\x80", "8J+YgA==");
      ("\x00", "AA==");
      ("\n", "Cg==");
      ("\x1b", "Gw==");
      ("\xf4\x8f\xbf\xbf", "9I+/vw==");
    ]
