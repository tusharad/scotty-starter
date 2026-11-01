{ pkgs ? import <nixpkgs> {} }:
let
  hp = pkgs.haskellPackages;
  pkg = hp.callCabal2nix "scotty-starter" ./. {};
in
hp.shellFor {
  packages = p: [ pkg ];
  withHoogle = true;
  nativeBuildInputs = [
    hp.cabal-install
    hp.ghc
    hp.haskell-language-server
    hp.fourmolu
    hp.hlint
    hp.ghcid
  ];
}
