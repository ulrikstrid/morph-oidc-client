type t = {
  name : string;
  category : string;
  description : string;
  info : string;
  provider_uri : string;
}

(*
let _datas =
  [
    {
      name = "rp-response_type-code";
      category = "Response Type and Response Mode";
      description =
        "Make an authentication request using the Authorization Code Flow.";
      info = "An authentication response containing an authorization code.";
    };
    {
      name = "rp-scope-userinfo-claims";
      category = "scope Request Parameter";
      description = "Request claims using scope values.";
      info =
        "A UserInfo Response containing the requested claims. If no access \
         token is issued (when using Implicit Flow with \
         response_type='id_token') the ID Token contains the requested claims.";
    };
    {
      name = "rp-nonce-invalid";
      category = "nonce Request Parameter";
      description =
        "Pass a 'nonce' value in the Authentication Request. Verify the \
         'nonce' value returned in the ID Token.";
      info =
        "Identify that the 'nonce' value in the ID Token is invalid and reject \
         the ID Token.";
    };
    {
      name = "rp-token_endpoint-client_secret_basic";
      category = "Client Authentication";
      description =
        "Use the 'client_secret_basic' method to authenticate at the \
         Authorization Server when using the token endpoint.";
      info = "A Token Response, containing an ID token.";
    };
    {
      name = "rp-id_token-kid-absent-single-jwks";
      category = "ID Token";
      description =
        "Request an ID token and verify its signature using a single matching \
         key provided by the Issuer.";
      info =
        "Use the single matching key out of the Issuer's published set to \
         verify the ID Tokens signature and accept the ID Token after doing ID \
         Token validation.";
    };
    {
      name = "rp-id_token-iat";
      category = "ID Token";
      description = "\tRequest an ID token and verify its 'iat' value.";
      info =
        "Identify the missing 'iat' value and reject the ID Token after doing \
         ID Token validation.";
    };
    {
      name = "rp-id_token-aud";
      category = "ID Token";
      description =
        "Request an ID token and compare its aud value to the Relying Party's \
         'client_id'.";
      info =
        "Identify that the 'aud' value is missing or doesn't match the \
         'client_id' and reject the ID Token after doing ID Token validation.";
    };
    {
      name = "rp-id_token-kid-absent-multiple-jwks";
      category = "ID Token";
      description =
        "Request an ID token and verify its signature using the keys provided \
         by the Issuer.";
      info =
        "Identify that the 'kid' value is missing from the JOSE header and \
         that the Issuer publishes multiple keys in its JWK Set document \
         (referenced by 'jwks_uri'). The RP can do one of two things; reject \
         the ID Token since it can not by using the kid determined which key \
         to use to verify the signature. Or it can just test all possible keys \
         and hit upon one that works, which it will in this case.";
    };
    {
      name = "rp-id_token-sig-none";
      category = "ID Token";
      description =
        "Use Code Flow and retrieve an unsigned ID Token. This test is only \
         applicable when response_type='code'";
      info = "Accept the ID Token after doing ID Token validation.";
    };
    {
      name = "rp-id_token-sig-rs256";
      category = "ID Token";
      description =
        "Request an signed ID Token. Verify the signature on the ID Token \
         using the keys published by the Issuer.";
      info = "Accept the ID Token after doing ID Token validation.";
    };
    {
      name = "rp-id_token-sub";
      category = "ID Token";
      description = "Request an ID token and verify it contains a sub value.";
      info = "Identify the missing 'sub' value and reject the ID Token.";
    };
    {
      name = "rp-id_token-bad-sig-rs256";
      category = "ID Token";
      description =
        "Request an ID token and verify its signature using the keys provided \
         by the Issuer.";
      info =
        "Identify the invalid signature and reject the ID Token after doing ID \
         Token validation.";
    };
    {
      name = "rp-id_token-issuer-mismatch";
      category = "ID Token";
      description = "\tRequest an ID token and verify its 'iss' value.";
      info =
        "Identify the incorrect 'iss' value and reject the ID Token after \
         doing ID Token validation.";
    };
    {
      name = "rp-userinfo-bad-sub-claim";
      category = "UserInfo Endpoint";
      description =
        "\tMake a UserInfo Request and verify the 'sub' value of the UserInfo \
         Response by comparing it with the ID Token's 'sub' value.";
      info =
        "Identify the invalid 'sub' value and reject the UserInfo Response.";
    };
    {
      name = "rp-userinfo-bearer-header";
      category = "UserInfo Endpoint";
      description =
        "Pass the access token using the \"Bearer\" authentication scheme \
         while doing the UserInfo Request.";
      info = "A UserInfo Response.";
    };
  ]
*)

let redirect_uri =
  try Sys.getenv "OIDC_REDIRECT_URI"
  with _ -> failwith "Must set OIDC_REDIRECT_URI"

let form_post_certification_client_data =
  let provider_uri =
    try Sys.getenv "FORM_POST_PROVIDER_HOST"
    with _ -> failwith "Must set FORM_POST_PROVIDER_HOST"
  in
  {
    name = "form_post_morph_oidc_client";
    category = "new";
    description = "Form Post";
    info = "the new certification";
    provider_uri;
  }

let basic_certification_client_data =
  let provider_uri =
    try Sys.getenv "BASIC_PROVIDER_HOST"
    with _ -> failwith "Must set BASIC_PROVIDER_HOST"
  in
  {
    name = "basic_morph_oidc_client";
    category = "new";
    description = "Form Post";
    info = "the new certification";
    provider_uri;
  }

let to_client_meta (data : t) : Oidc.Client.meta =
  Oidc.Client.make_meta ~client_name:data.name
    ~redirect_uris:
      (List.map Uri.of_string [ redirect_uri; data.provider_uri ^ "/callback" ])
    ~contacts:[ "ulrik.strid@outlook.com" ]
    ~response_types:[ "code" ] ~grant_types:[ "authorization_code" ]
    ~token_endpoint_auth_method:"client_secret_basic" ()

let datas : t list =
  [ form_post_certification_client_data; basic_certification_client_data ]

let get_clients ~kv ~make_store =
  let open Lwt_result.Infix in
  List.map
    (fun data ->
      let store = make_store () in
      let meta = to_client_meta data in
      let uri = Uri.of_string data.provider_uri in
      let () =
        Logs.info (fun m ->
            m "Creating client for provider with uri: %s" data.provider_uri)
      in
      OidcClient.Dynamic.make ~kv ~store ~provider_uri:uri meta
      >|= fun client -> (data, client))
    datas
  |> Lwt.all
