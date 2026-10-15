{
  description = "Development environment for noq";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, rust-overlay, flake-utils, ... }:
    # Not `eachDefaultSystem`: nixpkgs dropped x86_64-darwin support in 26.11.
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-linux" "aarch64-darwin" ] (system:
      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs { inherit system overlays; };

        rustStable = pkgs.rust-bin.stable.latest.default.override {
          extensions = [ "rust-src" "rust-analyzer" "clippy" "rustfmt" ];
        };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            rustStable
            cargo-nextest
            cargo-make

            # Needed to build aws-lc-fips-sys (the `aws-lc-rs-fips` feature),
            # which `--all-features` and the cargo-make tasks pull in.
            cmake
            go
            perl
          ];

          # aws-lc-fips-sys builds C with `-O0 -Werror` in debug, which turns
          # glibc's "_FORTIFY_SOURCE requires compiling with optimization"
          # warning (from Nix's default hardening flags) into a hard error.
          hardeningDisable = [ "fortify" ];

          RUST_BACKTRACE = "1";
        };
      }
    );
}
