let make: string => Morph.Server.handler =
  (provider: string, request) => {
    open Lwt.Syntax;

    Logs.info(m => m("Starting login with %s", provider));

    let oidc_client = Context.get_client(request, provider);

    let state =
      Uuidm.v4_gen(Random.State.make_self_init(), ()) |> Uuidm.to_string;

    let nonce =
      Uuidm.v4_gen(Random.State.make_self_init(), ()) |> Uuidm.to_string;

    Logs.info(m => m("nonce on auth page: %s", nonce));

    let* () =
      Morph.Middlewares.Session.set(
        request,
        ~expiry=3600L,
        ~key="state",
        ~value=state,
      );
    let* () =
      Morph.Middlewares.Session.set(
        request,
        ~expiry=3600L,
        ~key="nonce",
        ~value=nonce,
      );
    let* () =
      Morph.Middlewares.Session.set(
        request,
        ~key="provider",
        ~value=provider,
      );

    let+ auth_uri =
      OidcClient.Dynamic.get_auth_uri(
        ~scope=["openid", "profile", "email"],
        ~nonce,
        ~state,
        oidc_client,
      );

    switch (auth_uri) {
    | Ok(auth_uri) =>
      let auth_uri = Uri.to_string(auth_uri);
      Logs.info(m =>
        m("Starting new authentication with auth_uri %s", auth_uri)
      );
      Morph.Response.redirect(auth_uri);
    | Error(e) => Error(`Server(Piaf.Error.to_string(e)))
    };
  };
