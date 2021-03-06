/* Print instructions for the Motorola 88000, for GDB and GNU Binutils.
   Copyright 1986, 1987, 1988, 1989, 1990, 1991, 1993
   Free Software Foundation, Inc.

This file is part of GDB and the GNU Binutils.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.  */

#include "defs.h"
#include "dis-asm.h"

/* Print the m88k instruction at address MEMADDR in debugged memory,
   on STREAM.  Returns length of the instruction, in bytes, which
   is always 4.  */

int
print_insn (memaddr, stream)
     CORE_ADDR memaddr;
     GDB_FILE *stream;
{
  disassemble_info info;

  GDB_INIT_DISASSEMBLE_INFO (info, stream);

  /* print_insn_m88k is in opcodes/m88k-dis.c.  */
  return print_insn_m88k ((bfd_vma) memaddr, &info);
}
