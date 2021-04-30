module DynamicOidcClient = {
  open Lwt.Syntax;

  let start = () => {
    let kv:
      module OidcClient.KeyValue.KV with
        type value = string and type store = Hashtbl.t(string, string) =
      (module OidcClient.KeyValue.MemoryKV);

    let+ certification_clients =
      Library.CertificationClients.get_clients(~kv, ~make_store=() =>
        Hashtbl.create(128)
      );

    let oidc_clients_tbl = Hashtbl.create(32);

    let () =
      List.iter(
        x => {
          switch (x) {
          | Ok((data, client)) =>
            Library.CertificationClients.(
              Hashtbl.add(oidc_clients_tbl, data.name, client)
            )
          | Error(e) => Logs.err(m => m("%s", Piaf.Error.to_string(e)))
          }
        },
        certification_clients,
      );
    Ok(oidc_clients_tbl);
  };

  let stop = oidc_clients_tbl => {
    Logs.info(m => m("Stopping OIDC Clients"));

    Hashtbl.to_seq(oidc_clients_tbl)
    |> Array.of_seq
    |> Array.map(((_, client): (string, OidcClient.Dynamic.t('a))) =>
         Piaf.Client.shutdown(client.http_client)
       )
    |> Array.to_list
    |> Lwt.join;
  };

  let component = Archi_lwt.Component.make(~start, ~stop);
};

module WebServer = {
  open Library;

  let port =
    try(Sys.getenv("PORT") |> int_of_string) {
    | _ => 4040
    };

  let server = Morph.Server.make(~port, ~address=Unix.inet_addr_any, ());

  let start = ((), context) => {
    Logs.app(m => m("Starting server on %n", port));

    let handler =
      Morph.Middlewares.Session.middleware(
        Context.middleware(
          ~context,
          Router.handler(
            Router.routes(~providers=Library.CertificationClients.datas),
          ),
        ),
      );

    server.start(handler) |> Lwt_result.ok;
  };

  let stop = _server => {
    Logs.info(m => m("Stopped Server")) |> Lwt.return;
  };

  let component =
    Archi_lwt.Component.using(
      ~start,
      ~stop,
      ~dependencies=[DynamicOidcClient.component],
    );
};

let system =
  Archi_lwt.System.make([
    ("oidc_client", DynamicOidcClient.component),
    ("web_server", WebServer.component),
  ]);

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
