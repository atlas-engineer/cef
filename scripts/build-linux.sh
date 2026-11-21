#!/bin/bash
set -euo pipefail

root=$(cd "$(dirname "$0")/.." && pwd)
build_dir=${CEF_BUILD_DIR:-"$HOME/Source/C++/cef-build"}
mkdir -p "$build_dir"

docker pull ubuntu:24.04
docker rm -f cef-linux-build >/dev/null 2>&1 || true
docker run --name cef-linux-build --rm \
  -v "$build_dir:/cef-build" \
  -v "$root:/cef-repo:ro" \
  ubuntu:24.04 \
  bash /cef-repo/scripts/build-linux-inner.sh

dist="$build_dir/chromium/src/cef/binary_distrib"
tarball=$(echo "$dist"/cef_binary_*_linux64_minimal.tar.bz2)
test -f "$tarball"
base=$(basename "$tarball" .tar.bz2)
version=${base#cef_binary_}
version=${version%_linux64_minimal}
(
  cd "$dist"
  sha256sum "$(basename "$tarball")" > "$(basename "$tarball").sha256"
)
notes=$(cat <<EOF
CEF ${version}, built with proprietary_codecs and ffmpeg_branding=Chrome from c1a097eaa7738483abe2ea9d6297a937d6a884c0.

Adds CefBrowserView::SetCornerRadius, CefBrowserView::SetBackgroundBlur, CefBrowserView::SetSafeAreaInsets, CefPanel::ClearLayout, and CefPanel::SetViewportCutout.
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
