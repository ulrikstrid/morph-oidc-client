let result_t :
    [> `Msg of string
    | `Expired
    | `Missing_exp
    | `Invalid_signature
    | `Invalid_nonce
    | `Missing_nonce
    | `Unexpected_nonce
    | `Invalid_sub_length
    | `Missing_sub
    | `Wrong_iss_value of string
    | `Missing_iss
    | `Iat_in_future
    | `Missing_iat
    | `Wrong_aud_value of string
    | `Missing_aud
    | `No_jwk_provided
    | `Unsafe ]
    Alcotest.testable =
  let pp ppf = function
    | `Msg e -> Fmt.string ppf e
    | `Expired -> Fmt.string ppf "expired"
    | `Missing_exp -> Fmt.string ppf "Missing exp"
    | `Invalid_signature -> Fmt.string ppf "Invalid signature"
    | `Invalid_nonce -> Fmt.string ppf "Invalid nonce"
    | `Missing_nonce -> Fmt.string ppf "Missing nonce"
    | `Unexpected_nonce -> Fmt.string ppf "Got nonce when not expected"
    | `Invalid_sub_length -> Fmt.string ppf "Invalid sub length"
    | `Missing_sub -> Fmt.string ppf "Missing sub"
    | `Wrong_aud_value aud -> Fmt.string ppf ("Wrong aud " ^ aud)
    | `Missing_aud -> Fmt.string ppf "aud is missing"
    | `Wrong_iss_value iss -> Fmt.string ppf ("Wrong iss value " ^ iss)
    | `Missing_iss -> Fmt.string ppf "iss is missing"
    | `Iat_in_future -> Fmt.string ppf "iat is in future"
    | `Missing_iat -> Fmt.string ppf "Missing iat"
    | `No_jwk_provided -> Fmt.string ppf "No jwk provided but is needed"
    | `Unsafe -> Fmt.string ppf "Unsafe action"
  in
  Alcotest.testable pp ( = )

let check_string = Alcotest.(check string)

let check_result_string = Alcotest.(check (result string result_t))

let check_result_bool = Alcotest.(check (result bool result_t))

let check_option_string name expected actual =
  Alcotest.(check (option string)) name (Some expected) actual

let check_int = Alcotest.(check int)

(*
let trim_json_string str =
  str |> CCString.replace ~sub:" " ~by:"" |> CCString.replace ~sub:"\n" ~by:""
*)

let make_test_case (name, test) = Alcotest.test_case name `Quick test
