
# Winamp

## About

Winamp is a multimedia player launched in 1997, iconic for its flexibility and wide compatibility with audio formats. Originally developed by Nullsoft, it gained massive popularity with still millions of users. Its development slowed down, but now, its source code was opened to the community, allowing developers to improve and modernize the player to meet current user needs.

It really whips the llama's ass.

## Usage

Building of the Winamp desktop client is currently based around Visual Studio 2019 (VS2019) and Intel IPP libs (You need to use exactly v6.1.1.035). There are different options of how to build Winamp:

1. Use the `build_winampAll_2019.cmd` script file that makes 4 versions x86/x64 (Debug and Release). In this case, Visual Studio IDE is not required.
2. Use the `winampAll_2019.sln` file to build and debug in Visual Studio IDE.

### Dependencies

#### libdiscid

We take libdiscid from https://github.com/metabrainz/libdiscid/tree/v0.6.2; the
build script clones it into `Dependencies\libdiscid-0.6.2` (previously
`/Src/external_dependencies/libdiscid-0.6.2/`).

#### libvpx

We take libvpx from [https://github.com/ShiftMediaProject/libvpx](https://github.com/ShiftMediaProject/libvpx), modify it, and pack it to archive.
Run `unpack_libvpx_v1.8.2_msvc16.cmd` to unpack.

#### libmpg123

We take libmpg123 from [https://www.mpg123.de/download.shtml](https://www.mpg123.de/download.shtml), modify it, and pack it to archive.
Run `unpack_libmpg123.cmd` to unpack and process the DLLs.

#### OpenSSL

You need to use `openssl-1.0.1u`. For that, you need to build a static version of these libs.
Run `build_vs_2019_openssl_x86.cmd` and `build_vs_2019_openssl_64.cmd`.

To build OpenSSL, you need to install:

- 7-Zip ([https://www.7-zip.org/](https://www.7-zip.org/)) – Licensed under the GNU LGPL.
- NASM ([https://www.nasm.us/](https://www.nasm.us/)) – Licensed under the 2-Clause BSD License.
- Perl ([https://www.perl.org/](https://www.perl.org/)) – Licensed under the Artistic License or GPL.

#### DirectX 9 SDK

We take DirectX 9 SDK (June 2010) from Microsoft, modify it, and pack it to archive.
Run `unpack_microsoft_directx_sdk_2010.cmd` to unpack it.

#### Microsoft ATLMFC lib fix

In file `C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Tools\MSVC\14.24.28314\atlmfc\include\atltransactionmanager.h`

Go to line 427 and change from:

```cpp
return ::DeleteFile((LPTSTR)lpFileName);
```

to:

```cpp
return DeleteFile((LPTSTR)lpFileName);
```

#### Intel IPP 6.1.1.035

We take Intel IPP 6.1.1.035, modify it, and pack it to archive.

Run `unpack_intel_ipp_6.1.1.035.cmd` to unpack it.

### Additional build dependencies

Everything that has to be downloaded or installed lives under the
`Dependencies\` folder at the repository root. That folder is not checked into
git; `build_with_vs2026.cmd` creates it automatically (see
[Building with Visual Studio 2026](#building-with-visual-studio-2026)). The
layout after setup:

| Path | Contents |
| --- | --- |
| `Dependencies\vcpkg\` | vcpkg checkout with the patched ports from `vcpkg-ports` and the prebuilt packages for both architectures |
| `Dependencies\Qt\5.15.2\msvc2019\` | Qt 5.15.2 Win32 kit (base + QtWebEngine) |
| `Dependencies\Qt\5.15.2\msvc2019_64\` | Qt 5.15.2 x64 kit (base + QtWebEngine) |
| `Dependencies\QtMsBuild\` | Qt VS Tools MSBuild targets (extracted from the official VSIX) |
| `Dependencies\libdiscid-0.6.2\` | libdiscid sources (generated `discid.h` included) |
| `Dependencies\libvpx_v1.8.2_msvc16\` | unpacked libvpx 1.8.2 import libraries/headers |
| `Dependencies\libmpg123\` | unpacked mpg123 1.25.13 runtime folders and generated import libraries |

The following sections describe each dependency, where it comes from and
which projects need it.

#### Qt and Qt VS Tools

`wac_network`, `wac_browser` and `wac_downloadManager` are included in the
repository, and their Visual Studio projects require a Qt 5.15.2 MSVC 2019 kit
named `5.15.2_msvc2019` plus the Qt VS Tools MSBuild targets.

- The Qt 5.15.2 SDK (Win32 `win32_msvc2019` base kit plus the `qtwebengine`
  module, and the x64 `win64_msvc2019_64` equivalent for 64-bit builds) is
  downloaded from the [Qt 5.15.2 win32_msvc2019 package
  archive](https://mirror.fi.ossplanet.net/qtproject/online/qtsdkrepository/windows_x86/desktop/qt5_5152/qt.qt5.5152.win32_msvc2019/)
  and unpacked under `Dependencies\Qt\5.15.2\msvc2019` (32-bit) and
  `Dependencies\Qt\5.15.2\msvc2019_64` (64-bit). The required modules are:
  - `wac_network`: Core, Network, Widgets, Concurrent (WebView for x64).
  - `wac_downloadManager`: Core, Network, Concurrent, WebEngine, and
    WebEngineWidgets.
- Qt VS Tools is not installed as a VS extension here; instead, the
  `QtMsBuild` MSBuild targets shipped inside the official
  [Qt VS Tools VSIX](https://marketplace.visualstudio.com/items?itemName=TheQtCompany.QtVisualStudioTools2022)
  are extracted to `Dependencies\QtMsBuild`. Command-line builds point the
  `QtMsBuild` environment variable at that folder.
- Kits are registered for the targets to find them under
  `HKEY_CURRENT_USER\Software\QtProject\QtVsTools\Versions\5.15.2_msvc2019`
  (and `..._msvc2019_64`) with an `InstallDir` value pointing at the two
  folders above. The Qt targets resolve the per-architecture kit from the
  shared `5.15.2_msvc2019` name automatically.

The stale `Qt\DLL_5.12_x86` runtime archives are no longer used. The Qt
runtime deployed next to `winamp.exe` is produced by `windeployqt` from the
registered Qt 5.15.2 kit as part of the `winampv6` post-build step.

#### vcpkg packages

The majority of third-party libraries (alac, expat, freetype, ijg-libjpeg,
libflac, libogg, libpng, libsndfile, libtheora, libvorbis, libvpx, minizip,
mp3lame, mpg123, openssl, pthread, restclient-cpp, spdlog, zlib) are consumed
through vcpkg in the `x86-windows-static-md` / `x64-windows-static-md`
triplets. The custom port overrides in `vcpkg-ports\` are copied over the
upstream port tree; the `freetype` port intentionally drops the `brotli`
default feature (brotli 1.2 changed its header layout and the old freetype
find-module cannot locate it), and the `spdlog` port was updated to the
upstream 1.17.0 port because spdlog 1.10 does not compile with current MSVC.

#### libdiscid 0.6.2

`in_cdda` compiles libdiscid sources directly. The sources are cloned from
[metabrainz/libdiscid tag v0.6.2](https://github.com/metabrainz/libdiscid/tree/v0.6.2)
into `Dependencies\libdiscid-0.6.2`; the CMake template
`include\discid\discid.h.in` is turned into `discid.h` (version 0.6.2, version
number 602) because the project builds the sources without running CMake.

#### libvpx 1.8.2 and mpg123 1.25.13

The modified prebuilt packages are shipped as archives in the repository
(`Src\winampAll\libvpx_v1.8.2_msvc16.7z`, `Src\winampAll\libmpg123.7z`) and
are unpacked into `Dependencies\` by the build script; the four
`libmpg123.lib` import libraries are generated from the shipped `.def` files
with `lib.exe`.

#### Chromium Embedded Framework (CEF)

`gen_ml` can use an unpacked CEF distribution at
`Src\\external_dependencies\\CEF`. The expected archive
`Src\\external_dependencies\\CEF.7z.001` is not stored in the repository;
the solution currently builds without it. The checked-in `cef_x86.bat`
targets CEF branch 5414, whose source is available
from [chromiumembedded/cef branch 5414](https://github.com/chromiumembedded/cef/tree/5414).
Use the [official CEF build instructions](https://chromiumembedded.github.io/cef/master_build_quick_start.html)
to build a compatible distribution (an official prebuilt standard distribution
of CEF 109.1.18 / Chromium 109.0.5414.120 for Windows 32-bit also matches that
branch). The legacy script's default Bitbucket CEF
URL is obsolete; use the GitHub source above instead.

#### Components not publicly downloadable

- `Src\vlb` (Dolby VLB decoder) was never part of the public source release,
  and redistributing its sources or binaries requires written permission from
  Winamp/Dolby. **VLB playback has therefore been removed from `in_mp3`**: the
  ADTS VLB decoder wrapper, the `.vlb` extension handling, and the
  `winampv6`/solution references to the missing `vlb` project are gone. AAC
  playback now relies solely on the `adts_aac` service component.
- `Src\Plugins\DSP\sc_serv3` is missing. SHOUTcast provides DNAS binaries,
  and its [software license](https://www.shoutcast.com/legal/agreements/dnas)
  does not authorize obtaining or modifying its source, so no source was used.
  The only helper `dsp_sc` needed from it (`stringUtil::toLower` /
  `stringUtil::stripAlphaDigit`) has been replaced by an independent,
  project-owned implementation in
  `Src\Plugins\DSP\dsp_sc\sc2srclib\stringUtils.h`, and the standalone
  `sc_serv` project entry was removed from the solution.
- Windows Mobile/DRM device plugins (`pmp_activesync`, `pmp_p4s`) depend on
  RAPI and Windows Media DRM libraries that Microsoft only ever shipped for
  32-bit Windows; they remain Win32-only, as do the VP5/VP6 codec cores
  (`vp5d`, `vp6d`, `dxv`, `dxv2`, `vputil`, `vppp`, `CPUIdLib`, `on2_mem`,
  `h264dec` and their `nsvdec_vp5`/`nsvdec_vp6`/`vp6`/`h264` consumers) and
  the EEL-scripted visualizations (`vis_milk2`, `vis_avs`, `dsp_sps`), whose
  hand-written MMX/inline-assembly code was never ported to x64. These are
  excluded from x64 solution builds.

### Build Tools

Several external build tools are required to build Winamp. These tools are not bundled directly into the repository to comply with their respective licenses. You will need to download them separately from the following links:

- **Visual Studio 2026** (or Visual Studio 2019 for the original
  `build_winampAll_2019.cmd` flow) with the C++ workload. The VS 2026 flow
  uses the v145 toolset; no MFC/ATL or Spectre-mitigated runtime component is
  required.  
  License: Microsoft license terms
- **7-Zip** (or NanaZip from the Microsoft Store): used to unpack the bundled
  `.7z` dependency archives and the Qt VS Tools VSIX.  
  Download from [https://www.7-zip.org/](https://www.7-zip.org/) - License: GNU LGPL
- **Git**: vcpkg/libdiscid clones and general source control.  
  Download from [https://git-scm.com/download/win](https://git-scm.com/download/win) - License: GNU GPL v2
- **Python 3** (optional, first setup only): used by `aqtinstall` to download
  the Qt kits automatically.  
  Download from [https://www.python.org/downloads/](https://www.python.org/downloads/) - License: PSF
- **TortoiseSVN**: only needed for the legacy mastering scripts.  
  Download from [https://tortoisesvn.net/downloads.html](https://tortoisesvn.net/downloads.html) - License: GNU GPL v2
- **NASM** and **Perl** (optional): only needed if you rebuild the static
  OpenSSL 1.0.1u libraries via `build_vs_2019_openssl_*.cmd`; the vcpkg
  openssl packages make this unnecessary for the standard build.

Make sure to install these tools as part of your build environment. You may need to modify the build scripts to reflect the correct paths to these tools on your system.

### Building with Visual Studio 2026

A single command builds everything, including all pre-compilation steps:

```bat
build_with_vs2026.cmd
```

This builds all four configurations (x86/x64, Debug/Release) with Visual
Studio 2026 and the v145 toolset. On first run it downloads and prepares every
dependency listed above (vcpkg and its packages, the Qt 5.15.2 kits, the Qt
VS Tools targets, libdiscid, libvpx and libmpg123) into `Dependencies\`; on
later runs each step is skipped when its output already exists. Partial builds
are supported:

```bat
build_with_vs2026.cmd x86           & rem x86 Debug + Release
build_with_vs2026.cmd x64           & rem x64 Debug + Release
build_with_vs2026.cmd x64 Release   & rem one configuration only
```

Compiler/linker settings applied by the script (no third-party code involved):

- The v145 toolset replaces the projects' pinned v142; Windows SDK 10.0.26100
  replaces the pinned 10.0.19041.
- `BuildTools\shim\afxres.h` (a `winres.h` wrapper) is prepended to
  `IncludePath` because 136 resource scripts include the MFC header
  `afxres.h` purely for standard resource macros.
- `VcpkgTriplet` is overridden to `x64-windows-static-md` for x64 builds
  because the projects pin the x86 triplet in every configuration.
- `SpectreMitigation=false` (the Spectre-mitigated runtime libraries are an
  optional VS component that is not installed) and `/utf-8` via `_CL_`
  (required by fmt 12, pulled in through spdlog).
- The Qt MSBuild targets are taken from `Dependencies\QtMsBuild` and the
  registered Qt 5.15.2 kits from `Dependencies\Qt`.

Each configuration writes an error summary to `build_<platform>_<config>.log`
at the repository root. The final binaries land in `Build\Winamp_<platform>_<config>\`
(`winamp.exe` plus plugins, system `.w5s` components, shared DLLs and the Qt
runtime deployed by `windeployqt`).
