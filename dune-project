(lang dune 3.0)
(name kar)
(cram enable)
(generate_opam_files true)
(maintainers "Theo Beers <theodore@boot.dev>")
(authors "Theo Beers")
(license MIT)
(source
 (github theodore-s-beers/kar))

(package
 (name kar)
 (depends
  (ocaml (>= 4.14))
  dune
  (uucp (>= 18.0.0))
  (ocamlformat (and :with-dev-setup (= 0.29.0)))
  (ocaml-lsp-server :with-dev-setup))
 (synopsis "Grab a karacter: copy a Unicode scalar to the clipboard"))
