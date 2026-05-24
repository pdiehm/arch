{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  outputs = { nixpkgs, ... }: let
    inherit (nixpkgs) lib;
    eachSystem = fn: lib.genAttrs lib.systems.flakeExposed (sys: fn nixpkgs.legacyPackages.${sys});
  in {
    packages = eachSystem (pkgs: {
      default = pkgs.writeShellApplication {
        name = "hello";
        text = "echo 'Hello, world!'";
      };
    });
  };
}
