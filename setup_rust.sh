# TODO: Don't hard-code the x86_64 part
TOOLCHAINS="stable-x86_64-unknown-linux-gnu nightly-x86_64-unknown-linux-gnu"
TARGETS="i686-unknown-linux-musl arm-unknown-linux-gnueabi"
STABLE_TOOLS="rustfmt license cargo-deadlinks cargo-check cargo-modules cargo-outdated cargo-watch cargo-update cargo-edit cargo-tree cargo-graph"
UNSTABLE_TOOLS="clippy cargo-check"

# TODO: Make this conditional on rustup not being installed
curl https://sh.rustup.rs -sSf | sh

for TOOLCHAIN in $TOOLCHAINS; do
	rustup toolchain install "$TOOLCHAIN";

	# Add cross-compiling support
	for TARGET in $TARGETS; do
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
