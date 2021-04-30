{ pkgs, stdenv, lib, ocamlPackages, static ? false, doCheck }:

with ocamlPackages;

rec {
  oidc = buildDunePackage {
    pname = "oidc";
    version = "0.0.1-dev";

    src = lib.filterGitSource {
      src = ./..;
      dirs = [ "oidc" ];
      files = [ "dune-project" "oidc.opam" ];
    };

    useDune2 = true;

    propagatedBuildInputs = [
      uri
      jose
      yojson
      logs
    ];

    inherit doCheck;

    meta = {
      description = "Base functions and types to work with OpenID Connect.";
      license = stdenv.lib.licenses.bsd3;
    };
  };

  oidc-client = buildDunePackage {
    pname = "oidc-client";
    version = "1.0.0-dev";

    src = lib.filterGitSource {
      src = ./..;
      dirs = [ "oidc-client" ];
      files = [ "dune-project" "oidc-client.opam" ];
    };

    useDune2 = true;

    propagatedBuildInputs = [
      oidc
      jose
      piaf
      uri
      yojson
      logs

      junit
      junit_alcotest
      alcotest
      odoc
      bisect_ppx
    ];

    inherit doCheck;

    meta = {
      description = "OpenID Connect Relaying Party implementation built ontop of Piaf.";
      license = stdenv.lib.licenses.bsd3;
    };
  };

  morph-oidc-client = buildDunePackage {
    pname = "morph-oidc-client";
    version = "1.0.0-dev";

    src = lib.filterGitSource {
      src = ./..;
      dirs = [ "executable" "library" ];
      files = [ "dune-project" "morph-oidc-client.opam" ];
    };

    useDune2 = true;

    propagatedBuildInputs = [
      reason
      tyxml
      tyxml-jsx
      tyxml-ppx
      archi
      archi-lwt
      fmt
      lwt
      routes
      uuidm
      oidc
      jose
      piaf
      uri
      yojson
      logs
      morph
      pkgs.gmp
    ];

    inherit doCheck;

    meta = {
      description = "OpenID Connect Relaying Party implementation built ontop of Piaf.";
      license = stdenv.lib.licenses.bsd3;
    };
  };

  hello_dream = buildDunePackage {
    pname = "hello";
    version = "1.0.0-dev";

    src = lib.filterGitSource {
      src = ./..;
      dirs = [ "hello" ];
      # files = [ ];
    };

    propagatedBuildInputs = [
      dream.dream
    ];

    inherit doCheck;

    meta = {
      description = "Base functions and types to work with OpenID Connect.";
      license = stdenv.lib.licenses.bsd3;
    };
  };
}
