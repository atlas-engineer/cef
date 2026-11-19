#!/bin/bash
set -euxo pipefail

export GN_DEFINES="is_official_build=true proprietary_codecs=true ffmpeg_branding=Chrome use_thin_lto=false is_cfi=false chrome_pgo_phase=false symbol_level=0 blink_symbol_level=0"
export CEF_ARCHIVE_FORMAT=tar.bz2
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends \
  build-essential \
  ca-certificates \
  curl \
  file \
  git \
  lsb-release \
  patch \
  pkg-config \
  python-is-python3 \
  python3 \
  sudo \
  unzip \
  wget \
  xz-utils
printf 'root ALL=(ALL) NOPASSWD:ALL\n' > /etc/sudoers.d/root
chmod 440 /etc/sudoers.d/root
df -h /cef-build

if [[ ! -f /cef-build/automate-git.py ]]; then
  curl -fsSL -o /cef-build/automate-git.py \
    https://raw.githubusercontent.com/chromiumembedded/cef/c1a097eaa7738483abe2ea9d6297a937d6a884c0/tools/automate/automate-git.py
fi

export PATH="/cef-build/depot_tools:${PATH}"
python3 /cef-build/automate-git.py \
  --download-dir=/cef-build \
  --depot-tools-dir=/cef-build/depot_tools \
  --branch=7871 \
  --checkout=c1a097eaa7738483abe2ea9d6297a937d6a884c0 \
  --no-chromium-history \
  --no-debug-build \
  --no-build \
  --no-distrib \
  --x64-build \
  --build-target=cefsimple
df -h /cef-build

if ! patch -d /cef-build/chromium/src/cef -p1 --forward --batch \
  < /cef-repo/patches/corner-radius.patch; then
  grep -q SetCornerRadius \
    /cef-build/chromium/src/cef/include/views/cef_browser_view.h
fi
python3 /cef-build/chromium/src/cef/tools/version_manager.py -c --force-update

cd /cef-build/chromium/src
./build/install-build-deps.sh --no-chromeos-fonts --no-nacl --no-prompt
apt-get install -y --no-install-recommends \
  libpipewire-0.3-dev \
  libx11-xcb-dev

python3 /cef-build/automate-git.py \
  --download-dir=/cef-build \
  --depot-tools-dir=/cef-build/depot_tools \
  --branch=7871 \
  --checkout=c1a097eaa7738483abe2ea9d6297a937d6a884c0 \
  --no-chromium-history \
  --no-update \
  --no-depot-tools-update \
  --force-build \
  --force-distrib \
  --no-debug-build \
  --minimal-distrib \
  --x64-build \
  --build-target=cefsimple
df -h /cef-build

lib=$(find /cef-build/chromium/src/out -type f -name libcef.so | head -1)
test -n "$lib"
nm "$lib" | grep -q ' ff_h264_decoder$'
nm "$lib" | grep -q ' ff_aac_decoder$'
nm "$lib" | grep -q 'SetCornerRadius'
