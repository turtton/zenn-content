{
  description = "Corepack environment with a shell";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      treefmt-nix,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        corepack =
          with pkgs;
          stdenv.mkDerivation {
            name = "corepack";
            buildInputs = [ pkgs.nodejs-slim ];
            phases = [ "installPhase" ];
            installPhase = ''
              mkdir -p $out/bin
              corepack enable --install-directory=$out/bin
            '';
          };
      in
      {
        formatter = treefmt-nix.lib.mkWrapper pkgs {
          projectRootFile = "flake.nix";
          programs = {
            nixfmt.enable = true;
            mdformat = {
              enable = true;
              plugins = ps: [ ps.mdformat-frontmatter ];
            };
          };
        };
        devShells.default =
          with pkgs;
          mkShell {
            packages = [
              bashInteractive
              corepack
            ];
          };
      }
    );
}
