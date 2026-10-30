with import <nixpkgs> { };
mkShell {
  packages = [ hello ];

  shellHook = ''
    hello
  '';
}
