//
//  precomp.h
//  nu
//

#include "foundation/error.h"
#include "foundation/types.h"
#include "foundation/atomics.h"

#include <stdlib.h>
#include <stddef.h>
#include <string.h>

#ifdef _WIN32
#include <windows.h>
#else
#include <pthread.h>
#endif //WIN32
