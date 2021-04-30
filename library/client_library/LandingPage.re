let make = (providers, _request) => {
  open Tyxml;

  let body =
    <Layout title="Landing page">
      <main className="flex flex-row items-center justify-center">
        <Card title="OIDC Demo Client"> ...<AuthButtons providers /> </Card>
      </main>
    </Layout>;

  TyxmlRender.respond_html(body) |> Lwt.return;
};
