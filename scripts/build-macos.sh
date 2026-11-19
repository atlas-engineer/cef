#!/bin/bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
build_dir=${CEF_BUILD_DIR:-"$HOME/Source/C++/cef-build"}
mkdir -p "$build_dir"

export GN_DEFINES="is_official_build=true proprietary_codecs=true ffmpeg_branding=Chrome use_thin_lto=false is_cfi=false chrome_pgo_phase=false symbol_level=0 blink_symbol_level=0 use_clang_modules=false"
export CEF_ARCHIVE_FORMAT=tar.bz2

if ! xcodebuild -version >/dev/null 2>&1; then
  echo "Full Xcode is required. Command Line Tools are installed, and Xcode.app is not." >&2
fi

if [[ ! -f "$build_dir/automate-git.py" ]]; then
  curl -fsSL -o "$build_dir/automate-git.py" \
    https://raw.githubusercontent.com/chromiumembedded/cef/c1a097eaa7738483abe2ea9d6297a937d6a884c0/tools/automate/automate-git.py
fi

export PATH="$build_dir/depot_tools:${PATH}"
python3 "$build_dir/automate-git.py" \
  --download-dir="$build_dir" \
  --depot-tools-dir="$build_dir/depot_tools" \
  --branch=7871 \
  --checkout=c1a097eaa7738483abe2ea9d6297a937d6a884c0 \
  --no-chromium-history \
  --no-debug-build \
  --no-build \
  --no-distrib \
  --arm64-build \
  --build-target=cefsimple
df -h "$build_dir"

if [[ ! -f "$build_dir/depot_tools/python3_bin_reldir.txt" ]]; then
  env -u DEPOT_TOOLS_UPDATE "$build_dir/depot_tools/ensure_bootstrap"
fi
export DEPOT_TOOLS_UPDATE=0

if ! patch -d "$build_dir/chromium/src/cef" -p1 --forward --batch \
  < "$root/patches/corner-radius.patch"; then
  grep -q SetCornerRadius \
    "$build_dir/chromium/src/cef/include/views/cef_browser_view.h"
fi
python3 "$build_dir/chromium/src/cef/tools/version_manager.py" -c --force-update

if [[ "$(sysctl -n hw.memsize)" -le 8589934592 ]]; then
  export NINJA_CORE_LIMIT=3
fi

python3 "$build_dir/automate-git.py" \
  --download-dir="$build_dir" \
  --depot-tools-dir="$build_dir/depot_tools" \
  --branch=7871 \
  --checkout=c1a097eaa7738483abe2ea9d6297a937d6a884c0 \
  --no-chromium-history \
  --no-update \
  --no-depot-tools-update \
  --force-build \
  --force-distrib \
  --no-debug-build \
  --minimal-distrib \
  --arm64-build \
  --build-target=cefsimple
df -h "$build_dir"

dist="$build_dir/chromium/src/cef/binary_distrib"
tarball=$(echo "$dist"/cef_binary_*_macosarm64_minimal.tar.bz2)
test -f "$tarball"
base=$(basename "$tarball" .tar.bz2)
version=${base#cef_binary_}
version=${version%_macosarm64_minimal}
(
  cd "$dist"
  shasum -a 256 "$(basename "$tarball")" > "$(basename "$tarball").sha256"
)
notes=$(cat <<EOF
CEF ${version} for macOS arm64, built with proprietary_codecs and ffmpeg_branding=Chrome from c1a097eaa7738483abe2ea9d6297a937d6a884c0.

Adds CefBrowserView::SetCornerRadius. The radius clips the hosted web content so the view background shows in the corners.
EOF
)
if gh release view "$version" --repo atlas-engineer/cef >/dev/null 2>&1; then
  gh release upload "$version" --repo atlas-engineer/cef --clobber \
    "$tarball" "$tarball.sha256"
else
  gh release create "$version" --repo atlas-engineer/cef \
    --title "CEF ${version}" \
    --notes "$notes" \
    "$tarball" "$tarball.sha256"
fi
echo "Published ${version}"
