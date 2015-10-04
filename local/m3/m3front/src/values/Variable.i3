(* Copyright (C) 1992, Digital Equipment Corporation           *)
(* All rights reserved.                                        *)
(* See the file COPYRIGHT for a full description.              *)
(*                                                             *)
(* File: Variable.i3                                           *)
(* Last Modified On Tue Dec 20 15:08:50 PST 1994 By kalsow     *)
(*      Modified On Fri Apr 27 03:11:00 1990 By muller         *)

(*
 * HISTORY
 * 09-Feb-97  Wilson Hsieh (whsieh) at the University of Washington
 *	globalness is more precise
 *
 * 24-May-96  Wilson Hsieh (whsieh) at the University of Washington
 *	add IsGlobal
 *      make Split return BOOLEAN
 *
 *)

INTERFACE Variable;

IMPORT M3, M3ID, Type, Value,  Scope, Decl, Target, CG, Tracer;

TYPE
  T <: Value.T;

PROCEDURE ParseDecl (READONLY att: Decl.Attributes);

PROCEDURE New (name: M3ID.T;  used: BOOLEAN): T;
(* does not insert the object into any scope.... *)

PROCEDURE NewFormal (formal: Value.T;  name: M3ID.T): T;

PROCEDURE BindType (t: T;  type: Type.T;
                    indirect, readonly, open_array_ok, needs_init: BOOLEAN;
                    global_alias: M3.Global := M3.Global.No);

PROCEDURE Split (t: Value.T;  VAR type: Type.T;
                 VAR indirect, readonly: BOOLEAN)
            : BOOLEAN;

PROCEDURE IsFormal   (t: T): BOOLEAN;
PROCEDURE IsGlobal   (t: T): M3.Global;
PROCEDURE HasClosure (t: T): BOOLEAN;

PROCEDURE NeedsAddress (t: T);

PROCEDURE SetBounds (t: T;  READONLY min, max: Target.Int);
PROCEDURE GetBounds (t: T;  VAR min, max: Target.Int);

PROCEDURE Load       (t: T);
PROCEDURE LoadLValue (t: T);
PROCEDURE SetLValue  (t: T);

PROCEDURE CGName (t: T;  VAR unit: CG.Var;  VAR offset: INTEGER);
(* return the back-end address of the variable. *)

PROCEDURE NeedGlobalInit (t: T): BOOLEAN;
PROCEDURE InitGlobal (t: T);

PROCEDURE GenGlobalMap (s: Scope.T): INTEGER;

PROCEDURE ParseTrace (): Tracer.T;
PROCEDURE BindTrace  (t: T;  x: Tracer.T);
PROCEDURE CheckTrace (x: Tracer.T;  VAR cs: Value.CheckState);
PROCEDURE ScheduleTrace (t: T);

END Variable.
