# CEF

Binary distributions of Chromium Embedded Framework built with H.264 and AAC
(`proprietary_codecs=true`, `ffmpeg_branding=Chrome`). Nyxt's Linux packages
download the release archive.

The default build is CEF 150.0.22 (`c1a097e`), the commit Nyxt compiles against.
`patches/corner-radius.patch` adds `CefBrowserView::SetCornerRadius` before
the release archive is compiled.

Build the same archive on this machine with `scripts/build-linux.sh`. It runs
the workflow steps in an Ubuntu 24.04 container and publishes the release.

Run the Build workflow from the Actions tab. It publishes
`cef_binary_<version>_linux64_minimal.tar.bz2` and a `.sha256` file on a
release tagged with that version.

The job checks out Chromium and compiles it. It deletes the runner's
preinstalled toolchains first so the build and package installs share one disk.
A GitHub-hosted runner has a six-hour limit.
