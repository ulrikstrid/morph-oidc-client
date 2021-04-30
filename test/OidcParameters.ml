open Helpers

let client =
  Oidc.Client.
    {
      id = "s6BhdRkqt3";
      response_types = [ "code" ];
      grant_types = [ "authorization_code" ];
      redirect_uris = [ Uri.of_string "https://client.example.org/cb" ];
      secret = Some "secret";
      token_endpoint_auth_method = "client_secret_post";
    }

let clients = [ client ]

let base_url = "http://localhost:3000/authorize"

let valid_query =
  "response_type=code&client_id=s6BhdRkqt3&redirect_uri=https://client.example.org/cb&scope=openid%20profile&state=af0ifjsldkj&nonce=n-0S6_WzA2Mj"

let parse_query () =
  match
    Oidc.Parameters.parse_query ~clients
      (Uri.of_string (base_url ^ valid_query))
  with
  | Ok valid_parameters ->
      check_string "client_id" "s6BhdRkqt3" valid_parameters.client.id;
      check_string "redirect_uri" "https://client.example.org/cb"
        (Uri.to_string valid_parameters.redirect_uri);
      check_option_string "nonce" "n-0S6_WzA2Mj" valid_parameters.nonce
  | _ -> ()

let to_query () =
  let parameters =
    Oidc.Parameters.
      {
        response_type = [ "code" ];
        client;
        redirect_uri = Uri.of_string "https://client.example.org/cb";
        scope = [ "openid"; "profile" ];
        state = Some "af0ifjsldkj";
        nonce = Some "n-0S6_WzA2Mj";
        claims = None;
        max_age = None;
        display = None;
        prompt = None;
      }
  in
  check_string "valid_query" valid_query
    (Oidc.Parameters.to_query parameters |> Uri.encoded_of_query)

let tests =
  List.map make_test_case
    [ ("Parses a query", parse_query); ("Creates a query", to_query) ]

let suite, _ =
  Junit_alcotest.run_and_report ~package:"oidc" "Parameters"
    [ ("OIDC - Parameters", tests) ]
