let handler clients (req : Morph.Request.t) =
  let uri = Uri.of_string req.request.target in
  match Oidc.Parameters.parse_query ~clients uri with
  | Ok params ->
      let open Lwt.Infix in
      let uuid = Uuidm.create `V4 in
      let uuid_str = Uuidm.to_string uuid in
      let params_json = params |> Oidc.Parameters.to_json in
      Morph.Middlewares.Session.set req
        ~value:(Yojson.Safe.to_string params_json)
        ~key:uuid_str
      >|= fun () ->
      Morph.Response.redirect (InteractionRoute.print_route uuid_str)
  | Error (`Unauthorized_client _) ->
      Morph.Response.text "Unauthorized_client" |> Lwt.return
  | Error `Missing_client -> Morph.Response.text "Missing_client" |> Lwt.return
  | Error (`Invalid_scope s) ->
      Morph.Response.text ("Invalid_scope " ^ String.concat " " s) |> Lwt.return
  | Error (`Invalid_redirect_uri s) ->
      Morph.Response.text ("Invalid_redirect_uri " ^ s) |> Lwt.return
  | Error (`Missing_parameter s) ->
      Morph.Response.text ("Missing_parameter " ^ s) |> Lwt.return
  | Error (`Invalid_display s) ->
      Morph.Response.text ("Invalid_display " ^ s) |> Lwt.return
  | Error (`Invalid_prompt s) ->
      Morph.Response.text ("Invalid_prompt " ^ s) |> Lwt.return
  | Error `Invalid_parameters ->
      Morph.Response.text "Invalid_parameters" |> Lwt.return
