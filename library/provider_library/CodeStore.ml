let create_code () =
  Base64.encode_string ~alphabet:Base64.uri_safe_alphabet (Cstruct.to_string (Mirage_crypto_rng.generate 30))

let save_code ~email ~client_id code =
  let a =
    (code, `Assoc [ ("email", `String email); ("client_id", `String client_id) ])
    :: (Yojson.Safe.from_file "./tokens.json" |> Yojson.Safe.Util.to_assoc)
  in
  `Assoc a |> Yojson.Safe.to_file "./tokens.json" |> Lwt.return

let use_code code =
  Logs.info (fun m -> m "code: %s" code);
  let json = Yojson.Safe.from_file "./tokens.json" in
  let email, client_id =
    Yojson.Safe.Util.member code json |> fun a ->
    let email =
      Yojson.Safe.Util.member "email" a |> Yojson.Safe.Util.to_string
    in
    let client_id =
      Yojson.Safe.Util.member "client_id" a |> Yojson.Safe.Util.to_string
    in
    (email, client_id)
  in
  let assoc =
    Yojson.Safe.Util.to_assoc json |> List.filter (fun (c, _) -> code <> c)
  in
  let () = Yojson.Safe.to_file "./tokens.json" (`Assoc assoc) in
  Lwt.return (email, client_id)
