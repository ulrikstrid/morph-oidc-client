let handler (req : Morph.Request.t) =
  let open Lwt.Syntax in
  let* body = Piaf.Body.to_string req.request.body in
  Logs.info (fun m -> m "%s" (body |> Result.get_ok));

  match Result.bind body Oidc.Token.Request.of_body_string with
  | Ok token_request ->
      Logs.info (fun m -> m "test2");
      let+ email, client_id = CodeStore.use_code token_request.code in

      Morph.Response.text (email ^ client_id)
  | Error (`Msg s) -> Morph.Response.text s |> Lwt.return
  | Error e -> Morph.Response.text (Piaf.Error.to_string e) |> Lwt.return
