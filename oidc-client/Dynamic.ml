type 'store t = {
  kv : (module KeyValue.KV with type value = string and type store = 'store);
  store : 'store;
  http_client : Piaf.Client.t;
  meta : Oidc.Client.meta;
  provider_uri : Uri.t;
}

let get_or_create_client { kv; store; http_client; provider_uri; meta } =
  let open Lwt_result.Infix in
  Internal.discover ~kv ~store ~http_client ~provider_uri >>= fun discovery ->
  ( Internal.register ~kv ~store ~http_client ~meta ~discovery >|= fun dynamic ->
    Oidc.Client.of_dynamic_and_meta ~dynamic ~meta )
  >>= fun client ->
  Static.make ~kv ~store ~http_client
    ~redirect_uri:(List.hd meta.redirect_uris)
    ~provider_uri ~client

let make (type store)
    ~(kv : (module KeyValue.KV with type value = string and type store = store))
    ~(store : store) ~provider_uri (meta : Oidc.Client.meta) =
  Piaf.Client.create provider_uri
  |> Lwt_result.map (fun http_client ->
         { kv; store; http_client; meta; provider_uri })

let get_jwks t = Lwt_result.bind (get_or_create_client t) Static.get_jwks

let get_token ~code t =
  Lwt_result.bind (get_or_create_client t) (Static.get_token ~code)

let get_and_validate_id_token ?nonce ~code t =
  Lwt_result.bind
    (get_or_create_client t |> Utils.RPiaf.map_piaf_err)
    (Static.get_and_validate_id_token ?nonce ~code)

let get_auth_result ~nonce ~params ~state t =
  Lwt_result.bind
    (get_or_create_client t |> Utils.RPiaf.map_piaf_err)
    (Static.get_auth_result ~nonce ~params ~state)

let get_auth_parameters ?scope ?claims ~nonce ~state t =
  get_or_create_client t |> Utils.RPiaf.map_piaf_err
  |> Lwt_result.map (Static.get_auth_parameters ?scope ?claims ~nonce ~state)

let get_auth_uri ?scope ?claims ~nonce ~state t =
  let open Lwt_result.Infix in
  get_or_create_client t |> Utils.RPiaf.map_piaf_err
  >>= Static.get_auth_uri ?scope ?claims ~nonce ~state

let get_userinfo ~jwt ~token t =
  Lwt_result.bind
    (get_or_create_client t |> Utils.RPiaf.map_piaf_err)
    (Static.get_userinfo ~jwt ~token)

let register (t : 'store t) meta =
  Lwt_result.bind
    (Internal.discover ~kv:t.kv ~store:t.store ~http_client:t.http_client
       ~provider_uri:t.provider_uri
    |> Utils.RPiaf.map_piaf_err)
    (fun discovery ->
      Internal.register ~kv:t.kv ~store:t.store ~http_client:t.http_client ~meta
        ~discovery)
