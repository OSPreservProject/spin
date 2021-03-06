(* Copyright (C) 1992, Digital Equipment Corporation           *)
(* All rights reserved.                                        *)
(* See the file COPYRIGHT for a full description.              *)

(* File: InExpr.m3                                             *)
(* Last modified on Fri Jul  8 09:48:45 PDT 1994 by kalsow     *)
(*      modified on Thu Nov 29 03:31:28 1990 by muller         *)

(* HISTORY
 * 23-Mar-96  Charles Garrett (garrett) at the University of Washington
 *	Call Type.Base to get rid of possible packed type.
 *
 *)

MODULE InExpr;

IMPORT CG, Expr, ExprRep, Error, Type, SetType, Bool, SetExpr;
IMPORT Target, TInt;

TYPE
  P = ExprRep.Tab BRANDED "InExpr.P" OBJECT
        tmp: CG.Val;
      OVERRIDES
        typeOf       := ExprRep.NoType;
        check        := Check;
        need_addr    := ExprRep.NotAddressable;
        prep         := Prep;
        compile      := Compile;
        prepLV       := ExprRep.NotLValue;
        compileLV    := ExprRep.NotLValue;
        prepBR       := ExprRep.PrepNoBranch;
        compileBR    := ExprRep.NoBranch;
        evaluate     := Fold;
        isEqual      := ExprRep.EqCheckAB;
        getBounds    := ExprRep.NoBounds;
        isWritable   := ExprRep.IsNever;
        isDesignator := ExprRep.IsNever;
	isZeroes     := ExprRep.IsNever;
	genFPLiteral := ExprRep.NoFPLiteral;
	prepLiteral  := ExprRep.NoPrepLiteral;
	genLiteral   := ExprRep.NoLiteral;
        note_write   := ExprRep.NotWritable;
      END;

PROCEDURE New (a, b: Expr.T): Expr.T =
  VAR p: P;
  BEGIN
    p := NEW (P);
    ExprRep.Init (p);
    p.a    := a;
    p.b    := b;
    p.type := Bool.T;
    p.tmp  := NIL;
    RETURN p;
  END New;

PROCEDURE Check (p: P;  VAR cs: Expr.CheckState) =
  VAR ta, tb, tc: Type.T;
  BEGIN
    Expr.TypeCheck (p.a, cs);
    Expr.TypeCheck (p.b, cs);
    ta := Type.Base (Expr.TypeOf (p.a));
    tb := Type.Base (Expr.TypeOf (p.b));
    IF SetType.Split (tb, tc) AND Type.IsSubtype (ta, Type.Base (tc)) THEN
      (*ok *)
    ELSE
      p.type := Expr.BadOperands ("IN", ta, tb);
    END;
  END Check;

PROCEDURE Prep (p: P) =
  VAR
    set, range: Type.T;
    b: BOOLEAN;
    min, max, emin, emax, n_elts: Target.Int;
    skip: CG.Label;
    index: CG.Val;
    info: Type.Info;
  BEGIN
    set := Type.Base (Type.CheckInfo (Expr.TypeOf (p.b), info));
    b := SetType.Split (set, range);  <*ASSERT b*>
    b := Type.GetBounds (range, min, max);  <*ASSERT b*>
    Expr.GetBounds (p.a, emin, emax);

    Expr.Prep (p.a);
    Expr.Prep (p.b);

    IF TInt.LT (emin, min) OR TInt.LT (max, emax) THEN
      (* we need to range check a *)
      IF NOT TInt.Subtract (max, min, n_elts) THEN
        Error.Msg ("set too large");
      END;
      Expr.Compile (p.a);
      IF NOT TInt.EQ (min, TInt.Zero) THEN
        CG.Load_integer (min);
        CG.Subtract (CG.Type.Int);
      END;
      index := CG.Pop ();
      CG.Load_integer (TInt.Zero);
      p.tmp := CG.Pop_temp ();
      CG.Push (index);
      CG.Loophole (CG.Type.Int, CG.Type.Word);
      CG.Load_integer (n_elts);
      CG.Loophole (CG.Type.Int, CG.Type.Word);
      skip := CG.Next_label ();
      CG.If_gt (skip, CG.Type.Word, CG.Never);
      Expr.Compile (p.b);
      CG.Push (index);
      CG.Set_member (info.size);
      CG.Store_temp (p.tmp);
      CG.Set_label (skip);
      CG.Free (index);
    END;
  END Prep;

PROCEDURE Compile (p: P) =
  VAR
    set, range: Type.T;
    b: BOOLEAN;
    min, max, emin, emax: Target.Int;
    info: Type.Info;
  BEGIN
    set := Type.Base (Type.CheckInfo (Expr.TypeOf (p.b), info));
    b := SetType.Split (set, range);  <*ASSERT b*>
    b := Type.GetBounds (range, min, max);  <*ASSERT b*>
    Expr.GetBounds (p.a, emin, emax);

    IF TInt.LT (emin, min) OR TInt.LT (max, emax) THEN
      (* we need to range check a *)
      CG.Push (p.tmp);
      CG.Free (p.tmp);
      p.tmp := NIL;
    ELSE
      (* no range checking is needed *)
      Expr.Compile (p.b);
      Expr.Compile (p.a);
      IF NOT TInt.EQ (min, TInt.Zero) THEN
        CG.Load_integer (min);
        CG.Subtract (CG.Type.Int);
      END;
      CG.Set_member (info.size);
    END;
  END Compile;

PROCEDURE Fold (p: P): Expr.T =
  VAR e1, e2, e3: Expr.T;
  BEGIN
    e1 := Expr.ConstValue (p.b);
    e2 := Expr.ConstValue (p.a);
    e3 := NIL;
    IF (e1 = NIL) OR (e2 = NIL) THEN
    ELSIF SetExpr.Member (e1, e2, e3) THEN
    END;
    RETURN e3;
  END Fold;

BEGIN
END InExpr.
