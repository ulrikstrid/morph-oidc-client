(** Dynamic registration functions *)

(**
    All functions in this module maps to the base functions but will create a Client "just in time" and make sure you always have a fresh Client to work with.
    *)

type 'store t = {
  kv : (module KeyValue.KV with type value = string and type store = 'store);
  store : 'store;
  meta : Oidc.Client.meta;
  provider_uri : Uri.t;
}
(** A Dynamically registered OIDC Client *)

val make :
  kv:(module KeyValue.KV with type store = 'store and type value = string) ->
  store:'store ->
  provider_uri:Uri.t ->
  Oidc.Client.meta ->
  'store t

val register :
  get:(?headers:(string * string) list ->
    string -> (string, [> `Msg of string ] as 'a) Lwt_result.t) ->
  post:(?headers:(string * string) list ->
    body:string -> string -> (string, 'a) Lwt_result.t) ->
  'store t ->
  Oidc.Client.meta ->
  (Oidc.Client.dynamic_response, 'a) result Lwt.t
(** Register a dynamic client, this will mostly be handled for you automatically but can be useful *)

val get_jwks :
  get:(?headers:(string * string) list ->
    string -> (string, [> `Msg of string ] as 'a) Lwt_result.t) ->
  post:(?headers:(string * string) list ->
    body:string -> string -> (string, 'a) Lwt_result.t) ->
  'store t ->
  (Jose.Jwks.t, 'a) result Lwt.t

val get_token :
  code:string ->
  get:(?headers:(string * string) list ->
    string -> (string, [> `Msg of string ] as 'a) Lwt_result.t) ->
  post:(?headers:(string * string) list ->
    body:string -> string -> (string, 'a) Lwt_result.t) ->
  'store t ->
  (Oidc.Token.t, 'a) result Lwt.t

val get_auth_parameters :
  ?scope:string list ->
  ?claims:Yojson.Safe.t ->
  nonce:string ->
  get:(?headers:(string * string) list ->
    string -> (string, [> `Msg of string ] as 'a) Lwt_result.t) ->
  post:(?headers:(string * string) list ->
    body:string -> string -> (string, 'a) Lwt_result.t) ->
  state:string ->
  'store t ->
  (Oidc.Parameters.t, 'a) result Lwt.t

val get_auth_uri :
  ?scope:string list ->
  ?claims:Yojson.Safe.t ->
  nonce:string ->
  get:(?headers:(string * string) list ->
    string -> (string, [> `Msg of string ] as 'a) Lwt_result.t) ->
  post:(?headers:(string * string) list ->
    body:string -> string -> (string, 'a) Lwt_result.t) ->
  state:string ->
  'store t ->
  (string, 'a) result Lwt.t

val get_and_validate_id_token :
  ?nonce:string ->
  code:string ->
  get:(?headers:(string * string) list ->
    string ->
    (string, Oidc.IDToken.validation_error) Lwt_result.t) ->
  post:(?headers:(string * string) list ->
    body:string ->
    string ->
    (string, Oidc.IDToken.validation_error) Lwt_result.t) ->
  'store t ->
  (Oidc.Token.t, Oidc.IDToken.validation_error) result Lwt.t

val get_auth_result :
  nonce:string ->
  get:(?headers:(string * string) list ->
    string ->
    (string, Oidc.IDToken.validation_error) Lwt_result.t) ->
  post:(?headers:(string * string) list ->
    body:string ->
    string ->
    (string, Oidc.IDToken.validation_error) Lwt_result.t) ->
  params:(string * string list) list ->
  state:string ->
  'a t ->
  (Oidc.Token.t, Oidc.IDToken.validation_error) result Lwt.t

val get_userinfo :
  get:(?headers:(string * string) list ->
    string ->
    (string,
    [> `Missing_sub | `Msg of string | `Sub_missmatch ] as 'a)
    Lwt_result.t) ->
  post:(?headers:(string * string) list ->
    body:string -> string -> (string, 'a) Lwt_result.t) ->
  jwt:Jose.Jwt.t ->
  token:string ->
  'a t ->
  (string, 'a) result Lwt.t
