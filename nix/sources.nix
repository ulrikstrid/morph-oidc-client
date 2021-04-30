{ ocamlVersion ? "4_11" }:
let
  overlays =
    builtins.fetchTarball
      https://github.com/ulrikstrid/nix-overlays/archive/cff5393e8d6e9e036c9973e953cd6ed804b5fde4.tar.gz;

in
import "${overlays}/sources.nix" {
  overlays = [
    (import overlays)
    (self: super: {
      ocamlPackages = super.ocaml-ng."ocamlPackages_${ocamlVersion}";

      pkgsCross.musl64.pkgsStatic = super.pkgsCross.musl64.pkgsStatic.appendOverlays [
        (self: super: {
          ocamlPackages = super.ocaml-ng."ocamlPackages_${ocamlVersion}";
        })
      ];
    })
  ];
}
