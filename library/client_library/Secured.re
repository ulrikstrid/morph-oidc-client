let markup =
    (
      ~id_token: string,
      ~header: string,
      ~payload: string,
      ~signature: string,
      ~userinfo,
    ) =>
  Tyxml.(
    <Layout title="Secured">
      <h3> "Header" </h3>
      <pre> <code className="language-JSON"> {Html.txt(header)} </code> </pre>
      <h3> "Payload" </h3>
      <pre>
        <code className="language-JSON"> {Html.txt(payload)} </code>
      </pre>
      <h3> "Signature" </h3>
      <pre>
        <code className="language-JSON"> {Html.txt(signature)} </code>
      </pre>
      <h3> "id_token" </h3>
      <pre> <code> {Html.txt(id_token)} </code> </pre>
      <h3> "userinfo" </h3>
      <pre> <code> {Html.txt(userinfo)} </code> </pre>
    </Layout>
  );

let handle: Morph.Server.handler =
  req => {
    open Lwt.Syntax;
    open Lwt.Infix;
    let* provider =
      Morph.Middlewares.Session.get(req, ~key="provider")
      |> Lwt.map(Result.get_ok);

    let oidc_client = Context.get_client(req, provider);

    let* id_token_result =
      Morph.Middlewares.Session.get(req, ~key="id_token");
    let* access_token_result =
      Morph.Middlewares.Session.get(req, ~key="access_token");

    switch (id_token_result, access_token_result) {
    | (Ok(id_token), Ok(access_token)) =>
      OidcClient.Dynamic.get_userinfo(
        ~jwt=Jose.Jwt.of_string(id_token) |> Result.get_ok,
        ~token=access_token,
        oidc_client,
      )
      >|= (
        userinfo => {
          let userinfo =
            switch (userinfo) {
            | Ok(userinfo) => userinfo
            | Error(`Sub_missmatch) => "sub doesn't match id_token"
            | Error(`Missing_sub) => "Could not find sub in userinfo"
            | Error(`Msg(msg)) => msg
            };
          let () = Logs.info(m => m("userinfo: %s", userinfo));
          let jwt = Jose.Jwt.of_string(id_token) |> Result.get_ok;
          let header =
            Yojson.Safe.pretty_to_string(jwt.header |> Jose.Header.to_json);
          let payload = Yojson.Safe.pretty_to_string(jwt.payload);

          TyxmlRender.respond_html(
            markup(
              ~id_token,
              ~header,
              ~payload,
              ~signature=jwt.signature,
              ~userinfo,
            ),
          );
        }
      )
    | _ => Morph.Response.redirect("/") |> Lwt.return
    };
  };
