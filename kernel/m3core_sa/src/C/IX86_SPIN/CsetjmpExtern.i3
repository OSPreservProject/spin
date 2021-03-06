(*
 * Copyright 1994, University of Washington
 * All rights reserved.
 * See COPYRIGHT file for a full description
 *
 *
 * HISTORY
 * 13-Aug-96  Frederick Gray (fgray) at the University of Washington
 *	Created from Alpha version.
 *
 *)

UNSAFE INTERFACE CsetjmpExtern;

FROM Ctypes IMPORT int;
FROM Csetjmp IMPORT jmp_buf;

<*EXTERNAL*> PROCEDURE setjmp (VAR env: jmp_buf): int;
<*EXTERNAL*> PROCEDURE longjmp (VAR env: jmp_buf; val: int);

<*EXTERNAL "_setjmp" *>  PROCEDURE usetjmp (VAR env: jmp_buf): int;
<*EXTERNAL "_longjmp" *> PROCEDURE ulongjmp (VAR env: jmp_buf; val: int);

END CsetjmpExtern.
