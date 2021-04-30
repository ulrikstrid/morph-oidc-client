(** ID Token validation and creation

{{:https://openid.net/specs/openid-connect-core-1_0.html#IDToken} Spec link} *)

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
(** Possible validation errors *)

val validate :
  ?nonce:string ->
  ?jwk:'a Jose.Jwk.t ->
  client:Client.t ->
  issuer:Uri.t ->
  Jose.Jwt.t ->
  (Jose.Jwt.t, validation_error) result
(** Validation of the ID Token according to the spec.

  [jwk] is not needed when ["alg": "none"]

{{:https://openid.net/specs/openid-connect-core-1_0.html#IDTokenValidation} Spec link}
*)

(**
  {2 Extra info }
  Required fields
  - iss
  - sub - not longer than 256 ASCII chars
  - aud
  - exp
  - iat
  
  Fields to be validated if exists
  - nonce

  Optional fields:
  - acr
  - amr
  - azp (required if aud is a list)
*)
