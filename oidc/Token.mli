(** Types and functions to work with the token endpoint *)

(** {{: https://openid.net/specs/openid-connect-core-1_0.html#TokenEndpoint} OpenID Connect Core 1.0 TokenEndpoint} *)

module Response : sig
  type token_type = Bearer

  type t = {
    token_type : token_type;
    scope : string option;
    expires_in : int option;
    ext_exipires_in : int option;
    access_token : string option;
    refresh_token : string option;
    id_token : string;
  }
  (** A token response *)

  val of_json : Yojson.Safe.t -> t

  val of_string : string -> t
end

module Request : sig
  (** Types and functions to work with the token endpoint *)

  type t = {
    grant_type : string;
    scope : string list;
    code : string;
    client_id : string;
    client_secret : string option;
    redirect_uri : Uri.t;
  }
  (** A token request *)

  val make :
    client:Client.t ->
    grant_type:string ->
    scope:string list ->
    redirect_uri:Uri.t ->
    code:string ->
    t

  val to_body_string : t -> string
  (** Creates the body for the token request *)

  val of_body_string : string -> (t, [> `Msg of string ]) result
  (** Parses a request body into a t *)

  (** {2 Notes}

  The Authorization Server MUST validate the Token Request as follows:
  - Authenticate the Client if it was issued Client Credentials or if it uses another Client Authentication method, per Section 9.
  - Ensure the Authorization Code was issued to the authenticated Client.
  - Verify that the Authorization Code is valid.
  - If possible, verify that the Authorization Code has not been previously used.
  - Ensure that the redirect_uri parameter value is identical to the redirect_uri parameter value that was included in the initial Authorization Request. If the redirect_uri parameter value is not present when there is only one registered redirect_uri value, the Authorization Server MAY return an error (since the Client should have included the parameter) or MAY proceed without an error (since OAuth 2.0 permits the parameter to be omitted in this case).
  - Verify that the Authorization Code used was issued in response to an OpenID Connect Authentication Request (so that an ID Token will be returned from the Token Endpoint).
  *)
end

(** {2 Utils} *)

val basic_auth : client_id:string -> secret:string -> string * string
(** Creates a valid Basic auth header from [client_id] and [secret] *)
