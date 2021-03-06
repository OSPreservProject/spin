(* Copyright (C) 1992, Digital Equipment Corporation           *)
(* All rights reserved.                                        *)
(* See the file COPYRIGHT for a full description.              *)

(* File: Inc.m3                                                *)
(* Last Modified On Wed Jun 29 17:01:22 PDT 1994 By kalsow     *)
(*      Modified On Tue Apr  2 03:47:06 1991 By muller         *)

(*
 * HISTORY
 * 23-May-96  Wilson Hsieh (whsieh) at the University of Washington
 *	functional and bounded
 *
 *)

MODULE Inc;

IMPORT CG, CallExpr, Expr, Type, Procedure, Dec, Target, TInt;
IMPORT IntegerExpr, Host;
IMPORT Error, Fmt;

VAR Z: CallExpr.MethodList;

PROCEDURE Check (ce: CallExpr.T;  VAR cs: Expr.CheckState) =
  BEGIN
    Dec.DoCheck ("INC", ce, cs);
  END Check;

PROCEDURE Prep (ce: CallExpr.T) =
  BEGIN
    Expr.PrepLValue (ce.args[0]);
    IF (NUMBER (ce.args^) > 1) THEN Expr.Prep (ce.args[1]); END;
  END Prep;

PROCEDURE Compile (ce: CallExpr.T) =
  VAR
    lhs    := ce.args[0];
    tlhs   := Expr.TypeOf (lhs);
    info   : Type.Info;
    inc    : Expr.T;
    check  : [0..3] := 0;
    lvalue : CG.Val;
    bmin, bmax, imin, imax: Target.Int;
  BEGIN
    tlhs := Type.CheckInfo (tlhs, info);
    IF (NUMBER (ce.args^) > 1)
      THEN inc := ce.args[1];
      ELSE inc := IntegerExpr.New (TInt.One);  Expr.Prep (inc);
    END;
    Expr.GetBounds (lhs, bmin, bmax);
    Expr.GetBounds (inc, imin, imax);

    IF Host.doRangeChk THEN
      IF NOT TInt.EQ (bmin, Target.Integer.min)
         AND TInt.LT (imin, TInt.Zero) THEN INC (check) END;
      IF NOT TInt.EQ (bmax, Target.Integer.max)
         AND TInt.LT (TInt.Zero, imax) THEN INC (check, 2) END;
    END;

    Expr.CompileLValue (lhs);
    lvalue := CG.Pop ();
    CG.Push (lvalue);

    CG.Push (lvalue);
    CG.Load_indirect (info.cg_type, 0, info.size);
    Expr.Compile (inc);

    IF (info.cg_type = CG.Type.Addr)
      THEN CG.Index_bytes (Target.Byte);  check := 0;
      ELSE CG.Add (CG.Type.Int);
    END;

    VAR
      pmin, pmax: INTEGER;
    BEGIN
      EVAL TInt.ToInt(bmin, pmin);
      EVAL TInt.ToInt(bmax, pmax);

      CASE check OF
      | 0 => (* no range checking *)
      | 1 => 
        IF Host.verbose_checks THEN
          Error.Warn (1, "Emitting INC check low against " & 
            Fmt.Int(pmin));
        END;
        CG.Check_lo (bmin);
      | 2 => 
        IF Host.verbose_checks THEN
          Error.Warn (1, "Emitting INC check high against " & 
            Fmt.Int(pmax));
        END;
        CG.Check_hi (bmax);
      | 3 => 
        IF Host.verbose_checks THEN
          Error.Warn (1, "Emitting INC check range in [" & 
            Fmt.Int(pmin) & ", " & Fmt.Int(pmax));
        END;
        CG.Check_range (bmin, bmax);
      END;
    END;

    CG.Store_indirect (info.cg_type, 0, info.size);
    CG.Free (lvalue);
    Expr.NoteWrite (lhs);
  END Compile;

PROCEDURE Initialize () =
  BEGIN
    Z := CallExpr.NewMethodList (1, 2, FALSE, FALSE, TRUE, NIL,
                                 NIL,
                                 CallExpr.NotAddressable,
                                 Check,
                                 Prep,
                                 Compile,
                                 CallExpr.NoLValue,
                                 CallExpr.NoLValue,
                                 CallExpr.NotBoolean,
                                 CallExpr.NotBoolean,
                                 CallExpr.NoValue,
                                 CallExpr.IsNever, (* writable *)
                                 CallExpr.IsNever, (* designator *)
                                 CallExpr.NotWritable (* noteWriter *));
    Procedure.Define ("INC", Z, TRUE,
                      isBounded := TRUE, isFunctional := TRUE);
  END Initialize;

BEGIN
END Inc.
