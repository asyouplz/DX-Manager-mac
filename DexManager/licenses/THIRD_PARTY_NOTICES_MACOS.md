# DX Manager for macOS - Third-Party Notices

DX Manager is an independently developed utility. The macOS portable packages
include the components listed below from official project sources or archives.
Packaging applies ad-hoc macOS signatures to the DX Manager executables and to
a third-party executable only when it does not already have a valid signature.
This changes signing metadata, not program code. Those components remain
under their own licenses; the DX Manager MIT License does not replace or alter
those licenses.

## .NET Runtime

The self-contained DX Manager and ADB proxy executables include Microsoft .NET
Runtime 8.0.30 components. .NET Runtime is licensed under the MIT License.
The package includes `dotnet-LICENSE.txt` and the matching
`dotnet-THIRD-PARTY-NOTICES.txt` from the official `dotnet/runtime` v8.0.30
source tag.

Official source: https://github.com/dotnet/runtime/tree/v8.0.30

## DX Manager loopback DeX helper (ScrcpyDeX-derived)

`tools/loopback/dxm-loopback.jar` is used only by the experimental Hide phone
preview mode. Its Samsung loopback wireless DeX configuration and WFD
negotiation are adapted from ScrcpyDeX
(https://github.com/Aureliano021/ScrcpyDex, commit
3e58823000a897300df5cf2c6d4a131d97b28162). Copyright 2026 Aureliano Peixoto
and ScrcpyDeX Contributors. Licensed under the Apache License, Version 2.0;
see `tools/loopback/LICENSE`, `tools/loopback/NOTICE`, and the copies
`dxm-loopback-LICENSE.txt` / `dxm-loopback-NOTICE.txt` in the license
directory. Source and the reproducible build script are in `DXLoopback/` and
`scripts/Build-DexLoopback.sh` of the source repository.

## scrcpy

The package includes the official static scrcpy 4.1 archive for the selected
Mac processor architecture. scrcpy and scrcpy-server are licensed under the
Apache License, Version 2.0. The complete license supplied by the official
archive is retained in `tools/scrcpy/LICENSE` and is also provided as
`scrcpy-LICENSE.txt` in the package license directory.

Copyright (C) 2018 Genymobile

Copyright (C) 2018-2026 Romain Vimont

Official project: https://github.com/Genymobile/scrcpy

## Android Debug Bridge (ADB)

The official scrcpy macOS archive includes an Android Debug Bridge binary from
Android SDK Platform-Tools. ADB source is distributed under the Apache License,
Version 2.0.

Official source: https://android.googlesource.com/platform/packages/modules/adb/

Platform-Tools information: https://developer.android.com/tools/releases/platform-tools

## Libraries linked into the static scrcpy client

The official scrcpy 4.1 macOS build links libraries including SDL 3.4.12,
FFmpeg 8.1.2, libusb 1.0.30, dav1d 1.5.3, and zlib. The package provides the
applicable LGPL 2.1, SDL/zlib, dav1d BSD 2-Clause, and zlib license texts in its
`licenses` directory. Source and build information is available from:

- https://github.com/Genymobile/scrcpy/blob/v4.1/release/build_macos.sh
- https://ffmpeg.org/
- https://github.com/libsdl-org/SDL/tree/release-3.4.12
- https://github.com/libusb/libusb/tree/v1.0.30
- https://code.videolan.org/videolan/dav1d
- https://zlib.net/

## Samsung DeX trademark notice

DX Manager works with features provided by Samsung DeX on compatible Samsung
devices. DX Manager is not affiliated with, sponsored by, endorsed by, or
distributed by Samsung Electronics or Genymobile.

Samsung and Samsung DeX are trademarks of Samsung Electronics Co., Ltd. All
trademarks are the property of their respective owners.
