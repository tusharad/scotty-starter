{
  description = "Modern starter kit for Scotty web applications in Haskell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        hp = pkgs.haskellPackages;
        scottyStarterPkg = hp.callCabal2nix "scotty-starter" ./. {};
      in
      {
        packages.default = scottyStarterPkg;

        devShells.default = hp.shellFor {
          packages = p: [ scottyStarterPkg ];
          withHoogle = true;
          nativeBuildInputs = [
            hp.cabal-install
            hp.ghc
            hp.haskell-language-server
            hp.fourmolu
            hp.hlint
            hp.ghcid
          ];
        };
      }
    );
}

