(* Copyright (C) 1990, Digital Equipment Corporation           *)
(* All rights reserved.                                        *)
(* See the file COPYRIGHT for a full description.              *)
(*                                                             *)
(* Last modified on Fri Nov 18 17:40:10 PST 1994 by kalsow     *)
(*      modified on Mon Mar 11 23:31:37 1991 by muller         *)
(*							       *)

(* HISTORY						       
 * 5-Sep-96  Przemek Pardyak (pardy) at the University of Washington
 *	Change ResumeRaise to be able to clean-up the exception stack
 *	(execute the TRY-FINALLY handlers) even if no exception handler
 *	will be executed.  Original code crashes the runtime if no handler
 *	is present.  Our code only kills the thread, but the accumulated
 *	TRY-FINALLY handlers should be executed.
 *
 * 01-Oct-95  Brian Bershad (bershad) at the University of Washington
 *	Manipulate implicit exceptions.
 *)

UNSAFE INTERFACE RTException;

(* This interface provides access to the runtime machinery that
   raises exceptions.  The values of the types defined in this
   interface are generated by the compiler.  Changing any of the
   types below is dangerous. *)

TYPE
  ExceptionName = UNTRACED REF UNTRACED REF (*ARRAY OF*) CHAR;
  ExceptionList = UNTRACED REF (*ARRAY OF*) ExceptionName;
  ExceptionArg  = ADDRESS; (* actually, it's an untyped 4-byte field *)

PROCEDURE Raise (ex: ExceptionName;  arg: ExceptionArg) RAISES ANY;
(* raise the exception ex passing arg as the associated value *)

PROCEDURE ResumeRaise (en: ExceptionName;  arg: ExceptionArg;
                       crash: BOOLEAN := TRUE) RAISES ANY;
(* Execute TRY-FINALLY handlers and restart the processing of the execption. 
   If "crash" is TRUE, it is known that there is a handler for this 
   exception and it will be executed. If it is FALSE, it is known that 
   there is no such handler and only the TRY-FINALLY handlers will be
   executed *)

PROCEDURE DumpStack ();
(* If possible, produce a diagnostic stack dump on stderr *)

PROCEDURE NoteImplicitException(ex: ExceptionName; enable: BOOLEAN);
(* Inform the runtime that the named exception can be passed out of a procedure
 * despite not being listed in the RAISES clause.  *)


PROCEDURE NoHandler(en: ExceptionName; 
                    arg: ExceptionArg; raises : BOOLEAN := TRUE);

PROCEDURE Init(); (* SPIN - mainbody init moved here and is
			run directly by RTLinker *)
END RTException.

