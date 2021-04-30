let route_target () = Routes.(s "interaction" / str /? nil)

let print_route s = Routes.sprintf (route_target ()) s

let page (title_text : string) interaction_id =
  let uri = Tyxml.Html.uri_of_string (print_route interaction_id) in
  Tyxml.Html.(
    html
      (head (title (txt title_text)) [])
      (body
         [
           form
             ~a:[ a_action uri; a_method `Post ]
             [
               input ~a:[ a_input_type `Email; a_name "email" ] ();
               input ~a:[ a_input_type `Password; a_name "password" ] ();
               input ~a:[ a_input_type `Submit ] ();
             ];
         ]))

let get_handler interaction_id req =
  let open Lwt.Syntax in
  let+ params = Morph.Middlewares.Session.get req ~key:interaction_id in
  match params with
  | Ok _params -> TyxmlRender.respond_html (page "interaction" interaction_id)
  | Error Session.S.Not_found -> Morph.Response.text "no params session found"
  | Error Session.S.Not_set -> Morph.Response.text "no params session set"

let get_route = Routes.(route_target () @--> get_handler)

let post_handler clients interaction_id (req : Morph.Request.t) =
  let open Lwt.Syntax in
  let* body = Piaf.Body.to_string req.request.body in

  let* params = Morph.Middlewares.Session.get req ~key:interaction_id in
  match (body, params) with
  | Ok b, Ok params ->
      let parsed = Uri.query_of_encoded b in
      let email = List.assoc "email" parsed |> List.hd in
      let password = List.assoc "password" parsed |> List.hd in
      let user = User.find_valid email password |> Option.get in
      let auth_params =
        Oidc.Parameters.of_json ~clients (Yojson.Safe.from_string params)
        |> Result.get_ok
      in
      let code = CodeStore.create_code () in
      let+ () =
        CodeStore.save_code ~email:user.email ~client_id:auth_params.client.id
          code
      in
      let redirect_uri =
        Uri.with_query' auth_params.redirect_uri [ ("code", code) ]
      in
      Morph.Response.redirect (Uri.to_string redirect_uri)
  | _, Error Session.S.Not_found ->
      Morph.Response.text "no params session found" |> Lwt.return
  | _, Error Session.S.Not_set ->
      Morph.Response.text "no params session set" |> Lwt.return
  | _ -> Morph.Response.text "unknown" |> Lwt.return

let post_route clients = Routes.(route_target () @--> post_handler clients)
