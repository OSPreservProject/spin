(* Copyright (C) 1992, Digital Equipment Corporation           *)
(* All rights reserved.                                        *)
(* See the file COPYRIGHT for a full description.              *)

(* File: NamedType.m3                                          *)
(* Last modified on Tue Jul 19 10:05:49 PDT 1994 by kalsow     *)
(*      modified on Fri Dec 21 01:25:25 1990 by muller         *)

(*
 * HISTORY
 * 05-Feb-97  Wilson Hsieh (whsieh) at the University of Washington
 *	errors for using floats
 *      ref-counting code
 *
 * 06-Oct-96  Wilson Hsieh (whsieh) at the University of Washington
 *	support for VIEW between representation-equivalent types
 *
 * 05-Jan-96  Wilson Hsieh (whsieh) at the University of Washington
 *	added ToText, which overrides the to_text inherited 
 *	method
 *
 *)

MODULE NamedType;

IMPORT M3, M3ID, Token, Type, TypeRep, Scanner, ObjectType;
IMPORT Error, Scope, RefType, Value, ErrType;

IMPORT Host, Reel, EReel, LReel;

TYPE
  P = Type.T BRANDED "NamedType.T" OBJECT
        scope      : Scope.T;
	qid        : M3.QID;
	type       : Type.T;
        obj        : Value.T;
      OVERRIDES
        check      := Check;
        check_align:= CheckAlign;
        isEqual    := TypeRep.NeverEqual;
        isEquiv    := TypeRep.NeverEquiv;
        isSubtype  := TypeRep.NoSubtypes;
        compile    := Compiler;
        initCost   := InitCoster;
        initValue  := GenInit;
        mapper     := GenMap;
        gen_desc   := GenDesc;
        fprint     := FPrinter;
        to_text    := ToText;
        genRC      := GenRC;
      END;

PROCEDURE Parse (): Type.T =
  TYPE TK = Token.T;
  VAR p: P;  t: Type.T;
  BEGIN
    IF (Scanner.cur.token = TK.tIDENT)
      AND (Scanner.cur.defn # NIL)
      AND (Value.ClassOf (Scanner.cur.defn) = Value.Class.Type) THEN
      (* this identifier is reserved! *)
      t := Value.ToType (Scanner.cur.defn);
      Scanner.GetToken (); (* IDENT *)

      IF Host.no_float THEN
        IF t = Reel.T OR t = EReel.T OR t = LReel.T THEN
          Error.Msg ("floating-point type used");
        END;
      END;
    ELSE
      (* this is a non-reserved ID *)
      p := NEW (P);
      TypeRep.Init (p, Type.Class.Named);
      p.scope      := Scope.Top ();
      p.type       := NIL;
      p.obj        := NIL;
      p.qid.module := M3ID.NoID;
      p.qid.item   := Scanner.MatchID ();
      IF (Scanner.cur.token = TK.tDOT) THEN
        Scanner.GetToken (); (* . *)
        p.qid.module := p.qid.item;
        p.qid.item   := Scanner.MatchID ();
      END;
      t := p;
    END;
 
    IF (Scanner.cur.token = TK.tBRANDED) THEN
      t := ObjectType.Parse (t, FALSE, RefType.ParseBrand ());
    ELSIF (Scanner.cur.token = TK.tOBJECT) THEN
      t := ObjectType.Parse (t, FALSE, NIL);
    END;
    RETURN t;
  END Parse;

PROCEDURE New (t: Type.T): Type.T =
  VAR p: P;
  BEGIN
    p := NEW (P);
    TypeRep.Init (p, Type.Class.Named);
    p.scope      := NIL;
    p.qid.module := M3ID.NoID;
    p.qid.item   := M3ID.NoID;
    p.type       := t;
    p.obj        := NIL;
    RETURN p;
  END New;

PROCEDURE Create (m, n: M3ID.T): Type.T =
  VAR p: P;
  BEGIN
    p := NEW (P);
    TypeRep.Init (p, Type.Class.Named);
    p.scope      := Scope.Top ();
    p.qid.module := m;
    p.qid.item   := n;
    p.type       := NIL;
    p.obj        := NIL;
    RETURN p;
  END Create;

PROCEDURE Reduce (t: Type.T): P =
  BEGIN
    IF (t = NIL) THEN RETURN NIL END;
    IF (t.info.class # Type.Class.Named) THEN RETURN NIL END;
    RETURN t;
  END Reduce;

PROCEDURE Split (t: Type.T;  VAR name: M3.QID): BOOLEAN =
  VAR p := Reduce (t);
  BEGIN
    IF (p = NIL) THEN RETURN FALSE END;
    name := p.qid;
    RETURN TRUE;
  END Split;

PROCEDURE SplitV (t: Type.T;  VAR v: Value.T): BOOLEAN =
  VAR p := Reduce (t);
  BEGIN
    IF (p = NIL) THEN RETURN FALSE END;
    Resolve (p);
    v := p.obj;
    RETURN TRUE;
  END SplitV;

PROCEDURE Resolve (p: P) =
  VAR o: Value.T;  t: Type.T;  save: INTEGER;
  BEGIN
    IF (p.type = NIL) THEN
      o := Scope.LookUpQID (p.scope, p.qid);
      p.obj := o;
      IF (o = NIL) THEN
        save := Scanner.offset;
        Scanner.offset := p.origin;
        Error.QID (p.qid, "undefined");
        Scanner.offset := save;
        t := ErrType.T;
      ELSIF (Value.ClassOf (o) = Value.Class.Type) THEN
        t := Value.ToType (o);
      ELSE
        save := Scanner.offset;
        Scanner.offset := p.origin;
        Error.QID (p.qid, "name isn\'t bound to a type");
        Scanner.offset := save;
        t := ErrType.T;
      END;
      p.type := t;
    END;
  END Resolve;

PROCEDURE Strip (t: Type.T): Type.T =
  VAR p: P := t;
  BEGIN
    IF (p.type = NIL) THEN Resolve (p) END;
    RETURN p.type;
  END Strip;

PROCEDURE Check (p: P) =
  VAR cs := M3.OuterCheckState;  nErrs, nWarns, nErrsB: INTEGER;
  BEGIN
    IF (p.type = NIL) THEN Resolve (p) END;
    nErrs := 0;  nErrsB := 0;
    IF (p.obj # NIL) THEN
      Error.Count (nErrs, nWarns);
      Value.TypeCheck (p.obj, cs);
      Error.Count (nErrsB, nWarns);
    END;
    IF (nErrs = nErrsB) THEN
      (* no errors yet... *)
      p.type := Type.CheckInfo (p.type, p.info);
    ELSE (* some sort of error (probably illegal recursion...) *)
      EVAL Type.CheckInfo (ErrType.T, p.info);
    END;
    p.info.class := Type.Class.Named; (* this node is still a Named node *)
  END Check;

PROCEDURE CheckAlign (p: P;  offset: INTEGER): BOOLEAN =
  BEGIN
    IF (p.type = NIL) THEN Resolve (p) END;
    RETURN Type.IsAlignedOk (p.type, offset);
  END CheckAlign;

PROCEDURE Compiler (p: P) =
  BEGIN
    IF (p.type = NIL) THEN Resolve (p) END;
    (*** Type.Compile (p.type);  ***)
    IF (p.type # NIL) THEN
      Scanner.offset := p.type.origin;
      p.type.compile ();
    END;
  END Compiler;

PROCEDURE InitCoster (p: P;  zeroed: BOOLEAN): INTEGER =
  BEGIN
    IF (p.type = NIL) THEN Resolve (p) END;
    RETURN Type.InitCost (p.type, zeroed);
  END InitCoster;

PROCEDURE GenInit (p: P;  zeroed: BOOLEAN) =
  BEGIN
    IF (p.type = NIL) THEN Resolve (p) END;
    Type.InitValue (p.type, zeroed);
  END GenInit;

PROCEDURE GenMap (p: P;  offset, size: INTEGER;  refs_only: BOOLEAN) =
  BEGIN
    IF (p.type = NIL) THEN Resolve (p) END;
    Type.GenMap (p.type, offset, size, refs_only);
  END GenMap;

PROCEDURE GenDesc (p: P) =
  BEGIN
    IF (p.type = NIL) THEN Resolve (p) END;
    Type.GenDesc (p.type);
  END GenDesc;

PROCEDURE GenRC (p: P; definitelyGlobal: BOOLEAN; noOverlap := FALSE) =
  BEGIN
    Type.GenRC (p.type, definitelyGlobal, noOverlap);
  END GenRC;

PROCEDURE FPrinter (p: P;  VAR x: M3.FPInfo) =
  BEGIN
    Error.QID (p.qid, "INTERNAL ERROR: fingerprint of named type");
    IF (p.type = NIL) THEN Resolve (p) END;
    IF (p.type # NIL) THEN p.type.fprint (x); END;
  END FPrinter;

PROCEDURE ToText (p: P): TEXT =
  BEGIN
    RETURN (M3ID.ToText(p.qid.item));
  END ToText;

BEGIN
END NamedType.
