(** Parsing and creating the discovery document.
All fields listed here: https://openid.net/specs/openid-connect-discovery-1_0.html#ProviderMetadata *)

type t = {
  issuer : Uri.t;
  authorization_endpoint : Uri.t;
  token_endpoint : Uri.t;
  jwks_uri : Uri.t;
  userinfo_endpoint : Uri.t option;
  registration_endpoint : Uri.t option;
  response_types_supported : string list;
      (** "code", "id_token", "token id_token" *)
  subject_types_supported : string list;
      (** "pairwise", "public" https://openid.net/specs/openid-connect-core-1_0.html#SubjectIDTypes *)
  id_token_signing_alg_values_supported : string list;
      (** "RS256" must be supported *)
}
(** {i The discovery type can include much more than the type currently includes. Feel free to open a PR adding anything you need } *)

val of_json : Yojson.Safe.t -> t
(** {i This might change to return a result in the future} *)

val of_string : string -> t
(** {i This might change to return a result in the future} *)

val to_json : t -> Yojson.Safe.t
