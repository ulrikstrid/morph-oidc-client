open Tyxml;

let auth_route = Routes.(s("auth") / str /? nil);

let createElement = (~providers: list(CertificationClients.t), ()) => {
  let buttons =
    List.map(
      (provider: CertificationClients.t) => {
        let href = Routes.sprintf(auth_route, provider.name);
        <Button.Link href title={provider.info}>
          {Html.txt(provider.name)}
        </Button.Link>;
      },
      providers,
    );

  [
    <p className="text-md mb-2 pb-2 border-b-2 border-gray-500 text-center">
      "Login alternatives"
    </p>,
    ...buttons,
  ];
};
