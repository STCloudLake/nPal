#!/bin/sh
# Build nPal for TI-Nspire OS 5.x/6.x (CX II) with Ndless r2022.
# The resulting Zehn executable uses the native lcd_blit screen API
# (genzehn auto-detects it), so it is NOT run in Ndless "compatibility mode".
#
# Requirements: ndless-sdk (tools built: genzehn, zehn_loader, libndls.a,
# libsyscalls.a, libnspireio.a, system/crt*.o) + arm-none-eabi toolchain.
#
# Usage:
#   NDLESS_SDK=/path/to/ndless-sdk ./build-wsl.sh
#   NDLESS_SDK=/path/to/ndless-sdk ./build-wsl.sh clean
set -e

: "${NDLESS_SDK:?set NDLESS_SDK to the ndless-sdk directory}"

export PATH="$NDLESS_SDK/bin:$PATH"

if [ -z "$_NDLESS_TOOLCHAIN_PATH" ]; then
    _NDLESS_TOOLCHAIN_PATH="$(dirname "$(command -v arm-none-eabi-gcc)")"
    export _NDLESS_TOOLCHAIN_PATH
fi

exec make -f Makefile.OS64 "$@"
