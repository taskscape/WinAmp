@echo off
setlocal EnableExtensions
rem ============================================================================
rem build_with_vs2026.cmd - single-command build for the Winamp desktop client
rem
rem Usage:
rem   build_with_vs2026.cmd                      build all 4 configurations
rem                                              (x86/x64, Debug/Release)
rem   build_with_vs2026.cmd x86                  build x86 Debug + Release
rem   build_with_vs2026.cmd x64                  build x64 Debug + Release
rem   build_with_vs2026.cmd x86 Debug            build one configuration
rem
rem The script performs every pre-compilation step itself (idempotent - each
rem step is skipped when its output already exists):
rem   1. locate Visual Studio 2026 (v145 toolset) via vswhere
rem   2. create the afxres.h resource-compiler shim (MFC is not installed)
rem   3. set up vcpkg under Dependencies\vcpkg (clone, bootstrap, patch ports,
rem      install all required packages, MSBuild integration)
rem   4. download the Qt 5.15.2 MSVC2019 kits (x86 + x64, incl. QtWebEngine)
rem      into Dependencies\Qt and register them for the Qt targets
rem   5. fetch the Qt VS Tools MSBuild targets into Dependencies\QtMsBuild
rem   6. unpack libvpx/libmpg123 into Dependencies and build the libmpg123
rem      import libraries
rem   7. clone libdiscid 0.6.2 into Dependencies and generate discid.h
rem   8. run MSBuild for the selected configuration(s)
rem ============================================================================

set "WINAMP_ROOT=%~dp0"
if "%WINAMP_ROOT:~-1%"=="\" set "WINAMP_ROOT=%WINAMP_ROOT:~0,-1%"
set "DEPS=%WINAMP_ROOT%\Dependencies"
set "SHIM=%WINAMP_ROOT%\BuildTools\shim"
set "VCPKG=%DEPS%\vcpkg"

rem ---------------------------- tweakable settings ---------------------------
set "QT_VERSION=5.15.2"
set "QT_MIRROR=https://mirror.fi.ossplanet.net/qtproject/"
set "QTVSTOOLS_VSIX_URL=https://marketplace.visualstudio.com/_apis/public/gallery/publishers/TheQtCompany/vsextensions/QtVisualStudioTools2022/3.5.0/vspackage"
set "SDK_VERSION=10.0.26100.0"
set "TOOLSET=v145"
set "LIBDISCID_URL=https://github.com/metabrainz/libdiscid.git"

echo [0/8] Resolving tools...
rem ----------------------------- locate 7-Zip --------------------------------
set "SEVENZIP="
if exist "%ProgramFiles%\7-Zip\7z.exe" set "SEVENZIP=%ProgramFiles%\7-Zip\7z.exe"
if not defined SEVENZIP if exist "%ProgramFiles(x86)%\7-Zip\7z.exe" set "SEVENZIP=%ProgramFiles(x86)%\7-Zip\7z.exe"
if not defined SEVENZIP set "SEVENZIP=%LOCALAPPDATA%\Microsoft\WindowsApps\7z.exe"
if not exist "%SEVENZIP%" (
	echo ERROR: 7-Zip not found. Install it from https://www.7-zip.org/ ^(or NanaZip^).
	exit /b 1
)
echo        7-Zip: %SEVENZIP%

rem ------------------------- locate Visual Studio 2026 -----------------------
set "VSROOT="
for /f "usebackq tokens=*" %%i in (`"%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath 2^>nul`) do set "VSROOT=%%i"
if not defined VSROOT (
	echo ERROR: Visual Studio with C++ tools not found via vswhere.
	exit /b 1
)
echo        Visual Studio: %VSROOT%

rem -------------------- step 1: afxres.h shim (no MFC) -----------------------
echo [1/8] Resource-compiler shim (afxres.h)...
if not exist "%SHIM%" mkdir "%SHIM%"
if not exist "%SHIM%\afxres.h" (
	>  "%SHIM%\afxres.h"  echo // Shim for building without the MFC component installed: resource scripts
	>> "%SHIM%\afxres.h"  echo // include afxres.h only for standard Windows resource macros, which winres.h
	>> "%SHIM%\afxres.h"  echo // ^(Windows SDK^) provides. The build script prepends this directory to
	>> "%SHIM%\afxres.h"  echo // IncludePath when running MSBuild.
	>> "%SHIM%\afxres.h"  echo #include ^<winres.h^>
)
echo        shim: %SHIM%\afxres.h

rem ------------------- step 2: vcpkg + packages + integration ----------------
echo [2/8] vcpkg dependencies...
if not exist "%VCPKG%\vcpkg.exe" (
	echo        cloning vcpkg...
	if not exist "%VCPKG%" git clone https://github.com/microsoft/vcpkg.git "%VCPKG%" || exit /b 1
)
if not exist "%VCPKG%\installed\x86-windows-static-md\include\spdlog\spdlog.h" (
	echo        bootstrapping vcpkg...
	call "%VCPKG%\bootstrap-vcpkg.bat" -disableMetrics || exit /b 1
)
echo        patching ports from vcpkg-ports...
xcopy "%WINAMP_ROOT%\vcpkg-ports\*" "%VCPKG%\ports\" /E /Y /I /Q >nul
if not exist "%VCPKG%\installed\x86-windows-static-md\include\spdlog\spdlog.h" (
	echo        installing vcpkg packages ^(this is a long step on first run^)...
	pushd "%VCPKG%"
	"%VCPKG%\vcpkg.exe" install "alac:x86-windows-static-md" "expat:x86-windows-static-md" "expat:x86-windows-static" "freetype:x86-windows-static-md" "ijg-libjpeg:x86-windows-static-md" "libflac:x86-windows-static-md" "libogg:x86-windows-static-md" "libpng:x86-windows-static-md" "libsndfile:x86-windows-static-md" "libtheora:x86-windows-static-md" "libvorbis:x86-windows-static-md" "libvpx:x86-windows-static-md" "minizip:x86-windows-static-md" "mp3lame:x86-windows-static-md" "mpg123:x86-windows-static-md" "openssl:x86-windows-static-md" "openssl:x86-windows-static" "pthread:x86-windows-static-md" "pthread:x86-windows-static" "restclient-cpp:x86-windows-static-md" "restclient-cpp:x86-windows-static" "spdlog:x86-windows-static-md" "zlib:x86-windows-static-md" "zlib:x86-windows-static" || (popd & exit /b 1)
	"%VCPKG%\vcpkg.exe" install "alac:x64-windows-static-md" "expat:x64-windows-static-md" "expat:x64-windows-static" "freetype:x64-windows-static-md" "ijg-libjpeg:x64-windows-static-md" "libflac:x64-windows-static-md" "libogg:x64-windows-static-md" "libpng:x64-windows-static-md" "libsndfile:x64-windows-static-md" "libtheora:x64-windows-static-md" "libvorbis:x64-windows-static-md" "libvpx:x64-windows-static-md" "minizip:x64-windows-static-md" "mp3lame:x64-windows-static-md" "mpg123:x64-windows-static-md" "openssl:x64-windows-static-md" "openssl:x64-windows-static" "pthread:x64-windows-static-md" "pthread:x64-windows-static" "restclient-cpp:x64-windows-static-md" "restclient-cpp:x64-windows-static" "spdlog:x64-windows-static-md" "zlib:x64-windows-static-md" "zlib:x64-windows-static" || (popd & exit /b 1)
	popd
) else (
	echo        packages already installed
)
"%VCPKG%\vcpkg.exe" integrate install >nul || exit /b 1
echo        vcpkg ready: %VCPKG%

rem --------------------- step 3: Qt 5.15.2 kits ------------------------------
echo [3/8] Qt %QT_VERSION% kits...
if not exist "%DEPS%\Qt\%QT_VERSION%\msvc2019\bin\qmake.exe" (
	echo        downloading Qt %QT_VERSION% win32_msvc2019 + qtwebengine...
	py -3 -m pip install --quiet aqtinstall || exit /b 1
	py -3 -m aqt install-qt -O "%DEPS%\Qt" -b %QT_MIRROR% windows desktop %QT_VERSION% win32_msvc2019 -m qtwebengine || exit /b 1
) else (
	echo        x86 kit present
)
if not exist "%DEPS%\Qt\%QT_VERSION%\msvc2019_64\bin\qmake.exe" (
	echo        downloading Qt %QT_VERSION% win64_msvc2019_64 + qtwebengine...
	py -3 -m aqt install-qt -O "%DEPS%\Qt" -b %QT_MIRROR% windows desktop %QT_VERSION% win64_msvc2019_64 -m qtwebengine || exit /b 1
) else (
	echo        x64 kit present
)
reg add "HKCU\Software\QtProject\QtVsTools\Versions\%QT_VERSION%_msvc2019"    /v InstallDir /t REG_SZ /d "%DEPS%\Qt\%QT_VERSION%\msvc2019"    /f >nul
reg add "HKCU\Software\QtProject\QtVsTools\Versions\%QT_VERSION%_msvc2019_64" /v InstallDir /t REG_SZ /d "%DEPS%\Qt\%QT_VERSION%\msvc2019_64" /f >nul
echo        kits registered under HKCU\Software\QtProject\QtVsTools\Versions

rem ----------------- step 4: Qt VS Tools MSBuild targets ---------------------
echo [4/8] Qt VS Tools MSBuild targets...
if not exist "%DEPS%\QtMsBuild\Qt.props" (
	echo        fetching Qt VS Tools VSIX...
	powershell -NoProfile -ExecutionPolicy Bypass -Command "try { [IO.File]::WriteAllBytes('%TEMP%\qtvstools.vsix', (Invoke-WebRequest -Uri '%QTVSTOOLS_VSIX_URL%' -UseBasicParsing).Content) } catch { exit 1 }" || exit /b 1
	"%SEVENZIP%" x -y -o"%TEMP%\qtvsix_extract" "%TEMP%\qtvstools.vsix" QtMSBuild\* >nul || exit /b 1
	robocopy "%TEMP%\qtvsix_extract\QtMSBuild" "%DEPS%\QtMsBuild" /E /NFL /NDL /NJH /NJS >nul
	if errorlevel 8 exit /b 1
	del "%TEMP%\qtvstools.vsix" 2>nul
)
echo        targets: %DEPS%\QtMsBuild

rem ---------------- step 5: libvpx / libmpg123 unpack ------------------------
echo [5/8] libvpx / libmpg123...
if not exist "%DEPS%\libvpx_v1.8.2_msvc16" (
	"%SEVENZIP%" x -y -o"%DEPS%\" "%WINAMP_ROOT%\Src\winampAll\libvpx_v1.8.2_msvc16.7z" >nul || exit /b 1
)
if not exist "%DEPS%\libmpg123" (
	"%SEVENZIP%" x -y -o"%DEPS%\" "%WINAMP_ROOT%\Src\winampAll\libmpg123.7z" >nul || exit /b 1
)
echo        unpacked under %DEPS%

rem ------------------- step 6: libdiscid 0.6.2 -------------------------------
echo [6/8] libdiscid 0.6.2...
if not exist "%DEPS%\libdiscid-0.6.2\src\disc.c" (
	git clone --branch v0.6.2 --depth 1 %LIBDISCID_URL% "%DEPS%\libdiscid-0.6.2" || exit /b 1
)
if not exist "%DEPS%\libdiscid-0.6.2\include\discid\discid.h" (
	powershell -NoProfile -ExecutionPolicy Bypass -Command "$h = [IO.File]::ReadAllText('%DEPS%\libdiscid-0.6.2\include\discid\discid.h.in'); $h = $h.Replace('@libdiscid_MAJOR@','0').Replace('@libdiscid_MINOR@','6').Replace('@libdiscid_PATCH@','2').Replace('@libdiscid_VERSION_NUM@','602'); [IO.File]::WriteAllText('%DEPS%\libdiscid-0.6.2\include\discid\discid.h', $h)"
)
echo        ready: %DEPS%\libdiscid-0.6.2

rem ------------------- set up the compiler environment ----------------------
echo [7/8] Compiler environment...
rem Find the newest installed MSVC toolset include directory.
set "MSVC_INC="
for /f "delims=" %%D in ('dir /b /ad /o-n "%VSROOT%\VC\Tools\MSVC"') do if not defined MSVC_INC set "MSVC_INC=%%D"
set "MSVC_INC=%VSROOT%\VC\Tools\MSVC\%MSVC_INC%\include"
if not exist "%MSVC_INC%" (
	echo ERROR: MSVC include directory not found under %VSROOT%\VC\Tools\MSVC
	exit /b 1
)
if not exist "%ProgramFiles(x86)%\Windows Kits\10\Include\%SDK_VERSION%\um" (
	for /f "delims=" %%D in ('dir /b /ad /o-n "%ProgramFiles(x86)%\Windows Kits\10\Include"') do if exist "%ProgramFiles(x86)%\Windows Kits\10\Include\%%D\um" set "SDK_VERSION=%%D"
)
call "%VSROOT%\Common7\Tools\VsDevCmd.bat" -arch=x64 -host_arch=x64
if errorlevel 1 exit /b 1
rem fmt 12 (pulled in by spdlog) requires /utf-8 when its Unicode support is on;
rem _CL_ appends the flag to every cl.exe invocation made by MSBuild.
set "_CL_=/utf-8"
rem The afxres.h shim must come first so rc.exe/cl.exe resolve it before the
rem toolset directories (which do not contain MFC on this installation).
set "INCLUDE_ARG=%SHIM%;%MSVC_INC%;%ProgramFiles(x86)%\Windows Kits\10\Include\%SDK_VERSION%\shared;%ProgramFiles(x86)%\Windows Kits\10\Include\%SDK_VERSION%\um;%ProgramFiles(x86)%\Windows Kits\10\Include\%SDK_VERSION%\winrt;%ProgramFiles(x86)%\Windows Kits\10\Include\%SDK_VERSION%\cppwinrt;%ProgramFiles(x86)%\Windows Kits\10\Include\%SDK_VERSION%\ucrt"
rem Qt VS Tools MSBuild targets
set "QtMsBuild=%DEPS%\QtMsBuild"
echo        MSVC include: %MSVC_INC%
echo        SDK:          %SDK_VERSION%

rem ------------- step 7: libmpg123 import libraries (needs lib.exe) ----------
echo        libmpg123 import libraries...
call :mklib mpg123-1.25.13-x86-debug   X86
call :mklib mpg123-1.25.13-x86-release X86
call :mklib mpg123-1.25.13-x64-debug   X64
call :mklib mpg123-1.25.13-x64-release X64

rem --------------------------- step 8: build --------------------------------
echo [8/8] Building...
set "FAILED="
set "PLATFORMS="
set "CONFIGS="
if "%~1"==""          (set "PLATFORMS=Win32 x64" & set "CONFIGS=Debug Release")
if /i "%~1"=="x86"    (set "PLATFORMS=Win32"     & set "CONFIGS=Debug Release")
if /i "%~1"=="x64"    (set "PLATFORMS=x64"       & set "CONFIGS=Debug Release")
if /i "%~2"=="Debug"   (set "CONFIGS=Debug")
if /i "%~2"=="Release" (set "CONFIGS=Release")

for %%P in (%PLATFORMS%) do for %%C in (%CONFIGS%) do call :buildone %%C %%P
if defined FAILED (
	echo BUILD FAILED for: %FAILED%
	exit /b 1
)
echo.
echo ALL BUILDS SUCCEEDED.
exit /b 0

rem =========================== subroutines ===================================

:mklib
rem %1 = mpg123 folder name, %2 = MACHINE (X86|X64)
if not exist "%DEPS%\libmpg123\%~1\libmpg123.lib" (
	pushd "%DEPS%\libmpg123\%~1"
	lib /DEF:libmpg123.def /OUT:libmpg123.lib /MACHINE:%~2 >nul
	popd
)
exit /b 0

:buildone
rem %1 = Configuration, %2 = Platform
set "TRIPLET=x86-windows-static-md"
if /i "%~2"=="x64" set "TRIPLET=x64-windows-static-md"
set "LOGNAME=build_%~2_%~1"
echo.
echo ==========================================================================
echo  Building %~1 ^| %~2  ^(log: %LOGNAME%.log^)
echo ==========================================================================
msbuild "%WINAMP_ROOT%\winampAll_2019.sln" /t:Build /p:Configuration=%~1 /p:Platform=%~2 /p:PlatformToolset=%TOOLSET% /p:WindowsTargetPlatformVersion=%SDK_VERSION% /p:VcpkgTriplet=%TRIPLET% /p:SpectreMitigation=false /p:IncludePath="%INCLUDE_ARG%" /m /v:m /nologo /flp:LogFile=%WINAMP_ROOT%\%LOGNAME%.log;ErrorsOnly;Summary
if errorlevel 1 (
	echo ... %~1 ^| %~2 FAILED - see %LOGNAME%.log
	set "FAILED=%FAILED% %~1/%~2"
) else (
	echo ... %~1 ^| %~2 OK
)
exit /b 0
