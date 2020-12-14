open Utils

type 'store t = {
  kv : (module KeyValue.KV with type value = string and type store = 'store);
  store : 'store;
  client : Oidc.Client.t;
  provider_uri : Uri.t;
  redirect_uri : Uri.t;
}

let make (type store)
    ~(kv : (module KeyValue.KV with type value = string and type store = store))
    ~(store : store) ~redirect_uri
    ~provider_uri ~client : store t =
  let (module KV) = kv in
  { kv; store; client; provider_uri; redirect_uri }

let discover ~get t =
  Internal.discover ~kv:t.kv ~store:t.store ~get
    ~provider_uri:t.provider_uri

let get_jwks ~get t =
  Internal.jwks ~kv:t.kv ~store:t.store ~get
    ~provider_uri:t.provider_uri

let get_token ~code ~get ~post t =
  let open Lwt_result.Infix in
  let open Lwt_result.Syntax in
  let* discovery = discover ~get t in
  let token_path = Uri.of_string discovery.token_endpoint |> Uri.path in
  let body =
    Uri.add_query_params' Uri.empty
      [
        ("grant_type", "authorization_code");
        ("scope", "openid");
        ("code", code);
        ("client_id", t.client.id);
        ("client_secret", t.client.secret |> ROpt.get_or ~default:"secret");
        ("redirect_uri", t.redirect_uri |> Uri.to_string);
      ]
    |> Uri.query |> Uri.encoded_of_query
  in
  let headers =
    [
      ("Content-Type", "application/x-www-form-urlencoded");
      ("Accept", "application/json");
    ]
  in
  let headers =
    match t.client.token_endpoint_auth_method with
    | "client_secret_basic" ->
        Oidc.Token.basic_auth ~client_id:t.client.id
          ~secret:(Option.value ~default:"" t.client.secret)
        :: headers
    | _ -> headers
  in
  Log.debug (fun m -> m "Getting token with client_id: %s" t.client.id);
  post ?headers:(Some headers) ~body token_path >|= Oidc.Token.of_string

let get_and_validate_id_token ?nonce ~code ~get ~post t =
  let open Lwt_result.Syntax in
  let* jwks = get_jwks ~get t in
  let* token_response = get_token ~code ~get ~post t in
  let* discovery = discover ~get t in
  ( match Jose.Jwt.of_string token_response.id_token with
  | Ok jwt -> (
      if jwt.header.alg = `None then
        Oidc.IDToken.validate ?nonce ~client:t.client ~issuer:discovery.issuer
          jwt
        |> Result.map (fun _ -> token_response)
      else
        match Oidc.Jwks.find_jwk ~jwt jwks with
        | Some jwk ->
            Log.debug (fun m -> m "Found JWK in JWKs");

            Oidc.IDToken.validate ?nonce ~client:t.client
              ~issuer:discovery.issuer ~jwk jwt
            |> Result.map (fun _ -> token_response)
        (* When there is only 1 key in the jwks we can try with that according to the OIDC spec *)
        | None when List.length jwks.keys = 1 ->
            Log.debug (fun m ->
                m
                  "No matching JWK found but only 1 JWK in JWKs, try \
                   validating with it");
            let jwk = List.hd jwks.keys in
            Oidc.IDToken.validate ?nonce ~client:t.client
              ~issuer:discovery.issuer ~jwk jwt
            |> Result.map (fun _ -> token_response)
        | None ->
            Log.debug (fun m -> m "No matching JWK found in JWKs");
            Error (`Msg "Could not find JWK") )
  | Error e -> Error e )
  |> Lwt.return

let get_auth_result ?nonce ~get ~post ~params ~state t =
  match (List.assoc_opt "state" params, List.assoc_opt "code" params) with
  | None, _ -> Error (`Msg "No state returned") |> Lwt.return
  | _, None -> Error (`Msg "No code returned") |> Lwt.return
  | Some returned_state, Some code ->
      if List.hd returned_state <> state then
        Error (`Msg "State doesn't match") |> Lwt.return
      else get_and_validate_id_token ?nonce ~code:(List.hd code) ~get ~post t

let get_auth_parameters ?scope ?claims ?nonce ~state t =
  Oidc.Parameters.make ?scope ?claims t.client ?nonce ~state
    ~redirect_uri:t.redirect_uri

let get_auth_uri ?scope ?claims ?nonce ~get ~state t =
  let query =
    get_auth_parameters ?scope ?claims ?nonce ~state t
    |> Oidc.Parameters.to_query
  in
  discover ~get t
  |> Lwt_result.map (fun (discovery : Oidc.Discover.t) ->
         discovery.authorization_endpoint ^ query)

let get_userinfo ~(get: ?headers:(string * string) list -> string -> (string, [> `Missing_sub | `Sub_missmatch ]) result Lwt.t) ~jwt ~token t =
  let open Lwt_result.Syntax in
  let* discovery = discover ~get t in
  let user_info_path = Uri.of_string discovery.userinfo_endpoint |> Uri.path in
  let userinfo =
      get
      ~headers:
        [ ("Authorization", "Bearer " ^ token); ("Accept", "application/json") ]
      user_info_path
  in
  Lwt_result.bind userinfo (fun userinfo ->
      Internal.validate_userinfo ~jwt userinfo |> Lwt.return)
