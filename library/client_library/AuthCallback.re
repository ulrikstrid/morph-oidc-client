let make = (req: Morph.Request.t) => {
  Lwt_result.Syntax.(
    {
      let* params =
        (
          switch (req.request.meth) {
          | `GET =>
            req.request.target
            |> Uri.of_string
            |> Uri.query
            |> Lwt_result.return
          | `POST =>
            Piaf.Body.to_string(req.request.body)
            |> Lwt_result.map(Uri.query_of_encoded)
          | _ => Lwt_result.fail(`Msg("Method not supported"))
          }
        )
        |> Lwt_result.map_err(_ => `Msg("No params provided"));

      let* provider =
        Morph.Middlewares.Session.get(req, ~key="provider")
        |> Lwt_result.map_err(_ => `Msg("No provider set in session"));

      Logs.info(m => m("Handling callback with client %s", provider));
      let oidc_client = Context.get_client(req, provider);
      Logs.info(m =>
        m(
          "oidc_client provider_uri %s",
          oidc_client.provider_uri |> Uri.to_string,
        )
      );

      let* nonce =
        Morph.Middlewares.Session.get(req, ~key="nonce")
        |> Lwt_result.map_err(_ => `Msg("No nonce set in session"));

      Logs.info(m => m("nonce on auth callback: %s", nonce));

      let* state =
        Morph.Middlewares.Session.get(req, ~key="state")
        |> Lwt_result.map_err(_ => `Msg("State not found in session"));

      let* auth_result =
        OidcClient.Dynamic.get_auth_result(
          ~params,
          ~nonce,
          ~state,
          oidc_client,
        );

      let* _ =
        switch (auth_result.access_token) {
        | Some(access_token) =>
          Lwt_result.ok @@
          Morph.Middlewares.Session.set(
            req,
            ~value=access_token,
            ~key="access_token",
          )
        | None => Lwt_result.return()
        };

      Lwt_result.ok @@
      Morph.Middlewares.Session.set(
        req,
        ~value=auth_result.id_token,
        ~key="id_token",
      );
    }
    |> Lwt.map(
         fun
         | Ok(_) => Morph.Response.redirect("/secure")
         | Error(`Expired) => Morph.Response.unauthorized("expired session")
         | Error(`Missing_exp) =>
           Morph.Response.unauthorized("exp missing in JWT")
         | Error(`Msg(str)) => Morph.Response.unauthorized(str)
         | Error(`Invalid_signature) =>
           Morph.Response.unauthorized("Invalid signature")
         | Error(`Invalid_nonce) =>
           Morph.Response.unauthorized("Invalid nonce value")
         | Error(`Missing_nonce) =>
           Morph.Response.unauthorized("nonce missing in JWT")
         | Error(`Unexpected_nonce) =>
           Morph.Response.unauthorized("nonce in JWT but not provided")
         | Error(`Unsafe) => Morph.Response.unauthorized("Unsafe usage")
         | Error(`Invalid_sub_length) =>
           Morph.Response.unauthorized("Invalid sub length")
         | Error(`Missing_sub) => Morph.Response.unauthorized("Missing sub")
         | Error(`Wrong_iss_value(iss)) =>
           Morph.Response.unauthorized("Wrong iss value " ++ iss)
         | Error(`Missing_iss) =>
           Morph.Response.unauthorized("Missing iss value")
         | Error(`Iat_in_future) =>
           Morph.Response.unauthorized("Token can't be issued in the future")
         | Error(`Missing_iat) => Morph.Response.unauthorized("Missing iat")
         | Error(`Wrong_aud_value(aud)) =>
           Morph.Response.unauthorized("Wrong aud value " ++ aud)
         | Error(`Missing_aud) =>
           Morph.Response.unauthorized("Missing aud value")
         | Error(`No_jwk_provided) =>
           Morph.Response.unauthorized("No jwk provided"),
       )
  );
};
