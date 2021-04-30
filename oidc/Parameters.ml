open Utils

type error =
  [ `Unauthorized_client of Client.t
  | `Missing_client
  | `Invalid_scope of string list
  | `Invalid_redirect_uri of string
  | `Missing_parameter of string
  | `Invalid_display of string
  | `Invalid_prompt of string
  | `Invalid_parameters ]

type display = [ `Page | `Popup | `Touch | `Wap ]

let string_to_display = function
  | "page" -> Ok `Page
  | "popup" -> Ok `Popup
  | "touch" -> Ok `Touch
  | "wap" -> Ok `Wap
  | s -> Error (`Invalid_display s)

let display_to_string = function
  | `Page -> "page"
  | `Popup -> "popup"
  | `Touch -> "touch"
  | `Wap -> "wap"

type prompt = [ `None | `Login | `Consent | `Select_account ]

let string_to_prompt = function
  | "none" -> Ok `None
  | "login" -> Ok `Login
  | "consent" -> Ok `Consent
  | "select_account" -> Ok `Select_account
  | s -> Error (`Invalid_prompt s)

let prompt_to_string = function
  | `None -> "none"
  | `Login -> "login"
  | `Consent -> "consent"
  | `Select_account -> "select_account"

type t = {
  response_type : string list;
  (* TODO: This should probably just be a string *)
  client : Client.t;
  redirect_uri : Uri.t;
  scope : string list;
  (* Must include at least the openid scope *)
  state : string option;
  nonce : string option;
  claims : Yojson.Safe.t option;
  max_age : int option;
  display : display option;
  prompt : prompt option;
}

let make ?(response_type = [ "code" ]) ?(scope = [ "openid" ]) ?state ?claims
    ?max_age ?display ?prompt ?nonce client ~redirect_uri =
  {
    response_type;
    client;
    redirect_uri;
    scope;
    state;
    nonce;
    claims;
    max_age;
    display;
    prompt;
  }

let identity a = a

let to_query t =
  [
    Some ("response_type", t.response_type);
    Some ("client_id", [ t.client.id ]);
    Some ("redirect_uri", [ Uri.to_string t.redirect_uri ]);
    Some ("scope", [ String.concat " " t.scope ]);
    Option.map (fun state -> ("state", [ state ])) t.state;
    Option.map (fun nonce -> ("nonce", [ nonce ])) t.nonce;
    Option.map
      (fun claims -> ("claims", [ Yojson.Safe.to_string claims ]))
      t.claims;
    Option.map (fun prompt -> ("prompt", [ prompt_to_string prompt ])) t.prompt;
    Option.map
      (fun display -> ("display", [ display_to_string display ]))
      t.display;
  ]
  |> List.filter_map identity

let get_client ~clients client_id =
  List.find_opt (fun (client : Client.t) -> client.id = client_id) clients
  |> function
  | Some client -> Ok client
  | None -> Error `Missing_client

let to_json t : Yojson.Safe.t =
  `Assoc
    ([
       Some
         ( "response_type",
           `List (t.response_type |> List.map (fun r -> `String r)) );
       Some ("client_id", `String t.client.id);
       Some ("redirect_uri", `String (Uri.to_string t.redirect_uri));
       Some ("scope", `List (t.scope |> List.map (fun r -> `String r)));
       Option.map (fun state -> ("state", `String state)) t.state;
       Option.map (fun nonce -> ("nonce", `String nonce)) t.nonce;
       Option.map (fun claims -> ("claims", claims)) t.claims;
       Option.map
         (fun prompt -> ("prompt", `String (prompt_to_string prompt)))
         t.prompt;
       Option.map
         (fun display -> ("display", `String (display_to_string display)))
         t.display;
     ]
    |> List.filter_map identity)

let of_json ~clients json : (t, error) result =
  let module Json = Yojson.Safe.Util in
  try
    Ok
      {
        response_type =
          Json.to_list (Json.member "response_type" json)
          |> List.map Json.to_string;
        client =
          get_client ~clients (Json.member "client_id" json |> Json.to_string)
          |> Result.get_ok;
        redirect_uri =
          json |> Json.member "redirect_uri" |> Json.to_string |> Uri.of_string;
        scope =
          json |> Json.member "scope" |> Json.to_list |> List.map Json.to_string;
        state = json |> Json.member "state" |> Json.to_string_option;
        nonce = json |> Json.member "nonce" |> Json.to_string_option;
        claims = json |> Json.member "claims" |> Option.some;
        max_age = json |> Json.member "max_age" |> Json.to_int_option;
        display =
          json |> Json.member "display" |> Json.to_string_option
          |> ROpt.flat_map (fun d -> string_to_display d |> ROpt.of_result);
        prompt =
          json |> Json.member "prompt" |> Json.to_string_option
          |> ROpt.flat_map (fun p -> string_to_prompt p |> ROpt.of_result);
      }
  with _ -> Error `Invalid_parameters

let parse_query ~clients uri : (t, [> error ]) result =
  let getQueryParam param =
    Uri.get_query_param uri param |> function
    | Some x -> Ok x
    | None -> Error (`Missing_parameter (param ^ " not found"))
  in

  match getQueryParam "client_id" |> RResult.flat_map (get_client ~clients) with
  | Error e -> Error e
  | Ok client -> (
      let claims =
        getQueryParam "claims" |> Result.map Yojson.Safe.from_string |> function
        | Ok x -> Some x
        | Error _ -> None
      in

      let response_type =
        getQueryParam "response_type" |> Result.map (String.split_on_char ' ')
      in

      let redirect_uri = getQueryParam "redirect_uri" in

      let scope =
        getQueryParam "scope" |> Result.map (String.split_on_char ' ')
        (* TODO: Check for openid *)
      in

      let max_age =
        getQueryParam "max_age" |> ROpt.of_result
        |> ROpt.flat_map int_of_string_opt
      in

      match (response_type, redirect_uri, scope) with
      | Ok response_type, Ok redirect_uri, Ok scope
        when List.exists
               (fun uri -> Uri.to_string uri = redirect_uri)
               client.redirect_uris ->
          Ok
            {
              response_type;
              client;
              redirect_uri = Uri.of_string redirect_uri;
              scope;
              state = ROpt.of_result (getQueryParam "state");
              nonce = ROpt.of_result (getQueryParam "nonce");
              claims;
              max_age;
              display =
                RResult.flat_map string_to_display (getQueryParam "display")
                |> ROpt.of_result;
              prompt =
                RResult.flat_map string_to_prompt (getQueryParam "prompt")
                |> ROpt.of_result;
            }
      | Ok _, Ok redirect_uri, Ok _ ->
          Error (`Invalid_redirect_uri redirect_uri)
      | Error e, _, _ -> Error e
      | _, Error e, _ -> Error e
      | _, _, Error e -> Error e)
