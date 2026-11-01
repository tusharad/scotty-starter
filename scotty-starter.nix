{ mkDerivation, aeson, base, blaze-html, blaze-markup, clay, lib, scotty
, text, wai-extra, wai-middleware-static
}:
mkDerivation {
  pname = "scotty-starter";
  version = "0.2.0.0";
  src = ./.;
  isLibrary = false;
  isExecutable = true;
  executableHaskellDepends = [
    aeson base blaze-html blaze-markup clay scotty text wai-extra
    wai-middleware-static
  ];
  homepage = "https://github.com/scotty-web/scotty-starter";
  description = "Starter kit project for Scotty web applications";
  license = lib.licenses.bsd3;
}
