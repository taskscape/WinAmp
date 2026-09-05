// Shim for building without the MFC component installed: resource scripts
// include afxres.h only for standard Windows resource macros, which winres.h
// (part of the Windows SDK) provides. Add this directory to INCLUDE when
// running MSBuild on machines without MFC/ATL.
#include <winres.h>
