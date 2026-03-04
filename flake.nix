# A collection of reusable Nix dev shells for Rust projects.
#
# USAGE (per-project .envrc or .env, no local flake.nix needed):
# > use flake <template>
#
# After adding .envrc, run: direnv allow
# direnv will automatically activate the shell whenever you cd into the project.
#
# WHY FENIX INSTEAD OF NIXPKGS RUST?
#   fenix tracks the official Rust release channels (stable/beta/nightly) and
#   provides a `withComponents` interface that lets you pick exactly what gets
#   installed. nixpkgs ships a single pinned Rust version that often lags behind.
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    # Rust toolchain manager — provides stable, beta, and nightly channels
    # with fine-grained component selection (cargo, clippy, rust-src, etc.)
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs"; # keeps fenix and nixpkgs in sync
    };
  };

  outputs = { fenix, nixpkgs, ... }:
  let
    pkgs = import nixpkgs { system = "x86_64-linux"; };
    # Shorthand for the fenix package set on this system
    rust = fenix.packages.x86_64-linux;
  in {
    devShells.x86_64-linux = {

      rust = pkgs.mkShell {
        packages = [
          (rust.complete.withComponents [ "cargo" "rustc" "rust-src" "rustfmt" "clippy" ])
          # rust-src is required by rust-analyzer for go-to-definition into std
          rust.stable.rust-analyzer  # LSP server for IDE integration

          pkgs.bacon        # Background cargo runner: re-runs check/test on save
          pkgs.cargo-deny   # Audit dependencies for license issues and advisories
          pkgs.cargo-expand # Expand proc-macros and derive attributes for inspection
          pkgs.cargo-udeps  # Find unused dependencies in Cargo.toml
        ];
      };

      rust-db = pkgs.mkShell {
        packages = [
          (rust.complete.withComponents [ "cargo" "rustc" "rust-src" "rustfmt" "clippy" ])
          rust.stable.rust-analyzer

          pkgs.bacon
          pkgs.cargo-deny
          pkgs.cargo-expand
          pkgs.cargo-udeps

          pkgs.sqlx-cli    # sqlx migrations + offline query caching (`cargo sqlx prepare`)
        ];
      };

      rust-nightly = pkgs.mkShell {
        packages = [
          (rust.complete.withComponents [ "cargo" "rustc" "rust-src" "rustfmt" "clippy" ])
          # Use nightly rust-analyzer for better inference on nightly-only constructs
          rust.nightly.rust-analyzer

          pkgs.bacon
          pkgs.cargo-deny
          pkgs.cargo-expand
          pkgs.cargo-udeps
        ];
      };

      rust-lib = pkgs.mkShell {
        packages = [
          (rust.complete.withComponents [ "cargo" "rustc" "rust-src" "rustfmt" "clippy" ])
          rust.stable.rust-analyzer

          pkgs.bacon
          pkgs.cargo-deny
          pkgs.cargo-expand
          pkgs.cargo-udeps
          pkgs.cargo-hack # Useful options for Cargo for testing and ci
          pkgs.cargo-semver-checks # Scan crates for semver violations
          pkgs.cargo-llvm-cov # Code coverage via LLVM source-based intrumentation
        ];
      };
    };
  };
}
