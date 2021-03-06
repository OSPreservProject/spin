(* Copyright (C) 1992, Digital Equipment Corporation           *)
(* All rights reserved.                                        *)
(* See the file COPYRIGHT for a full description.              *)

(* File: DerefExpr.m3                                          *)
(* Last modified on Fri Feb 24 07:43:48 PST 1995 by kalsow     *)
(*      modified on Thu Nov 29 06:04:10 1990 by muller         *)

(* HISTORY
 * 09-Feb-97  Wilson Hsieh (whsieh) at the University of Washington
 *	globalness is more precise
 *
 * 19-Sep-96  Wilson Hsieh (whsieh) at the University of Washington
 *	x^ is always global
 *
 * 29-Jul-96  Charles Garrett (garrett) at the University of Washington
 *	Added Is predicate.
 *
 *)

MODULE DerefExpr;

IMPORT M3;
IMPORT Expr, ExprRep, RefType, Error, Type;
IMPORT NilChkExpr, CG, ErrType;

TYPE
  P = ExprRep.Ta BRANDED "DerefExpr.P" OBJECT
      OVERRIDES
        typeOf       := TypeOf;
        check        := Check;
        need_addr    := NeedsAddress;
        prep         := Prep;
        compile      := Compile;
        prepLV       := Prep;
        compileLV    := CompileLV;
        prepBR       := ExprRep.PrepNoBranch;
        compileBR    := ExprRep.NoBranch;
        evaluate     := ExprRep.NoValue;
        isEqual      := ExprRep.EqCheckA;
        getBounds    := ExprRep.NoBounds;
        isWritable   := ExprRep.IsAlways;
        isDesignator := ExprRep.IsAlways;
	isZeroes     := ExprRep.IsNever;
	genFPLiteral := ExprRep.NoFPLiteral;
	prepLiteral  := ExprRep.NoPrepLiteral;
	genLiteral   := ExprRep.NoLiteral;
        note_write   := NoteWrites;
        global       := IsGlobal;
      END;

PROCEDURE New (a: Expr.T): Expr.T =
  VAR p: P;
  BEGIN
    p := NEW (P);
    ExprRep.Init (p);
    p.a := NilChkExpr.New (a);
    p.origin := p.a.origin;
    RETURN p;
  END New;

PROCEDURE Is (e: Expr.T): BOOLEAN =
  BEGIN
    TYPECASE e OF
    | NULL => RETURN FALSE;
    | P    => RETURN TRUE;
    ELSE      RETURN FALSE;
    END;
  END Is;

PROCEDURE SetOffset (e: Expr.T; n: INTEGER) =
  BEGIN
    TYPECASE e OF
    | NULL => (* nothing *)
    | P(p) => NilChkExpr.SetOffset (p.a, n);
    ELSE      (* nothing *)
    END;
  END SetOffset;

PROCEDURE TypeOf (p: P): Type.T =
  VAR ta, target: Type.T;
  BEGIN
    ta := Expr.TypeOf (p.a);
    IF RefType.Split (ta, target)
      THEN RETURN target;
      ELSE RETURN ErrType.T;
    END;
  END TypeOf;

PROCEDURE Check (p: P;  VAR cs: Expr.CheckState) =
  VAR ta, target: Type.T;
  BEGIN
    Expr.TypeCheck (p.a, cs);
    ta := Type.Base (Expr.TypeOf (p.a));
    target := NIL;
    IF (ta = ErrType.T) THEN
      (* already an error, don't generate any more *)
      target := ErrType.T;
    ELSIF NOT RefType.Split (ta, target) THEN
      Error.Msg ("cannot dereference a non-REF value");
      target := ErrType.T;
    ELSIF (target = NIL) THEN
      Error.Msg ("cannot dereference REFANY, ADDRESS, or NULL");
      target := ErrType.T;
    END;
    p.type := target;
  END Check;

PROCEDURE NeedsAddress (<*UNUSED*> p: P) =
  BEGIN
    (* ok *)
  END NeedsAddress;

PROCEDURE Prep (p: P) =
  BEGIN
    Expr.Prep (p.a);
  END Prep;

PROCEDURE Compile (p: P) =
  VAR t := p.type;  info: Type.Info;
  BEGIN
    Expr.Compile (p.a);
    EVAL Type.CheckInfo (t, info);
    CG.Force ();  (*'cause alignment applies to the referent, not the pointer*)
    CG.Boost_alignment (info.alignment);
    Type.LoadScalar (t);
  END Compile;

PROCEDURE CompileLV (p: P) =
  VAR info: Type.Info;
  BEGIN
    Expr.Compile (p.a);
    EVAL Type.CheckInfo (p.type, info);
    CG.Force ();  (* alignment applies to the referent, not the pointer*)
    CG.Boost_alignment (info.alignment);
  END CompileLV;

PROCEDURE NoteWrites (p: P) =
  BEGIN
    Expr.NoteWrite (p.a);
  END NoteWrites;

PROCEDURE IsGlobal (<* UNUSED *> p: P): M3.Global =
  BEGIN
    RETURN M3.Global.Yes;
  END IsGlobal;

BEGIN
END DerefExpr.
