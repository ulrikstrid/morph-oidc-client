open Utils

let read_registration ~get ~client_id ~(discovery : Oidc.Discover.t) =
  match discovery.registration_endpoint with
  | Some endpoint ->
      let open Lwt_result.Infix in
      let registration_path = Uri.of_string endpoint |> Uri.path in
      let query = Uri.encoded_of_query [ ("client_id", [ client_id ]) ] in
      let uri = registration_path ^ query in
      get uri >>= fun s ->
      Oidc.Client.dynamic_of_string s |> Lwt.return
  | None -> Lwt_result.fail (`Msg "No_registration_endpoint")

let register (type store)
    ~(kv : (module KeyValue.KV with type value = string and type store = store))
    ~(store : store) ~(post: ?headers:(string * string) list ->
      body:string -> string -> (string, 'a) Lwt_result.t) ~meta ~(discovery : Oidc.Discover.t) =
  let (module KV) = kv in
  let open Lwt_result.Infix in
  ( KV.get ~store "dynamic_string" >>= fun dynamic_string ->
    Lwt.return
      ( match Oidc.Client.dynamic_of_string dynamic_string with
      | Error e -> Error e
      | Ok dynamic ->
          if Oidc.Client.dynamic_is_expired dynamic then Error `Expired_client
          else Ok dynamic ) )
  |> fun r ->
  Lwt.bind r (fun x ->
      match (x, discovery.registration_endpoint) with
      | Ok dynamic, _ -> Lwt_result.return dynamic
      | Error _, Some endpoint ->
          let meta_string = Oidc.Client.meta_to_string meta in
          let body = meta_string in
          let registration_path = Uri.of_string endpoint |> Uri.path in
          ( post ~body registration_path
          >>= fun dynamic_string ->
            let () =
              Log.debug (fun m -> m "dynamic string: %s" dynamic_string)
            in
            let open Lwt.Syntax in
            let+ () = KV.set ~store "dynamic_string" dynamic_string in
            Ok dynamic_string )
          >>= fun s -> Oidc.Client.dynamic_of_string s |> Lwt.return
      | Error _, None -> Lwt_result.fail (`Msg "No_registration_endpoint"))

let discover (type store)
    ~(kv : (module KeyValue.KV with type value = string and type store = store))
    ~(store : store) ~(get: ?headers:(string * string) list ->
      string -> (string, 'a) Lwt_result.t) ~provider_uri =
  let open Lwt_result.Infix in
  let (module KV) = kv in
  let save discovery =
    Log.debug (fun m -> m "discovery: %s" discovery);
    KV.set ~store "discovery" discovery |> Lwt_result.ok >|= fun _ -> discovery
  in
  Lwt.bind (KV.get ~store "discovery") (fun result ->
      match result with
      | Ok discovery -> Lwt_result.return discovery
      | Error _ ->
          let discover_path =
            Uri.path provider_uri ^ "/.well-known/openid-configuration"
          in
          let () = print_endline (Uri.to_string provider_uri) in
          get discover_path >>= save)
  |> Lwt_result.map Oidc.Discover.of_string

let jwks (type store)
    ~(kv : (module KeyValue.KV with type value = string and type store = store))
    ~(store : store) ~get ~provider_uri =
  let open Lwt_result.Infix in
  let open Lwt_result.Syntax in
  let (module KV) = kv in
  let save jwks =
    KV.set ~store "jwks" jwks |> Lwt_result.ok >|= fun _ -> jwks
  in
  Lwt.bind (KV.get ~store "jwks") (fun result ->
      match result with
      | Ok jwks -> Lwt_result.return jwks
      | Error _ ->
          let* discovery = discover ~kv ~store ~get ~provider_uri in
          let jwks_path = Uri.of_string discovery.jwks_uri |> Uri.path in
          get jwks_path >>= save)
  |> Lwt_result.map Jose.Jwks.of_string

(* TODO: Move to oidc lib *)
let validate_userinfo ~(jwt : Jose.Jwt.t) userinfo =
  let userinfo_json = Yojson.Safe.from_string userinfo in
  let userinfo_sub =
    Yojson.Safe.Util.member "sub" userinfo_json
    |> Yojson.Safe.Util.to_string_option
  in
  let sub =
    Yojson.Safe.Util.member "sub" jwt.payload |> Yojson.Safe.Util.to_string
  in
  match userinfo_sub with
  | Some s when s = sub ->
      Log.debug (fun m -> m "Userinfo is valid");
      Ok userinfo
  | Some s ->
      Log.debug (fun m ->
          m "Userinfo has invalid sub, expected %s got %s" sub s);
      Error `Sub_missmatch
  | None ->
      Log.debug (fun m -> m "Userinfo is missing sub");
      Error `Missing_sub
