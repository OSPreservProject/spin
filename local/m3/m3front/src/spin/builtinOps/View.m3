(* Copyright (C) 1992, Digital Equipment Corporation           *)
(* All rights reserved.                                        *)
(* See the file COPYRIGHT for a full description.              *)

(* File: Loophole.m3                                           *)
(* Last Modified On Tue May  3 16:36:31 PDT 1994 By kalsow     *)
(*      Modified On Sat Dec  8 00:57:40 1990 By muller         *)

(*
 * HISTORY
 * 25-Jan-97  Wilson Hsieh (whsieh) at the University of Washington
 *	move type Z out to interface, need it in CallExpr.IsGlobal
 *
 * 23-May-96  Wilson Hsieh (whsieh) at the University of Washington
 *	functional and bounded
 *
 * 31-Oct-95  Wilson Hsieh (whsieh) at the University of Washington
 *	most of the code copied from Loophole.m3
 *
 *)

MODULE View;

IMPORT CallExpr, Expr, ExprRep, Type, Procedure, ViewExpr;
IMPORT Int, TypeExpr, Error;

PROCEDURE TypeOf (ce: CallExpr.T): Type.T =
  VAR t: Type.T := Int.T;
  BEGIN
    IF TypeExpr.Split (ce.args[1], t) THEN (*ok*) END;
    RETURN t;
  END TypeOf;

PROCEDURE Check (ce: CallExpr.T;  VAR cs: Expr.CheckState) =
  VAR t: Type.T;
  BEGIN
    IF NOT TypeExpr.Split (ce.args[1], t) THEN
      Error.Msg ("VIEW: second argument must be a type");
      t := Int.T;
    END;
    ce.args[0] := ViewExpr.New (ce.args[0], t);
    Expr.TypeCheck (ce.args[0], cs);
    ce.type := t;
  END Check;

PROCEDURE NeedsAddress (ce: CallExpr.T) =
  BEGIN
    Expr.NeedsAddress (ce.args[0]);
  END NeedsAddress;

PROCEDURE Prep (ce: CallExpr.T) =
  BEGIN
    Expr.Prep (ce.args[0]);
  END Prep;

PROCEDURE Compile (ce: CallExpr.T) =
  BEGIN
    Expr.Compile (ce.args[0]);
  END Compile;

PROCEDURE PrepLV (ce: CallExpr.T) =
  BEGIN
    Expr.PrepLValue (ce.args[0]);
  END PrepLV;

PROCEDURE CompileLV (ce: CallExpr.T) =
  BEGIN
    Expr.CompileLValue (ce.args[0]);
  END CompileLV;

PROCEDURE IsWritable (ce: CallExpr.T): BOOLEAN =
  BEGIN
    RETURN Expr.IsWritable (ce.args[0]);
  END IsWritable;

PROCEDURE IsDesignator (ce: CallExpr.T): BOOLEAN =
  BEGIN
    RETURN Expr.IsDesignator (ce.args[0]);
  END IsDesignator;

PROCEDURE NoteWrites (ce: CallExpr.T) =
  BEGIN
    Expr.NoteWrite (ce.args[0]);
  END NoteWrites;

PROCEDURE Initialize () =
  BEGIN
    Z := CallExpr.NewMethodList (2, 2, TRUE, FALSE, TRUE, NIL,
                                 TypeOf,
                                 NeedsAddress,
                                 Check,
                                 Prep,
                                 Compile,
                                 PrepLV,
                                 CompileLV,
                                 CallExpr.PrepNoBranch,
                                 CallExpr.NoBranch,
                                 CallExpr.NoValue, (*fold*)
                                 IsWritable,
                                 IsDesignator,
                                 NoteWrites);
    Procedure.Define ("VIEW", Z, TRUE,
                      isBounded := TRUE,
                      isFunctional := TRUE);
  END Initialize;

BEGIN
END View.
