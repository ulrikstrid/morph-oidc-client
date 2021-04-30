module WebServer = {
  let start = () => {
    let port =
      try(Sys.getenv("PORT") |> int_of_string) {
      | _ => 4040
      };

    let server =
      Morph.Server.make(~port, ~address=Unix.inet_addr_loopback, ());

    let clients = [
      Oidc.Client.make(
        ~secret="secret",
        ~response_types=["code id_token"],
        ~grant_types=[],
        ~redirect_uris=[
          Uri.of_string("http://localhost:4141"),
          Uri.of_string("https://oidcdebugger.com/debug"),
        ],
        ~token_endpoint_auth_method="",
        "test",
      ),
    ];

    Logs.app(m => m("Starting server on %n", port));

    let handler =
      Morph.Middlewares.Session.middleware(
        ProviderLibrary.Router.handler(clients),
      );

    server.start(handler) |> Lwt_result.ok;
  };

  let stop = _server => {
    Logs.info(m => m("Stopped Server")) |> Lwt.return;
  };

  let component = Archi_lwt.Component.make(~start, ~stop);
};

let system = Archi_lwt.System.make([("web_server", WebServer.component)]);

open Lwt.Infix;

let main = () => {
  Logger.setup_log(Some(Logs.Warning));
  Logs.Src.set_level(Logs.default, Some(Logs.Debug));

  let () = Mirage_crypto_rng_unix.initialize();

  Archi_lwt.System.start((), system)
  >|= (
    fun
    | Ok(system) => {
        Logs.info(m => m("Starting"));

        Sys.(
          set_signal(
            sigint,
            Signal_handle(
              _ => {
                Logs.err(m => m("SIGNINT received, tearing down.@."));
                Archi_lwt.System.stop(system) |> ignore;
              },
            ),
          )
        );
      }
    | Error(_error) => {
        // Logs.err(m => m("ERROR: %s@.", Archi.Error.to_string(error)));
        exit(
          1,
        );
      }
  );
};

let () = Lwt_main.run(main());
