#!/bin/sh

ARCH="$(uname -p)"
TOOLCHAINS="stable-${ARCH}-unknown-linux-gnu nightly-${ARCH}-unknown-linux-gnu"
EXTRA_TARGETS="i686-unknown-linux-musl arm-unknown-linux-gnueabi"
STABLE_TOOLS="rustfmt license cargo-deadlinks cargo-outdated cargo-watch"
STABLE_TOOLS="$STABLE_TOOLS cargo-modules cargo-edit cargo-tree"
STABLE_TOOLS="$STABLE_TOOLS cargo-check cargo-update cargo-graph"
UNSTABLE_TOOLS="clippy cargo-check"

is_installed() { type "$1" 1>/dev/null 2>&1; return $?; }

if ! is_installed rustup; then
	curl https://sh.rustup.rs -sSf | sh
fi

for TOOLCHAIN in $TOOLCHAINS; do
	rustup toolchain install "$TOOLCHAIN"

	# Add cross-compiling support
	for TARGET in $EXTRA_TARGETS; do
		rustup target add --toolchain "$TOOLCHAIN" "$TARGET"
	done
done

for CRATE in $STABLE_TOOLS; do
	cargo install "$CRATE"
done

for CRATE in $UNSTABLE_TOOLS; do
	rustup run nightly cargo install "$CRATE"
done

# Install ripgrep with all optimizations my current development machine suppors
# TODO: Figure out how to make it conditional on an update being present
RUSTFLAGS="-C target-cpu=native" rustup run nightly cargo install -f ripgrep --features 'simd-accel'

# See also: https://pyra-handheld.com/boards/threads/how-to-cross-compile-rust-programs.78650/#post-1398907
