#!/usr/bin/env bash

# This is a wrapper script around `rustc`, which passes custom arguments to rustc.
#
# Normally, custom rustc arguments would be configured by setting the `rustflags` key in
# `.cargo/config.toml`, but that key is overridden by the `RUSTFLAGS` env var, which is set *inside*
# the `cross` Docker container for AArch64, so we unfortunately need this custom rustc wrapper.
#
# To make matters worse, it is not possible to override `rustc` only for a specific target, so we
# have to make sure that we *only* pass the custom arguments when the compilation target is AArch64.
#
# Ideally, `rustflags` from `.cargo/config` and the `RUSTFLAGS` env var would be merged, which is
# tracked in this Cargo issue: https://github.com/rust-lang/cargo/issues/5376

set -e

self=$(dirname "$0")

libstdcxx_path="/usr/local/aarch64-linux-musl/lib"
linker="$self/wrap-ld.sh"

# We don't get passed the target in any env var, so we'd have to parse cli args and look for the
# `--target` flag :(
target=""
args=()
for arg in "$@"; do
    # FIXME: --target=bla is valid too, but we don't handle that

    if [[ "$target" == "next" ]]; then
        target="$arg"
    fi

    if [[ "$arg" == "--target" ]]; then
        target="next"
    fi

    args+=("$arg")
done

if [[ "$target" == "aarch64-unknown-linux-musl" ]]; then
    # building for AArch64
    export RUST_MUSL_LINKER=aarch64-linux-musl-ld
    export RUST_MUSL_LIBGCC=/usr/local/lib/gcc/aarch64-linux-musl/6.4.0
    # Pass `-Clinker` last to override the previous `-Clinker`.
    rustc "-Lnative=$libstdcxx_path" "-Lnative=$RUST_MUSL_LIBGCC" "$@" "-Clinker=$linker"
else
    rustc "$@"
fi
