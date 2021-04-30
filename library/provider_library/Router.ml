let well_known_openid : (Morph.Server.handler, 'a) Routes.target =
  Routes.(s ".well-known" / s "openid-configuration" /? nil)

let auth : (Morph.Server.handler, 'a) Routes.target = Routes.(s "auth" /? nil)

let token : (Morph.Server.handler, 'a) Routes.target = Routes.(s "token" /? nil)

let get_routes clients =
  Routes.
    [
      well_known_openid @--> WellKnown.handler;
      auth @--> AuthRoute.handler clients;
      InteractionRoute.get_route;
    ]

let post_routes clients =
  Routes.[ InteractionRoute.post_route clients; token @--> TokenRoute.handler ]

let handler clients =
  Morph.Router.make ~get:(get_routes clients) ~post:(post_routes clients)
    ~not_found_handler:(fun _ -> Morph.Response.not_found () |> Lwt.return)
    ()
