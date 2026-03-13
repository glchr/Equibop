{
  description = "Equibop packaged for NixOS";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        packages = {
          default = pkgs.callPackage ./nix/package.nix { src = self; };
          equibop = pkgs.callPackage ./nix/package.nix { src = self; };
        };
      }
    )
    // {
      overlays.default = final: _prev: {
        equibop = final.callPackage ./nix/package.nix { src = self; };
      };
    };
}
