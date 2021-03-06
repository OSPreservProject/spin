(* Copyright (C) 1992, Digital Equipment Corporation           *)
(* All rights reserved.                                        *)
(* See the file COPYRIGHT for a full description.              *)

(* File: IsType.m3                                             *)
(* Last Modified On Tue May  3 16:31:06 PDT 1994 By kalsow     *)
(*      Modified On Sat Dec  8 00:54:22 1990 By muller         *)

(*
 * HISTORY
 * 14-Jun-96  Przemek Pardyak (pardy) at the University of Washington
 *	Changed the typecell layout (see RT0.i3)
 *
 * 23-May-96  Wilson Hsieh (whsieh) at the University of Washington
 *	functional and bounded
 *
 * 13-Nov-95  Przemek Pardyak (pardy) at the University of Washington
 *	Generate code that reads new typecell layout (see RT0.i3)
 *
 * 25-Oct-95  Wilson Hsieh (whsieh) at the University of Washington
 *	make ISTYPE bounded
 *
 *)

MODULE IsType;

IMPORT CG, CallExpr, Expr, ExprRep, Type, Error, TypeExpr, Reff, RefType;
IMPORT Procedure, Bool, ObjectType, Null, TInt, M3RT, Target, M3ID;

VAR Z: CallExpr.MethodList;

PROCEDURE Check (ce: CallExpr.T;  <*UNUSED*> VAR cs: Expr.CheckState) =
  VAR t, u: Type.T;
  BEGIN
    IF  NOT TypeExpr.Split (ce.args[1], t) THEN
      Error.Msg ("ISTYPE: second argument must be a type");
      t := Expr.TypeOf (ce.args[0]);
    END;
    t := Type.Base (t);
    u := Expr.TypeOf (ce.args[0]);

    IF NOT Type.IsAssignable (t, u) THEN
      Error.Msg ("ISTYPE: types must be assignable");
    ELSIF ObjectType.Is (t) OR Type.IsSubtype (t, Reff.T) THEN
      (* ok *)
    ELSE (* untraced ref type *)
      Error.Msg ("ISTYPE: must be a traced reference or object type");
    END;

    ce.type := Bool.T;
  END Check;

PROCEDURE Prep (ce: CallExpr.T) =
  VAR
    e := ce.args[0];
    t, u: Type.T;
    ptr, tc, stc: CG.Val;
    true: CG.Label;
    typecells : CG.Var;
  BEGIN
    IF NOT TypeExpr.Split (ce.args[1], t) THEN
      t := Expr.TypeOf (e);
    END;
    Type.Compile (t);
    t := Type.Base (t);
    u := Expr.TypeOf (e);

    Expr.Prep (ce.args[0]);
    Expr.Compile (ce.args[0]);
    IF Type.IsSubtype (u, t) THEN
      (* the test succeeds statically *)
      CG.Discard (CG.Type.Addr);
      CG.Load_integer (TInt.One);
      ce.tmp := CG.Pop ();

    ELSIF Type.IsEqual (t, Null.T, NIL) THEN
      CG.Load_nil ();
      CG.Eq (CG.Type.Addr);
      ce.tmp := CG.Pop ();

    ELSIF RefType.Is (t) THEN
      true := CG.Next_label ();
      ptr := CG.Pop ();
      CG.Load_integer (TInt.One);
      CG.Force (); (* we need a temp *)
      ce.tmp := CG.Pop_temp ();
      CG.Push (ptr);
      CG.Load_nil ();
      CG.If_eq (true, CG.Type.Addr, CG.Maybe);

      CG.Push (ptr);
      CG.Ref_to_typecode ();
      Type.LoadInfo (t, M3RT.TC_typecode);
      CG.If_eq (true, CG.Type.Int, CG.Always);

      CG.Load_integer (TInt.Zero);
      CG.Store_temp (ce.tmp);
      CG.Set_label (true);

      CG.Free (ptr);

    ELSE (* general object type *)
      (* t -> lhs; u -> rhs *)
      true := CG.Next_label (2);
      ptr := CG.Pop ();
      CG.Load_integer (TInt.One);
      ce.tmp := CG.Pop_temp ();
      CG.Push (ptr);
      CG.Load_nil ();
      CG.If_eq (true, CG.Type.Addr, CG.Maybe);
      
      (* get the rhs typecode *)
      CG.Push (ptr);
      CG.Ref_to_typecode ();
      tc := CG.Pop ();
      CG.Push (tc);

      (* load the lhs typecode *)
      Type.LoadInfo (t, M3RT.TC_typecode);

      (* done if they are equal, otherwise compare subtype codes  *)
      CG.If_eq (true, CG.Type.Int, CG.Never);

      (* turn right-hand side typecode into a pointer to a typecell *)
      typecells := CG.Import_global (M3ID.Add ("RT0u__types"),
                                     Target.Address.size, 
                                     Target.Address.align,
                                     CG.Type.Addr, 0);
      CG.Load_addr (typecells);
      CG.Push (tc);
      CG.Index_bytes (Target.Integer.size);
      CG.Boost_alignment(Target.Address.align);
      CG.Load_indirect(Target.CGType.Word, 
                       0, 
                       Target.Integer.size);
      CG.Boost_alignment(Target.Address.align);

      (* load rhs subtype code *)
      CG.Load_indirect(Target.CGType.Word, 
                       M3RT.TC_subTypeCode, 
                       Target.Integer.size); 
      stc := CG.Pop();
      CG.Push(stc);

      (* load lhs subtype code *)
      Type.LoadInfo (t, M3RT.TC_subTypeCode);

      (* compare rhs subtype code with lhs subtype code *)
      CG.If_lt (true+1, CG.Type.Int, CG.Never);

      (* compare the rhs subtype code with lhs last subtype code *)
      CG.Push (stc);
      Type.LoadInfo (t, M3RT.TC_lastSubTypeCode);
      CG.If_le (true, CG.Type.Int, CG.Always);

      (* they are not subtypes *)
      CG.Set_label (true+1);
      CG.Load_integer (TInt.Zero);
      CG.Store_temp (ce.tmp);

      (* they are subtypes *)
      CG.Set_label (true);

      (* clean-up *)
      CG.Free (ptr);
      CG.Free (tc);
    END;
  END Prep;

PROCEDURE Compile (ce: CallExpr.T) =
  BEGIN
    (* all the work was done by Prep *)
    CG.Push (ce.tmp);
    CG.Free (ce.tmp);
    ce.tmp := NIL;
  END Compile;

PROCEDURE PrepBR (ce: CallExpr.T;  true, false: CG.Label;  freq: CG.Frequency)=
  VAR
    e := ce.args[0];
    t, u: Type.T;
    ptr: CG.Val;
    tc, stc: CG.Val;
    skip: CG.Label;
    typecells : CG.Var;
  BEGIN
    IF NOT TypeExpr.Split (ce.args[1], t) THEN
      t := Expr.TypeOf (e);
    END;
    Type.Compile (t);
    t := Type.Base (t);
    u := Expr.TypeOf (e);

    Expr.Prep (ce.args[0]);
    Expr.Compile (ce.args[0]);
    IF Type.IsSubtype (u, t) THEN
      (* the test succeeds statically *)
      CG.Discard (CG.Type.Addr);
      IF (true # CG.No_label)
        THEN CG.Jump (true);
      (*ELSE fall through*)
      END;

    ELSIF Type.IsEqual (t, Null.T, NIL) THEN
      CG.Load_nil ();
      IF (true # CG.No_label)
        THEN CG.If_eq (true, CG.Type.Addr, freq);
        ELSE CG.If_ne (false, CG.Type.Addr, freq);
      END;

    ELSIF RefType.Is (t) THEN
      skip := CG.Next_label ();
      ptr := CG.Pop ();
      CG.Push (ptr);
      CG.Load_nil ();
      IF (true # CG.No_label)
        THEN CG.If_eq (true, CG.Type.Addr, CG.Maybe);
        ELSE CG.If_eq (skip, CG.Type.Addr, CG.Maybe);
      END;

      CG.Push (ptr);
      CG.Ref_to_typecode ();
      Type.LoadInfo (t, M3RT.TC_typecode);
      IF (true # CG.No_label)
        THEN CG.If_eq (true, CG.Type.Int, freq);
        ELSE CG.If_ne (false, CG.Type.Int, freq);  CG.Set_label (skip);
      END;
      CG.Free (ptr);

    ELSE (* general object type *)
      skip := CG.Next_label ();
      ptr := CG.Pop ();
      CG.Push (ptr);
      CG.Load_nil ();
      IF (true # CG.No_label) THEN 
        CG.If_eq (true, CG.Type.Addr, CG.Maybe);
      ELSE
        CG.If_eq (skip, CG.Type.Addr, CG.Maybe);
      END;

      (* get the rhs typecode *)
      CG.Push (ptr);
      CG.Ref_to_typecode ();
      tc := CG.Pop ();
      CG.Push (tc);

      (* load the lhs typecode *)
      Type.LoadInfo (t, M3RT.TC_typecode);

      (* done if they are equal, otherwise compare subtype codes  *)
      IF (true # CG.No_label) THEN 
        CG.If_eq (true, CG.Type.Int, CG.Always - freq);
      ELSE 
        CG.If_eq (skip, CG.Type.Int, CG.Always - freq);
      END;

      (* turn right-hand side typecode into a pointer to a typecell *)
      typecells := CG.Import_global (M3ID.Add ("RT0u__types"),
                                     Target.Address.size, 
                                     Target.Address.align,
                                     CG.Type.Addr, 0);
      CG.Load_addr (typecells);
      CG.Push (tc);
      CG.Index_bytes (Target.Integer.size);
      CG.Boost_alignment(Target.Address.align);
      CG.Load_indirect(Target.CGType.Word, 
                       0, 
                       Target.Integer.size);
      CG.Boost_alignment(Target.Address.align);

      (* load rhs subtype code *)
      CG.Load_indirect(Target.CGType.Word, 
                       M3RT.TC_subTypeCode, 
                       Target.Integer.size); 
      stc := CG.Pop();
      CG.Push(stc);

      (* load lhs subtype code *)
      Type.LoadInfo (t, M3RT.TC_subTypeCode);

      (* compare rhs subtype code with lhs subtype code *)
      IF (true # CG.No_label) THEN
        CG.If_lt (skip, CG.Type.Int, CG.Always-freq); 
      ELSE
        CG.If_lt (false, CG.Type.Int, CG.Always-freq);
      END;

      (* compare rhs subtype code with lhs last subtype code *)
      CG.Push (stc);
      Type.LoadInfo (t, M3RT.TC_lastSubTypeCode);
      IF (true # CG.No_label) THEN
        CG.If_le (true, CG.Type.Int, freq); 
      ELSE
        CG.If_gt (false, CG.Type.Int, freq);
      END;

      (* they are not subtypes *)
      CG.Set_label (skip);
      CG.Free (ptr);
      CG.Free (tc);
    END;
  END PrepBR;

PROCEDURE Initialize () =
  BEGIN
    Z := CallExpr.NewMethodList (2, 2, TRUE, FALSE, TRUE, Bool.T,
                                 NIL,
                                 CallExpr.NotAddressable,
                                 Check,
                                 Prep,
                                 Compile,
                                 CallExpr.NoLValue,
                                 CallExpr.NoLValue,
                                 PrepBR,
                                 CallExpr.NoBranch,
                                 CallExpr.NoValue, (* fold *)
                                 CallExpr.IsNever, (* writable *)
                                 CallExpr.IsNever, (* designator *)
                                 CallExpr.NotWritable (* noteWriter *));
    Procedure.Define ("ISTYPE", Z, TRUE,
                      isBounded := TRUE, isFunctional := TRUE);
  END Initialize;

BEGIN
END IsType.
