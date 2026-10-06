(lang dune 3.0)
(name gak)
(cram enable)
(generate_opam_files true)

(package
 (name gak)
 (depends
  (ocaml (>= 4.14))
  dune
  (uucp (>= 18.0.0))
  (ocamlformat (and :with-dev-setup (= 0.29.0)))
  (ocaml-lsp-server :with-dev-setup))
 (synopsis "Grab a karacter: copy a Unicode scalar to the clipboard"))
