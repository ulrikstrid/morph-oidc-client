open Utils

let src =
  Logs.Src.create "oidc.token" ~doc:"logs OIDC events in the IDToken module"

module Log = (val Logs.src_log src : Logs.LOG)

let clean_string = Uri.pct_encode ~component:`Userinfo

let basic_auth ~client_id ~secret =
  (* https://tools.ietf.org/html/rfc6749#appendix-B *)
  let username = clean_string client_id in
  let password = clean_string secret in

  Log.debug (fun m -> m "username: %s, secret: %s" username password);

  let b64 = RBase64.encode_string (Printf.sprintf "%s:%s" username password) in
  Log.debug (fun m -> m "Basic auth: %s" b64);
  ("Authorization", "Basic " ^ b64)

module Request = TokenRequest
module Response = TokenResponse
