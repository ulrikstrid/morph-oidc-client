(* All fields listed here: https://openid.net/specs/openid-connect-discovery-1_0.html#ProviderMetadata *)
type t = {
  issuer : Uri.t;
  authorization_endpoint : Uri.t;
  token_endpoint : Uri.t;
  jwks_uri : Uri.t;
  userinfo_endpoint : Uri.t option;
  registration_endpoint : Uri.t option;
  response_types_supported : string list;
  (* "code", "id_token", "token id_token" *)
  subject_types_supported : string list;
  (* "pairwise", "public" *)
  id_token_signing_alg_values_supported : string list;
      (* "RS256" must be supported, get list from Jose? *)
}

(* TODO: Should maybe be a result? *)
let of_json json =
  Yojson.Safe.Util.
    {
      authorization_endpoint =
        json |> member "authorization_endpoint" |> to_string |> Uri.of_string;
      token_endpoint =
        json |> member "token_endpoint" |> to_string |> Uri.of_string;
      jwks_uri = json |> member "jwks_uri" |> to_string |> Uri.of_string;
      userinfo_endpoint =
        json |> member "userinfo_endpoint" |> to_string_option
        |> Option.map Uri.of_string;
      issuer = json |> member "issuer" |> to_string |> Uri.of_string;
      registration_endpoint =
        json
        |> member "registration_endpoint"
        |> to_string_option |> Option.map Uri.of_string;
      response_types_supported =
        json
        |> member "response_types_supported"
        |> to_list |> List.map to_string;
      subject_types_supported =
        json
        |> member "subject_types_supported"
        |> to_list |> List.map to_string;
      id_token_signing_alg_values_supported =
        json
        |> member "id_token_signing_alg_values_supported"
        |> to_list |> List.map to_string;
    }

(* TODO: Should maybe be a result? *)
let of_string body = Yojson.Safe.from_string body |> of_json

let to_json t =
  let userinfo_endpoint =
    match Option.map Uri.to_string t.userinfo_endpoint with
    | Some s -> `String s
    | None -> `Null
  in
  let registration_endpoint =
    match Option.map Uri.to_string t.registration_endpoint with
    | Some s -> `String s
    | None -> `Null
  in
  let json_of_string s = `String s in
  `Assoc
    ([
       ("issuer", `String (Uri.to_string t.issuer));
       ( "authorization_endpoint",
         `String (Uri.to_string t.authorization_endpoint) );
       ("token_endpoint", `String (Uri.to_string t.token_endpoint));
       ("jwks_uri", `String (Uri.to_string t.jwks_uri));
       ("userinfo_endpoint", userinfo_endpoint);
       ("registration_endpoint", registration_endpoint);
       ( "response_types_supported",
         `List (List.map json_of_string t.response_types_supported) );
       ( "subject_types_supported",
         `List (List.map json_of_string t.subject_types_supported) );
       ( "id_token_signing_alg_values_supported",
         `List (List.map json_of_string t.id_token_signing_alg_values_supported)
       );
     ]
    |> List.filter (fun (_, v) -> v <> `Null))
