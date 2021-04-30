(** Dynamic registration functions *)

(**
    All functions in this module maps to the base functions but will create a Client "just in time" and make sure you always have a fresh Client to work with.
    *)

type 'store t = {
  kv : (module KeyValue.KV with type value = string and type store = 'store);
  store : 'store;
  http_client : Piaf.Client.t;
  meta : Oidc.Client.meta;
  provider_uri : Uri.t;
}
(** A Dynamically registered OIDC Client *)

val make :
  kv:(module KeyValue.KV with type store = 'store and type value = string) ->
  store:'store ->
  provider_uri:Uri.t ->
  Oidc.Client.meta ->
  ('store t, Piaf.Error.t) result Lwt.t

val register :
  'store t ->
  Oidc.Client.meta ->
  (Oidc.Client.dynamic_response, Piaf.Error.t) result Lwt.t
(** Register a dynamic client, this will mostly be handled for you automatically but can be useful *)

val get_jwks : 'store t -> (Jose.Jwks.t, Piaf.Error.t) result Lwt.t

val get_token :
  code:string -> 'store t -> (Oidc.Token.Response.t, Piaf.Error.t) result Lwt.t

val get_auth_parameters :
  ?scope:string list ->
  ?claims:Yojson.Safe.t ->
  nonce:string ->
  state:string ->
  'store t ->
  (Oidc.Parameters.t, [> `Msg of string ]) result Lwt.t

val get_auth_uri :
  ?scope:string list ->
  ?claims:Yojson.Safe.t ->
  nonce:string ->
  state:string ->
  'store t ->
  (Uri.t, Piaf.Error.t) result Lwt.t

val get_and_validate_id_token :
  ?nonce:string ->
  code:string ->
  'store t ->
  (Oidc.Token.Response.t, Oidc.IDToken.validation_error) result Lwt.t

val get_auth_result :
  nonce:string ->
  params:(string * string list) list ->
  state:string ->
  'a t ->
  (Oidc.Token.Response.t, Oidc.IDToken.validation_error) result Lwt.t

val get_userinfo :
  jwt:Jose.Jwt.t ->
  token:string ->
  'a t ->
  (string, [> `Missing_sub | `Msg of string | `Sub_missmatch ]) result Lwt.t
