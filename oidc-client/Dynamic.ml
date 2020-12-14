type 'store t = {
  kv : (module KeyValue.KV with type value = string and type store = 'store);
  store : 'store;
  meta : Oidc.Client.meta;
  provider_uri : Uri.t;
}

let get_or_create_client ~get ~post { kv; store; provider_uri; meta } =
  let open Lwt_result.Infix in
  Internal.discover ~kv ~store ~get ~provider_uri >>= fun discovery ->
  ( Internal.register ~kv ~store ~post ~meta ~discovery >|= fun dynamic ->
    Oidc.Client.of_dynamic_and_meta ~dynamic ~meta )
  >>= fun client ->
  Lwt.return_ok @@ Static.make ~kv ~store
    ~redirect_uri:(List.hd meta.redirect_uris)
    ~provider_uri ~client

let make (type store)
    ~(kv : (module KeyValue.KV with type value = string and type store = store))
    ~(store : store) ~provider_uri (meta : Oidc.Client.meta) =
  { kv; store; meta; provider_uri }

let get_jwks ~get ~post t = Lwt_result.bind (get_or_create_client ~get ~post t) (Static.get_jwks ~get)

let get_token ~code ~get ~post t =
  Lwt_result.bind (get_or_create_client ~get ~post t) (Static.get_token ~code ~get ~post )

let get_and_validate_id_token ?nonce ~code ~get ~post t =
  Lwt_result.bind
    (get_or_create_client ~get ~post t)
    (Static.get_and_validate_id_token ?nonce ~code ~get ~post)

let get_auth_result ~nonce ~get ~post ~params ~state t =
  Lwt_result.bind
    (get_or_create_client ~get ~post t)
    (Static.get_auth_result ~nonce ~get ~post ~params ~state)

let get_auth_parameters ?scope ?claims ~nonce ~get ~post ~state t =
  get_or_create_client~get ~post t
  |> Lwt_result.map (Static.get_auth_parameters ?scope ?claims ~nonce ~state)

let get_auth_uri ?scope ?claims ~nonce ~get ~post ~state t =
  let open Lwt_result.Infix in
  get_or_create_client ~get ~post t
  >>= Static.get_auth_uri ?scope ?claims ~nonce ~get ~state

let get_userinfo ~get ~post ~jwt ~token t =
  Lwt_result.bind
    (get_or_create_client ~get ~post t)
    (Static.get_userinfo ~get ~jwt ~token)

let register ~get ~post (t : 'store t) meta =
  Lwt_result.bind
    ( Internal.discover ~kv:t.kv ~store:t.store ~get
        ~provider_uri:t.provider_uri)
    (fun discovery ->
      Internal.register ~kv:t.kv ~store:t.store ~post ~meta
        ~discovery)
