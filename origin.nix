{ mkDerivation, barbies, base, higgledy, hpack, lib
, optparse-applicative, stdenv, validation
}:
mkDerivation {
  pname = "origin";
  version = "0.1.0.0";
  src = lib.sourceByRegex ./. [
    "app(.*)?"
    "src(.*)?"
    "test(.*)?"
    "Example.hs"
    "origin.cabal"
    "package.yaml"
  ];
  isLibrary = true;
  isExecutable = true;
  libraryHaskellDepends = [
    barbies base higgledy optparse-applicative validation
  ];
  libraryToolDepends = [ hpack ];
  executableHaskellDepends = [
    barbies base higgledy optparse-applicative validation
  ];
  testHaskellDepends = [
    barbies base higgledy optparse-applicative validation
  ];
  preConfigure = "hpack";
  homepage = "https://github.com/alexpeits/origin#readme";
  license = stdenv.lib.licenses.bsd3;
}