#!/bin/bash

set -ex

# See https://github.com/conda-forge/rust-feedstock/blob/master/recipe/build.sh for cc env explanation
if [ "$c_compiler" = gcc ] ; then
    case "$target_platform" in
        linux-64) rust_env_arch=X86_64_UNKNOWN_LINUX_GNU ;;
        linux-aarch64) rust_env_arch=AARCH64_UNKNOWN_LINUX_GNU ;;
        linux-ppc64le) rust_env_arch=POWERPC64LE_UNKNOWN_LINUX_GNU ;;
        *) echo "unknown target_platform $target_platform" ; exit 1 ;;
    esac

    export CARGO_TARGET_${rust_env_arch}_LINKER=$CC
fi

declare -a _xtra_maturin_args

mkdir -p "$SRC_DIR/.cargo"

if [ "$target_platform" = "osx-64" ] ; then
    cat <<EOF >> "$SRC_DIR/.cargo/config.toml"
[target.x86_64-apple-darwin]
linker = "$CC"
rustflags = [
  "-C", "link-arg=-undefined",
  "-C", "link-arg=dynamic_lookup",
]

EOF

    _xtra_maturin_args+=(--target=x86_64-apple-darwin)
elif [ "$target_platform" = "osx-arm64" ] ; then
    cat <<EOF >> "$SRC_DIR/.cargo/config.toml"
# Required for intermediate codegen stuff
[target.x86_64-apple-darwin]
linker = "$CC_FOR_BUILD"

# Required for final binary artifacts for target
[target.aarch64-apple-darwin]
linker = "$CC"
rustflags = [
  "-C", "link-arg=-undefined",
  "-C", "link-arg=dynamic_lookup",
]

EOF
    _xtra_maturin_args+=(--target=aarch64-apple-darwin)

    export PYO3_CROSS_LIB_DIR="$PREFIX/lib"
    export PYO3_PYTHON_VERSION="${PY_VER}"

    sed -i.bak 's,aarch64,arm64,g' "$BUILD_PREFIX/venv/lib/os-patch.py"
    sed -i.bak 's,aarch64,arm64,g' "$BUILD_PREFIX/venv/lib/platform-patch.py"
fi

cargo-bundle-licenses --format yaml --output THIRDPARTY.yml

maturin build -vv -j "${CPU_COUNT}" --release --strip --manylinux off --interpreter="${PYTHON}" "${_xtra_maturin_args[@]}"

"${PYTHON}" -m pip install "$SRC_DIR"/target/wheels/py_svg_hush*.whl --no-deps -vv
