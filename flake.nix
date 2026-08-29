{
  description = "transformers: version-bumped ahead of nixpkgs through a Python package overlay.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    flake-lib = {
      url = "github:jgus/flake-lib/v1";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
    tokenizers = {
      url = "github:jgus/tokenizers-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
      inputs.flake-lib.follows = "flake-lib";
    };
  };

  outputs = { nixpkgs, flake-utils, flake-lib, tokenizers, ... }:
    let
      pin = import ./pin.nix;
      inherit (pin) version hash;
      source = { type = "pypi"; pname = "transformers"; format = "sdist"; };
      transformersOverlay = final: prev: {
        pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
          (pyfinal: pyprev: {
            transformers = pyprev.transformers.overridePythonAttrs (_: {
              inherit version;
              doCheck = false;
              src = pyfinal.fetchPypi { inherit version hash; pname = "transformers"; };
            });
          })
        ];
      };
      overlay = nixpkgs.lib.composeManyExtensions [
        tokenizers.overlays.default
        transformersOverlay
      ];
    in
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ overlay ];
          };
        in
        {
          packages = {
            transformers = pkgs.python3.pkgs.transformers;
            default = pkgs.python3.pkgs.transformers;
            update-version = flake-lib.lib.mkUpdateVersion {
              inherit pkgs source;
              buildAttr = "transformers";
              siblings = [
                {
                  reqName = "tokenizers";
                  pypiName = "tokenizers";
                  flakeRepo = "jgus/tokenizers-flake";
                  mode = "resolve";
                }
              ];
              siblingRefsInPin = true;
            };
            update-branches = flake-lib.lib.mkUpdateBranches {
              inherit pkgs source;
              pinSchema = "pypi";
            };
          };
        }) // {
      overlays.default = overlay;
    };
}
