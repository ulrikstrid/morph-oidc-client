open Utils

let src =
  Logs.Src.create "oidc.id_token" ~doc:"logs OIDC events in the IDToken module"

module Log = (val Logs.src_log src : Logs.LOG)

type validation_error =
  [ `Expired
  | `Iat_in_future
  | `Invalid_nonce
  | `Invalid_signature
  | `Invalid_sub_length
  | `Missing_aud
  | `Missing_exp
  | `Missing_iat
  | `Missing_iss
  | `Missing_nonce
  | `Missing_sub
  | `Msg of string
  | `No_jwk_provided
  | `Unexpected_nonce
  | `Unsafe
  | `Wrong_aud_value of string
  | `Wrong_iss_value of string ]

let ( >>= ) = RResult.( >>= )

let get_string_member member payload =
  Yojson.Safe.Util.member member payload |> Yojson.Safe.Util.to_string_option

let get_int_member member payload =
  Yojson.Safe.Util.member member payload |> Yojson.Safe.Util.to_int_option

let validate_sub (jwt : Jose.Jwt.t) =
  match get_string_member "sub" jwt.payload with
  | Some sub when String.length sub < 257 ->
      Log.debug (fun m -> m "sub is valid");
      Ok jwt
  | Some _sub ->
      Log.debug (fun m -> m "sub has invalid length");
      Error `Invalid_sub_length
  | None ->
      Log.debug (fun m -> m "sub is missing");
      Error `Missing_sub

let validate_exp (jwt : Jose.Jwt.t) =
  let module Json = Yojson.Safe.Util in
  match get_int_member "exp" jwt.payload with
  | Some exp when exp > int_of_float (Unix.time ()) ->
      Log.debug (fun m -> m "exp is valid");
      Ok jwt
  | Some _exp ->
      Log.debug (fun m -> m "exp is the past");
      Error `Expired
  | None ->
      Log.debug (fun m -> m "exp is missing");
      Error `Missing_exp

let validate_iat (jwt : Jose.Jwt.t) =
  let now = int_of_float (Unix.time ()) in
  match get_int_member "iat" jwt.payload with
  | Some iat when iat <= now ->
      Log.debug (fun m -> m "iat is valid");
      Ok jwt (* TODO: Make the time diff configurable *)
  | Some _iat ->
      Log.debug (fun m -> m "iat is in the future");
      Error `Iat_in_future
  | None ->
      Log.debug (fun m -> m "iat is missing");
      Error `Missing_iat

let validate_iss ~issuer (jwt : Jose.Jwt.t) =
  match get_string_member "iss" jwt.payload with
  | Some iss when iss = issuer ->
      Log.debug (fun m -> m "iss is valid, %s" issuer);
      Ok jwt
  | Some iss ->
      Log.debug (fun m -> m "iss is invalid, expected %s, got %s" issuer iss);
      Error (`Wrong_iss_value iss)
  | None ->
      Log.debug (fun m -> m "iss is missing");
      Error `Missing_iss

let validate_aud ~(client : Client.t) (jwt : Jose.Jwt.t) =
  match Yojson.Safe.Util.member "aud" jwt.payload with
  | `String aud when aud = client.id ->
      Log.debug (fun m -> m "aud is valid");
      Ok jwt
  | `String aud ->
      Log.debug (fun m -> m "aud is invalid, expected %s got %s" client.id aud);
      Error (`Wrong_aud_value aud)
  | `List json -> (
      Log.debug (fun m -> m "aud is list");
      let maybe_client_id =
        List.find_opt (fun v -> v = `String client.id) json
      in
      match maybe_client_id with
      | Some _ ->
          Log.debug (fun m -> m "aud list includes %s" client.id);
          Ok jwt
      | None ->
          Log.debug (fun m ->
              m "aud list does not include expected value %s" client.id);
          Error (`Wrong_aud_value "")
      (* TODO: Check azp as well if audience is longer than 1 *))
  | _ ->
      Log.debug (fun m -> m "aud is missing");
      Error `Missing_aud

let validate_nonce ?nonce (jwt : Jose.Jwt.t) =
  let jwt_nonce = get_string_member "nonce" jwt.payload in
  match (nonce, jwt_nonce) with
  | Some nonce, Some jwt_nonce ->
      if nonce = jwt_nonce then (
        Log.debug (fun m -> m "nonce is valid");
        Ok jwt)
      else (
        Log.debug (fun m ->
            m "nonce is invalid, expected %s got %s" nonce jwt_nonce);
        Error `Invalid_nonce)
  | None, Some _ ->
      Log.debug (fun m -> m "Got nonce but did not expect to");
      Error `Unexpected_nonce
  | Some _, None ->
      Log.debug (fun m -> m "nonce is missing when expected");
      Error `Missing_nonce
  | None, None ->
      Log.debug (fun m -> m "no nonce provided");
      Ok jwt

let validate ?nonce ?jwk ~(client : Client.t) ~issuer (jwt : Jose.Jwt.t) =
  let issuer = Uri.to_string issuer in
  (match (jwt.header.alg, jwk) with
  | `None, _ -> Ok jwt
  | _, Some jwk -> Jose.Jwt.validate ~jwk jwt
  | _, None -> Error `No_jwk_provided)
  >>= validate_iss ~issuer >>= validate_exp >>= validate_iat >>= validate_sub
  >>= validate_aud ~client >>= validate_nonce ?nonce
  |> fun jwt ->
  let () =
    match jwt with
    | Ok _ -> Log.debug (fun m -> m "JWT is valid")
    | Error _ -> Log.debug (fun m -> m "JWT is invalid")
  in
  jwt
