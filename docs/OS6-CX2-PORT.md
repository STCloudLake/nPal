# OS 6.x / CX II port notes

This branch makes nPal target **TI-Nspire CX II (OS 5.x/6.x) with Ndless r2022**
instead of the original Ndless 3.x-era PRG format.

## Symptom

Running the original `sdlpal.tns` (built 2016-05-02) on a CX II with Ndless r2022
shows a dialog before the game starts:

> **Ndless** — Activating compatibility mode.
> This application hasn't been updated to work with your hardware.
> You may run into weird issues!

## Root cause

The message comes from Ndless' LCD compatibility layer
(`ndless/src/resources/lcd_compat.c`, `lcd_compat_enable()`), which is enabled when
the loaded executable does not advertise support for the HW-W 240x320 panel:

```c
// ndless/src/resources/ploaderhook.c
bool supports_hww = false;      // default
...
if (!supports_hww)
    lcd_compat_enable();        // shows the dialog
```

`supports_hww` is only set from the `RUNS_ON_HWW` flag of a **Zehn** executable.
The 2016 `sdlpal.tns` starts with `PRG\0` (legacy PRG container) and contains no
Zehn header at all, so Ndless takes the legacy PRG loading path, has no flag table
to read, and `supports_hww` stays `false`.

## Fix

Build with the current Ndless SDK (r2022) and emit a plain Zehn `.tns`:

* the SDK's nSDL (`libSDL.a`, 1.1.1) renders through the new **`lcd_blit`** API;
* `genzehn` detects the `_genzehn_new_lcd_api` marker and writes
  `USES_LCD_BLIT = 1` and `RUNS_ON_HWW = 1`;
* Ndless then skips compatibility mode and the OS rotates the 240x320 panel natively.

Changes:

| file | change |
|---|---|
| `Makefile.OS64` | OS 5.x/6.x target, plain Zehn output (no `make-prg`), `--240x320-support true` |
| `build-wsl.sh` | reproducible build helper for WSL/Linux |
| `touchpad.c/h` | GBK comments converted to UTF-8 (modern ARM GCC rejects non-UTF-8 sources) |

The game code itself is untouched; save format and the resource files from the
nPal 1.2 release are unchanged.

## Build

```sh
# Ndless SDK, with tools built once:
#   make -C tools/genzehn && make -C libndls && make -C libsyscalls && \
#   make -C system && make -C thirdparty/nspire-io lib
export NDLESS_SDK=/path/to/ndless-sdk
./build-wsl.sh            # -> sdlpal.tns
```

Build notes:

* `libsyscalls/stdlib.cpp` needs `-DPATH_MAX=4096` (newlib does not expose
  `PATH_MAX` with `-std=c++11`).
* `Makefile.OS64` passes `-Wno-error=implicit-function-declaration` because some
  old sources rely on implicit declarations, which GCC >= 14 rejects by default.
* With distributions' newlib (e.g. Ubuntu `gcc-arm-none-eabi` 13), the linker may
  need a weak `_fini` stub; the official Ndless toolchain does not.

## Verification

Tested in Firebird (WebAssembly) with an emulated CX II CAS:

* OS 6.4.0.74, Ndless r2022 installed through `ndless_installer_cx2.tns`;
* `resources.bin.tns`, `desc.dat.tns` and the new `sdlpal.tns` placed in
  `/documents/npal/`;
* no compatibility dialog, title screen, dialogues, walking, status menu and item
  menu all render and respond correctly.

Build output: `sdlpal.tns`, 419,248 bytes,
MD5 `EC6C333C777E5F98585C233E42D31DE8`
(official Ndless SDK toolchain: GCC 14.2 + binutils 2.44 + newlib 4.5).
