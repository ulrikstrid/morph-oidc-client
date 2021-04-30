open Helpers

let () = Mirage_crypto_rng_unix.initialize ()

let jwk = Jose.Jwk.make_priv_rsa (Mirage_crypto_pk.Rsa.generate ~bits:1024 ())

let aud = "1234"

let issuer = Uri.of_string "https://idp.example.com"

let valid_jwt =
  Jose.Jwt.sign jwk
    ~header:(Jose.Header.make_header jwk)
    ~payload:
      (`Assoc
        [
          ("iss", `String (Uri.to_string issuer));
          ("aud", `String aud);
          ("iat", `Int (Unix.time () |> int_of_float));
          ("exp", `Int ((Unix.time () |> int_of_float) + 1000));
          ("sub", `String "sub");
          ("nonce", `String "nonce");
        ])
  |> Result.get_ok

let client =
  Oidc.Client.make ~response_types:[] ~redirect_uris:[] ~grant_types:[]
    ~token_endpoint_auth_method:"" "1234"

let validate_valid () =
  let validated =
    Oidc.IDToken.validate ~nonce:"nonce" ~jwk ~client ~issuer valid_jwt
  in
  let get_aud (jwt : Jose.Jwt.t) =
    jwt.payload |> Yojson.Safe.Util.member "aud" |> Yojson.Safe.Util.to_string
  in
  check_result_string "aud" (Ok aud) (Result.map get_aud validated)

let tests = List.map make_test_case [ ("Valid JWT", validate_valid) ]

let suite, _ =
  Junit_alcotest.run_and_report ~package:"oidc" "Jwt" [ ("OIDC - JWT", tests) ]
