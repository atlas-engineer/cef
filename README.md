# CEF

Binary distributions of Chromium Embedded Framework built with H.264 and AAC
(`proprietary_codecs=true`, `ffmpeg_branding=Chrome`). Nyxt's Linux packages
download the release archive.

The default build is CEF 150.0.22 (`c1a097e`), the commit Nyxt compiles against.

Run the Build workflow from the Actions tab. It publishes
`cef_binary_<version>_linux64_minimal.tar.bz2` and a `.sha256` file on a
release tagged with that version.

The job checks out Chromium and compiles it. A GitHub-hosted runner gets the
disk that can be reclaimed and a six-hour limit.
