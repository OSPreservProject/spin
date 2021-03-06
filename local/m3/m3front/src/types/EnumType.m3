(* Copyright (C) 1992, Digital Equipment Corporation           *)
(* All rights reserved.                                        *)
(* See the file COPYRIGHT for a full description.              *)

(* File: EnumType.m3                                           *)
(* Last modified on Wed Sep  7 15:31:35 PDT 1994 by kalsow     *)
(*      modified on Thu Jan 31 02:30:29 1991 by muller         *)

(*
 * HISTORY
 * 06-Oct-96  Wilson Hsieh (whsieh) at the University of Washington
 *	support for VIEW between representation-equivalent types
 *
 * 05-Jan-96  Wilson Hsieh (whsieh) at the University of Washington
 *	added ToText, which overrides the to_text inherited 
 *	method
 *      added name field and name argument to New
 *
 *)

MODULE EnumType;

IMPORT M3, M3ID, CG, Type, TypeRep, Value, Scope, Scanner, Ident;
IMPORT EnumElt, Token, CChar, Bool, M3Buf, Word, Error, TipeMap, TipeDesc;
IMPORT Target, TInt, TargetMap;

TYPE
  Rep = [FIRST (TargetMap.Int_types) .. LAST (TargetMap.Int_types)];

TYPE
  P = Type.T BRANDED "EnumType.m3" OBJECT
	n_elts     : INTEGER;
	scope      : Scope.T;
	rep        : Rep;
        name       : TEXT;
      OVERRIDES
        check      := Check;
        check_align:= CheckAlign;
        isEqual    := EqualChk;
        isEquiv    := EqualChkAlias;
        isSubtype  := Subtyper;
        compile    := Compiler;
        initCost   := InitCoster;
        initValue  := TypeRep.InitToZeros;
        mapper     := GenMap;
        gen_desc   := GenDesc;
        fprint     := FPrinter;
        to_text    := ToText;
      END;

PROCEDURE Parse (): Type.T =
  TYPE TK = Token.T;
  VAR n, j: INTEGER;  p: P;  val: Target.Int;  b: BOOLEAN;
  BEGIN
    p := Create (Scope.PushNew (FALSE, M3ID.NoID));
    n := 0;
    Scanner.Match (TK.tLBRACE);
    IF (Scanner.cur.token = TK.tIDENT) THEN
      n := Ident.ParseList ();
      j := Ident.top - n;
      FOR i := 0 TO n - 1 DO
        b := TInt.FromInt (i, val); <*ASSERT b*>
        Scope.Insert (EnumElt.New (Ident.stack[j + i], val, p));
      END;
      DEC (Ident.top, n);
    END;
    Scanner.Match (TK.tRBRACE);
    Scope.PopNew ();
    p.n_elts := n;
    SetRep (p);
    RETURN p;
  END Parse;

PROCEDURE New (n_elts: INTEGER;  elts: Scope.T; name: TEXT := NIL): Type.T =
  VAR p: P;
  BEGIN
    p := Create (elts);
    p.n_elts := n_elts;
    SetRep (p);
    p.name := name;
    RETURN p;
  END New;

PROCEDURE Reduce (t: Type.T): P =
  BEGIN
    IF (t = NIL) THEN RETURN NIL END;
    IF (t.info.class = Type.Class.Named) THEN t := Type.Strip (t) END;
    IF (t.info.class # Type.Class.Enum) THEN RETURN NIL END;
    RETURN t;
  END Reduce;

PROCEDURE Is (t: Type.T): BOOLEAN =
  BEGIN
    RETURN (Reduce (t) # NIL);
  END Is;

PROCEDURE LookUp (t: Type.T;  name: M3ID.T;  VAR value: Value.T): BOOLEAN =
  VAR p := Reduce (t);
  BEGIN
    IF (p = NIL) THEN RETURN FALSE END;
    value := Scope.LookUp (p.scope, name, TRUE);
    RETURN (value # NIL);
  END LookUp;

PROCEDURE NumElts (t: Type.T): INTEGER =
  VAR p: P := t;
  BEGIN
    RETURN p.n_elts;
  END NumElts;

(************************************************************************)

PROCEDURE Create (elts: Scope.T): P =
  VAR p: P;
  BEGIN
    p := NEW (P);
    TypeRep.Init (p, Type.Class.Enum);
    p.scope := elts;
    p.n_elts := 0;
    RETURN p;
  END Create;

PROCEDURE SetRep (p: P) =
  VAR max: Target.Int;
  BEGIN
    IF NOT TInt.FromInt (p.n_elts-1, max) THEN
      Error.Msg ("enumeration type too large");
    END;
    FOR i := FIRST (Rep) TO LAST (Rep) DO
      IF TInt.LE (max, TargetMap.Int_types[i].max) THEN
        p.rep := i; RETURN;
      END;
    END;
    p.rep := LAST (Rep);
  END SetRep;

PROCEDURE Check (p: P) =
  VAR v: Value.T;  hash: INTEGER;  cs := M3.OuterCheckState;
  BEGIN
    Scope.TypeCheck (p.scope, cs);
    v := Scope.ToList (p.scope);
    hash := 37;
    WHILE (v # NIL) DO
      hash := Word.Plus (Word.Times (hash, 67), M3ID.Hash (Value.CName (v)));
      v := v.next;
    END;

    p.info.size      := TargetMap.Int_types[p.rep].size;
    p.info.min_size  := MinSize (p);
    p.info.alignment := TargetMap.Int_types[p.rep].align;
    p.info.cg_type   := TargetMap.CG_Base [TargetMap.Int_types[p.rep].cg_type];
    p.info.class     := Type.Class.Enum;
    p.info.isTraced  := FALSE;
    p.info.isEmpty   := (p.n_elts <= 0);
    p.info.isSolid   := TRUE;
    p.info.hash      := hash;
  END Check;

PROCEDURE CheckAlign (p: P;  offset: INTEGER): BOOLEAN =
  VAR
    sz := TargetMap.Int_types [p.rep].size;
    z0 := offset DIV Target.Integer.align * Target.Integer.align;
  BEGIN
    RETURN (offset + sz) <= (z0 + Target.Integer.size);
  END CheckAlign;

PROCEDURE Compiler (p: P) =
  VAR v := Scope.ToList (p.scope);
  BEGIN
    CG.Declare_enum (Type.GlobalUID (p), p.n_elts,
                     TargetMap.Int_types[p.rep].size);
    WHILE (v # NIL) DO
      CG.Declare_enum_elt (Value.CName (v));
      v := v.next;
    END;
  END Compiler;

PROCEDURE EqualChkAlias (a: P; t: Type.T; x: Type.Assumption;
                         <*UNUSED*> canTruncate: BOOLEAN): BOOLEAN =
  BEGIN
    RETURN EqualChk (a, t, x);
  END EqualChkAlias;

PROCEDURE EqualChk (a: P;  t: Type.T;  <*UNUSED*>x: Type.Assumption): BOOLEAN =
  VAR b: P := t;  oa, ob : Value.T;
  BEGIN
    IF (a.n_elts # b.n_elts) THEN RETURN FALSE END;
    IF (a.n_elts = 0) THEN RETURN TRUE END;
    IF (a.scope = NIL) OR (b.scope = NIL) THEN
      RETURN (a.scope = b.scope);
    END;

    (* get a handle on the elements *)
    oa := Scope.ToList (a.scope);
    ob := Scope.ToList (b.scope);

    (* compare the elements *)
    WHILE (oa # NIL) AND (ob # NIL) AND EnumElt.IsEqual (oa, ob) DO
      oa := oa.next;  ob := ob.next;
    END;

    RETURN (oa = NIL) AND (ob = NIL);
  END EqualChk;

PROCEDURE Subtyper (a: P;  t: Type.T): BOOLEAN =
  BEGIN
    RETURN Type.IsEqual (a, t, NIL);
  END Subtyper;

PROCEDURE MinSize (p: P): INTEGER =
  VAR i, j, n: INTEGER;
  BEGIN
    j := 1;  i := 2;  n := p.n_elts;
    WHILE (n > i) DO INC (j); INC (i, i);  END;
    RETURN j;
  END MinSize;

PROCEDURE InitCoster (p: P;  zeroed: BOOLEAN): INTEGER =
  VAR max: Target.Int;
  BEGIN
    IF (p.n_elts <= 0) OR (zeroed) THEN RETURN 0; END;
    IF NOT TInt.FromInt (p.n_elts-1, max) THEN RETURN 1 END;
    IF TInt.EQ (TargetMap.Int_types[p.rep].min, TInt.Zero)
      AND TInt.EQ (TargetMap.Int_types[p.rep].max, max)
      THEN RETURN 0;
      ELSE RETURN 1;
    END;
  END InitCoster;

PROCEDURE GenMap (<*UNUSED*> p: P; offset, size: INTEGER; refs_only: BOOLEAN) =
  VAR bit_offset := offset MOD Target.Byte;  op: TipeMap.Op;
  BEGIN
    IF (refs_only) THEN RETURN END;
    IF (bit_offset # 0) THEN             op := TipeMap.Op.Word_Field;
    ELSIF (size = 1 * Target.Byte) THEN  op := TipeMap.Op.Word_1;
    ELSIF (size = 2 * Target.Byte) THEN  op := TipeMap.Op.Word_2;
    ELSIF (size = 4 * Target.Byte) THEN  op := TipeMap.Op.Word_4;
    ELSIF (size = 8 * Target.Byte) THEN  op := TipeMap.Op.Word_8;
    ELSE (* weird size *)                op := TipeMap.Op.Word_Field;
    END;
    TipeMap.Add (offset, op, bit_offset + 256 * size);
  END GenMap;

PROCEDURE GenDesc (p: P) =
  BEGIN
    IF Type.IsEqual (p, CChar.T, NIL) THEN
      EVAL TipeDesc.AddO (TipeDesc.Op.Char, p);
    ELSIF Type.IsEqual (p, Bool.T, NIL) THEN
      EVAL TipeDesc.AddO (TipeDesc.Op.Boolean, p);
    ELSIF TipeDesc.AddO (TipeDesc.Op.Enum, p) THEN
      TipeDesc.AddI (p.n_elts);
    END;
  END GenDesc;

PROCEDURE FPrinter (p: P;  VAR x: M3.FPInfo) =
  VAR v: Value.T;
  BEGIN
    x.n_nodes := 0;
    IF Type.IsEqual (p, CChar.T, NIL) THEN
      x.tag := "$char";
    ELSIF Type.IsEqual (p, Bool.T, NIL) THEN
      x.tag := "$boolean";
    ELSE
      M3Buf.PutText (x.buf, "ENUM");
      v := Scope.ToList (p.scope);
      WHILE (v # NIL) DO
        M3Buf.PutChar (x.buf, ' ');
        M3ID.Put      (x.buf, Value.CName (v));
        v := v.next;
      END;
    END;
  END FPrinter;

PROCEDURE ToText (p: P): TEXT =
  BEGIN
    IF (p.name # NIL) THEN
      RETURN (p.name);
    ELSE
      RETURN ("enumeration");
    END;
  END ToText;

BEGIN
END EnumType.

