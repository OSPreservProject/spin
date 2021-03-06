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

UNSAFE MODULE Csetjmp;
IMPORT CsetjmpExtern;
FROM Ctypes IMPORT int;

PROCEDURE setjmp (VAR env: jmp_buf): int =
  BEGIN
    RETURN CsetjmpExtern.setjmp(env);
  END setjmp;

PROCEDURE longjmp (VAR env: jmp_buf; val: int) =
  BEGIN
    CsetjmpExtern.longjmp(env, val);
  END longjmp;


PROCEDURE usetjmp (VAR env: jmp_buf): int =
  BEGIN
    RETURN CsetjmpExtern.usetjmp(env);
  END usetjmp;

PROCEDURE ulongjmp (VAR env: jmp_buf; val: int) =
  BEGIN
    CsetjmpExtern.ulongjmp(env, val);
  END ulongjmp;

BEGIN
END Csetjmp.
