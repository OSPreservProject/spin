/* Definitions of target machine for GNU compiler, for HP PA-RISC 1.1
   Copyright (C) 1991 Free Software Foundation, Inc.
   Contributed by Tim Moore (moore@defmacro.cs.utah.edu)

This file is part of GNU CC.

GNU CC is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

GNU CC is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with GNU CC; see the file COPYING.  If not, write to
the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.  */

#define TARGET_DEFAULT 0x89	/* TARGET_SNAKE + TARGET_GAS
				   + TARGET_JUMP_IN_DELAY */

#include "pa/pa.h"
#undef CPP_PREDEFINES
#define CPP_PREDEFINES "-Dhppa -Dunix -Dhp9000 -Dspectrum -DREVARGV -Dhp700 -DHP700 -Dparisc -D__pa_risc -DPARISC -DBYTE_MSF -DBIT_MSF -Asystem(unix) -Asystem(mach) -Acpu(hppa) -Amachine(hppa)"

/* Don't default to pcc-struct-return, because gcc is the only compiler, and
   we want to retain compatibility with older gcc versions.  */
#define DEFAULT_PCC_STRUCT_RETURN 0

/* OSF1 on the PA still uses 16bit wchar_t.  */
#undef WCHAR_TYPE
#undef WCHAR_TYPE_SIZE

#define WCHAR_TYPE "short unsigned int"
#define WCHAR_TYPE_SIZE 16

/* OSF1 wants to be different and use unsigned long as size_t.  */
#undef SIZE_TYPE
#define SIZE_TYPE "long unsigned int"
