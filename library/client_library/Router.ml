let auth_callback_route : (Morph.Server.handler, 'a) Routes.target =
  Routes.(s "auth" / s "cb" /? nil)

let auth_route : (string -> 'a, 'b) Routes.target =
  Routes.(s "auth" / str /? nil)

let secure_route : (Morph.Server.handler, 'a) Routes.target =
  Routes.(s "secure" /? nil)

let routes ~providers =
  Routes.(
    one_of
      [
        empty @--> LandingPage.make providers;
        auth_callback_route @--> AuthCallback.make;
        auth_route @--> AuthPage.make;
        secure_route @--> Secured.handle;
      ])

let handler routes (req : Morph.Request.t) : Morph.Response.t Lwt.t =
  match Routes.match' ~target:req.request.target routes with
  | None -> Morph.Response.not_found () |> Lwt.return
  | Some h -> h req
