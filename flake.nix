{
  description = "Project Acrithis";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    fenix.url = "github:nix-community/fenix";
    flake-utils.url = "github:numtide/flake-utils";

    lean4-nix.url = "github:lenianiva/lean4-nix";
    lean4-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      fenix,
      flake-utils,
      lean4-nix,
    }:
    flake-utils.lib.eachDefaultSystem (system: {
      devShells.default =
        let
          pkgs = import nixpkgs {
            inherit system;

            overlays = [
              (lean4-nix.readToolchainFile ./lean-toolchain)
            ];
          };
        in
        pkgs.mkShell {
          buildInputs =
            let
              rustToolchain = fenix.packages.${system}.complete.toolchain;
            in
            with pkgs;
            [
              # rust
              rustToolchain

              # lean4
              lean.lean-all
              lean-lsp-mcp
              elan

              # gleam
              gleam

              # nodejs
              nodejs_latest

              # go
              go
              delve
              golangci-lint
              golangci-lint-langserver

              # nix
              nixfmt

              # containerization
              docker

              # nu
              nushell

              # build
              just
              just-formatter
              just-lsp
            ];

          shellHook = ''
            echo "sup"
          '';
        };
    });
}
