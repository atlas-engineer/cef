# CEF

Binary distributions of Chromium Embedded Framework built with H.264 and AAC
(`proprietary_codecs=true`, `ffmpeg_branding=Chrome`). Nyxt's Linux packages
download the release archive.

The default build is CEF 150.0.22 (`c1a097e`), the commit Nyxt compiles against.
`patches/corner-radius.patch` and `patches/floating-overlays.patch` add
`CefBrowserView::SetCornerRadius`, `CefBrowserView::SetBackgroundBlur`,
`CefBrowserView::SetSafeAreaInsets`, `CefPanel::ClearLayout`, and
`CefPanel::SetViewportCutout` before the release archive is compiled.

Build the same archive on this machine with `scripts/build-linux.sh`. It runs
the workflow steps in an Ubuntu 24.04 container and publishes the release.
`scripts/build-macos.sh` builds the arm64 macOS archive the same way.

Run the `Linux` or `macOS` workflow from the Actions tab. They build Linux x64
and macOS arm64 and publish `cef_binary_<version>_linux64_minimal.tar.bz2` and
`cef_binary_<version>_macosarm64_minimal.tar.bz2` (with `.sha256` files) on a
release tagged with that version.

GitHub-hosted runners enforce a six-hour limit per job, and a full Chromium/CEF
compile takes longer than six hours. Each workflow chains up to eight time-boxed
compile jobs: before the limit, Siso flushes its build state on `SIGINT`, the
stage archives `out/` with `zstd`, and the next stage restores a deterministic
source tree and resumes from the latest saved checkpoint until `autoninja`
completes.
