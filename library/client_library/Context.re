module Env = {
  let key = Hmap.Key.create();
};

let get_context = (request: Morph.Request.t) =>
  Hmap.get(Env.key, request.ctx);

let get_client = (request, name) => {
  let htbl = get_context(request);
  Hashtbl.find(htbl, name);
};

let middleware:
  (
    ~context: Hashtbl.t(
                string,
                OidcClient.Dynamic.t(Hashtbl.t(string, string)),
              )
  ) =>
  Morph.Server.middleware =
  (~context, handler, request) => {
    let next_request = {
      ...request,
      ctx: Hmap.add(Env.key, context, request.ctx),
    };
    handler(next_request);
  };
