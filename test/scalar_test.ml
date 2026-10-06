let () =
  List.iter
    (fun (input, expected) ->
      match Scalar.of_string input with
      | Ok scalar when Scalar.to_utf8 scalar = expected -> ()
      | _ -> failwith ("incorrect encoding for " ^ input))
    [
      ("0000", "\x00");
      ("U+0041", "A");
      ("7f", "\x7f");
      ("80", "\xc2\x80");
      ("0x00e9", "\xc3\xa9");
      ("7ff", "\xdf\xbf");
      ("800", "\xe0\xa0\x80");
      ("u+20AC", "\xe2\x82\xac");
      ("D7FF", "\xed\x9f\xbf");
      ("E000", "\xee\x80\x80");
      ("FFFF", "\xef\xbf\xbf");
      ("10000", "\xf0\x90\x80\x80");
      ("0X1F600", "\xf0\x9f\x98\x80");
      ("10FFFF", "\xf4\x8f\xbf\xbf");
    ];
  List.iter
    (fun input ->
      match Scalar.of_string input with
      | Error _ -> ()
      | Ok _ -> failwith ("unexpectedly accepted " ^ input))
    [
      "";
      "U+";
      "0x";
      "D800";
      "DFFF";
      "110000";
      "FFFFFFFFFFFFFFFFFFFFFFFF";
      "-1";
      "+41";
      " 41";
      "41 ";
      "4_1";
      "xyz";
      "U+0x41";
      "😀";
    ]

let () =
  List.iter
    (fun (code, expected) ->
      let actual = Scalar.name (Uchar.of_int code) in
      if actual <> expected then
        failwith (Printf.sprintf "unexpected name for U+%04X: %s" code actual))
    [
      (0x0041, "LATIN CAPITAL LETTER A");
      (0x1f600, "GRINNING FACE");
      (0x000a, "END OF LINE");
      (0x0000, "NULL");
      (0x200b, "ZERO WIDTH SPACE");
      (0x4e00, "CJK UNIFIED IDEOGRAPH-4E00");
      (0xac00, "HANGUL SYLLABLE GA");
      (0xe000, "(no Unicode name)");
      (0x0378, "(no Unicode name)");
      (0xffff, "(no Unicode name)");
    ]
