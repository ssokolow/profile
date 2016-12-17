#!/bin/sh

STABLE_TOOLS="rustfmt license cargo-deadlinks cargo-check cargo-modules cargo-outdated cargo-watch cargo-update cargo-edit cargo-tree cargo-graph"
ARCH="$(uname -p)"
TOOLCHAINS="stable-${ARCH}-unknown-linux-gnu nightly-${ARCH}-unknown-linux-gnu"
EXTRA_TARGETS="i686-unknown-linux-musl arm-unknown-linux-gnueabi"
UNSTABLE_TOOLS="clippy cargo-check"

is_installed() { type "$1" 1>/dev/null 2>&1; return $?; }

if ! is_installed rustup; then
	curl https://sh.rustup.rs -sSf | sh
fi

for TOOLCHAIN in $TOOLCHAINS; do
	rustup toolchain install "$TOOLCHAIN";

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

# See also: https://pyra-handheld.com/boards/threads/how-to-cross-compile-rust-programs.78650/#post-1398907
