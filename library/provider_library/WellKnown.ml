let metadata =
  let issuer = Uri.of_string "http://localhost:4040" in
  Oidc.Discover.
    {
      issuer;
      authorization_endpoint = Uri.with_path issuer "auth";
      token_endpoint = Uri.with_path issuer "token";
      jwks_uri = Uri.with_path issuer ".well-known/jwks";
      userinfo_endpoint = None;
      registration_endpoint = None;
      response_types_supported = [ "code"; "id_token" ];
      subject_types_supported = [ "public" ];
      id_token_signing_alg_values_supported = [ "RS256" ];
    }

let handler _ =
  Morph.Response.json (Oidc.Discover.to_json metadata |> Yojson.Safe.to_string)
  |> Lwt.return
