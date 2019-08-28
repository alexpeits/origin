{ mkDerivation,
  stdenv,

  lib,
  markdown-unlit,

  base,

  aeson,
  barbies,
  bytestring,
  directory,
  higgledy,
  optparse-applicative,
  split,
  text,
  yaml
}:
mkDerivation {
  pname = "harg";
  version = "0.1.3.0";
  src = lib.sourceByRegex ./. [
    "src(.*)?"
    "test(.*)?"
    "Example.hs"
    "README.lhs"
    "README.md"
    "harg.cabal"
    "LICENSE"
  ];
  isLibrary = true;
  libraryHaskellDepends = [
    base

    aeson
    barbies
    bytestring
    directory
    higgledy
    optparse-applicative
    text
    split
    yaml
  ];
  testHaskellDepends = [
    base

    barbies
    higgledy
    optparse-applicative
  ];
  testToolDepends = [ markdown-unlit ];
  homepage = "https://github.com/alexpeits/harg#readme";
  license = stdenv.lib.licenses.bsd3;
}
