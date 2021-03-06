(* Copyright (C) 1992, Digital Equipment Corporation           *)
(* All rights reserved.                                        *)
(* See the file COPYRIGHT for a full description.              *)

(* File: ProcType.m3                                           *)
(* Last modified on Fri Feb 24 16:48:22 PST 1995 by kalsow     *)
(*      modified on Thu Dec  5 17:23:39 PST 1991 by muller     *)

(*
 * HISTORY
 * 06-Oct-96  Wilson Hsieh (whsieh) at the University of Washington
 *	support for VIEW between representation-equivalent types
 *
 * 27-Sep-96  Wilson Hsieh (whsieh) at the University of Washington
 *	support for inline
 *
 * 19-Sep-96  Wilson Hsieh (whsieh) at the University of Washington
 *	fix IsCompatible to deal with FUNCTIONAL
 *	fix IsCompatible: before it wouldn't consider an EPHMERAL
 *	 procedure to be compatible with a method type
 *
 * 28-May-96  Wilson Hsieh (whsieh) at the University of Washington
 *	Formal.Split returns BOOLEAN: use EVAL
 *	fix up parsing for EPHEMERAL, FUNCTIONAL
 *
 * 17-Apr-96  Wilson Hsieh (whsieh) at the University of Washington
 *	error message now references EPHEMERAL
 *	make procedure types subtype of PROCANY and ADDRESS
 *	fix parsing of BOUNDED PROCEDURE so that call convention comes in
 *	 the middle
 *
 * 11-Jan-96  Wilson Hsieh (whsieh) at the University of Washington
 *	support for CVAR formals
 *        added isExternal to ParseSignature and ParseFormal
 *
 * 05-Jan-96  Wilson Hsieh (whsieh) at the University of Washington
 *	added ToText, which overrides the to_text inherited 
 *	method
 *
 * 19-Nov-95  Przemek Pardyak (pardy) at the University of Washington
 *	Added RealNFormals for generation of runtime type information 
 *	for procedures.  NFormals cannot be used because it includes
 *	large results in the set of formals.
 *
 * 25-Oct-95  Wilson Hsieh (whsieh) at the University of Washington
 *	support for bounded
 *
 *)

MODULE ProcType;

IMPORT M3, M3ID, CG, Expr, Type, TypeRep, Value, Scope, Target;
IMPORT Formal, UserProc, Token, Ident, CallExpr, Word, Error;
IMPORT ESet, TipeMap, TipeDesc, ErrType, M3Buf, Variable, OpenArrayType;
IMPORT Procany, Addr;

FROM Scanner IMPORT Match, GetToken, cur;

TYPE
  P = Type.T BRANDED "ProcType.T" OBJECT
        methods    : CallExpr.MethodList;
        formals    : Scope.T;
        nFormals   : INTEGER;
        result     : Type.T;
        raises     : ESet.T;
        callConv   : CG.CallingConvention;
        (* SPIN *)
        isBounded   : BOOLEAN := FALSE;
        isFunctional: BOOLEAN := FALSE;
        isInline    : BOOLEAN := FALSE;
        callsInline : BOOLEAN := FALSE;
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
  VAR callConv := Target.DefaultCall;
      isBounded : BOOLEAN := FALSE;
      isFunctional : BOOLEAN := FALSE;
  BEGIN
    WHILE cur.token # Token.T.tPROCEDURE DO
      CASE cur.token OF
      | Token.T.tBOUNDED =>
        isBounded := TRUE;
        GetToken (); (* EPHEMERAL *)
      | Token.T.tFUNCTIONAL =>
        isFunctional := TRUE;
        GetToken (); (* FUNCTIONAL *)
      | Token.T.tCALLCONV =>
        callConv := Target.FindConvention (M3ID.ToText (cur.id));
        GetToken (); (* tCALLCONV *)
        Match (Token.T.tENDPRAGMA);
      ELSE
        EXIT;
      END;
    END;

    Match (Token.T.tPROCEDURE);
    RETURN ParseSignature (M3ID.NoID, callConv,
                           isBounded := isBounded,
                           isFunctional := isFunctional);
  END Parse;

CONST FormalStart = Token.Set {Token.T.tVALUE, Token.T.tVAR, Token.T.tREADONLY,
                               Token.T.tCVAR,
                               Token.T.tIDENT, Token.T.tUNUSED};

PROCEDURE ParseSignature (name: M3ID.T;  cc: CG.CallingConvention;
                          isBounded: BOOLEAN := FALSE;
                          isFunctional: BOOLEAN := FALSE;
                          isExternal: BOOLEAN := FALSE;
                          isInline: BOOLEAN := FALSE): Type.T =
  TYPE  TK = Token.T;
  VAR   p: P;
  BEGIN
    p := Create (Scope.PushNew (FALSE, name));
    p.callConv := cc;

    (* SPIN *)
    p.isBounded := isBounded;
    p.isFunctional := isFunctional;
    p.isInline := isInline;

    Match (TK.tLPAREN);
    WHILE (cur.token IN FormalStart) DO
      ParseFormal (p, isExternal);
      IF (cur.token # TK.tSEMI) THEN EXIT END;
      GetToken (); (* ; *)
    END;
    Match (TK.tRPAREN);
    IF (cur.token = TK.tCOLON) THEN
      GetToken (); (* : *)
      p.result := Type.Parse ();
    END;
    IF (cur.token = TK.tRAISES) THEN
      p.raises := ESet.ParseRaises ();
    END;
    Scope.PopNew ();
    RETURN p;
  END ParseSignature;

PROCEDURE ParseFormal (p: P; isExternal: BOOLEAN := FALSE) =
  TYPE TK = Token.T;
  VAR
    j, n    : INTEGER;
    obj     : Value.T;
    formal  : Formal.Info;
  BEGIN
    formal.mode   := Formal.Mode.mVALUE;
    formal.type   := NIL;
    formal.dfault := NIL;
    formal.trace  := NIL;
    formal.unused := (cur.token = TK.tUNUSED);
    IF (formal.unused) THEN
      GetToken (); (*UNUSED*)
      Match (TK.tENDPRAGMA);
    END;
    IF (cur.token = TK.tVALUE) THEN
      formal.mode := Formal.Mode.mVALUE;
      GetToken (); (* VALUE *)
    ELSIF (cur.token = TK.tVAR) THEN
      formal.mode := Formal.Mode.mVAR;
      GetToken (); (* VAR *)
    ELSIF (cur.token = TK.tREADONLY) THEN
      formal.mode := Formal.Mode.mCONST;
      GetToken (); (* READONLY *)
    ELSIF (cur.token = TK.tCVAR) THEN
      IF NOT isExternal THEN
        Error.Msg ("CVAR formals only allowed in EXTERNAL declarations");
      END;
      formal.mode := Formal.Mode.mCVAR;
      GetToken (); (* CVAR *)
    END;
    n := Ident.ParseList ();
    IF (cur.token = TK.tCOLON) THEN
      GetToken (); (* : *)
      formal.type := Type.Parse ();
    END;
    IF (cur.token = TK.tEQUAL) THEN
      Error.Msg ("default value must begin with \':=\'");
      cur.token := TK.tASSIGN;
    END;
    IF (cur.token = TK.tASSIGN) THEN
      GetToken (); (* := *)
      formal.dfault := Expr.Parse ();
    END;
    formal.trace := Variable.ParseTrace ();
    IF (formal.type = NIL) AND (formal.dfault = NIL) THEN
      Error.ID (Ident.stack[Ident.top - 1],
                 "formals must have a type or default value");
    END;
    j := Ident.top - n;
    FOR i := 0 TO n - 1 DO
      formal.name   := Ident.stack [j + i];
      formal.offset := p.nFormals;
      obj := Formal.New (formal);
      obj.origin := Ident.offset[j + i];
      Scope.Insert (obj);
      INC (p.nFormals);
    END;
    DEC (Ident.top, n);
  END ParseFormal;

VAR unnamed: M3ID.T := M3ID.NoID;

PROCEDURE MethodSigAsProcSig (sig, objType: Type.T): Type.T =
  VAR
    pProc   : P;
    f, v    : Value.T;
    formal  : Formal.Info;
    pMethod := Reduce (sig);
  BEGIN
    IF (pMethod = NIL) THEN RETURN ErrType.T END;

    pProc := Create (Scope.PushNew (FALSE, M3ID.NoID));
    pProc.nFormals  := pMethod.nFormals + 1;
    pProc.result    := pMethod.result;
    pProc.raises    := pMethod.raises;
    pProc.callConv  := pMethod.callConv;

    (* insert the "self" formal *)
    IF (unnamed = M3ID.NoID) THEN unnamed := M3ID.Add ("_self_") END;
    formal.name   := unnamed;
    formal.offset := 0;
    formal.mode   := Formal.Mode.mVALUE;
    formal.type   := objType;
    formal.dfault := NIL;
    formal.trace  := NIL;
    formal.unused := FALSE;
    Scope.Insert (Formal.New (formal));

    (* copy the remaining formals *)
    v := Scope.ToList (pMethod.formals);
    WHILE (v # NIL) DO
      EVAL Formal.Split (v, formal);
      INC (formal.offset);
      f := Formal.New (formal);
      f.origin := v.origin;
      Scope.Insert (f);
      v := v.next;
    END;

    Scope.PopNew ();
    RETURN pProc;
  END MethodSigAsProcSig;

PROCEDURE Create (s: Scope.T): P =
  VAR p := NEW (P);
  BEGIN
    TypeRep.Init (p, Type.Class.Procedure);
    p.methods   := UserProc.Methods;
    p.formals   := s;
    p.nFormals  := 0;
    p.result    := NIL;
    p.raises    := NIL;
    p.callConv  := Target.DefaultCall;
    RETURN p;
  END Create;

PROCEDURE Check (p: P) =
  VAR
    hash   : INTEGER;
    v      : Value.T;
    formal : Formal.Info;
    cs     := M3.OuterCheckState;
  BEGIN
    (* look up each of the named exceptions *)
    ESet.TypeCheck (p.raises);

    (* add the exceptions to the hash value *)
    hash := ESet.Hash (p.raises);
    
    (* finish my hash value *)
    v := Scope.ToList (p.formals);
    WHILE (v # NIL) DO
      EVAL Formal.Split (v, formal);
      hash := Word.Plus (Word.Times (hash, 23), M3ID.Hash (formal.name));
      hash := Word.Plus (Word.Times (hash, 37), ORD (formal.mode));
      v := v.next;
    END;

    hash := Word.Plus (hash, p.callConv.m3cg_id);

    p.info.size      := Target.Address.size;
    p.info.min_size  := Target.Address.size;
    p.info.alignment := Target.Address.align;
    p.info.cg_type   := CG.Type.Addr;
    p.info.class     := Type.Class.Procedure;
    p.info.isTraced  := FALSE;
    p.info.isEmpty   := FALSE;
    p.info.isSolid   := TRUE;
    p.info.hash      := hash;

    INC (Type.recursionDepth); (*------------------------------------*)
      p.checked := TRUE;
      Scope.TypeCheck (p.formals, cs);
      IF (p.result # NIL) THEN
        p.result := Type.Check (p.result);
        IF OpenArrayType.Is (p.result) THEN
          Error.Msg ("procedures may not return open arrays");
        END;
      END;
    DEC (Type.recursionDepth); (*------------------------------------*)
  END Check;

PROCEDURE CheckAlign (<*UNUSED*> p: P;  offset: INTEGER): BOOLEAN =
  BEGIN
    RETURN (offset MOD Target.Address.align = 0);
  END CheckAlign;

PROCEDURE Compiler (p: P) =
  VAR n_formals, n_raises: INTEGER;  v: Value.T;  result_id: CG.TypeUID;
  BEGIN
    IF (p.result = NIL) THEN
      result_id := 0;
    ELSE
      Type.Compile (p.result);
      result_id := Type.GlobalUID (p.result);
      IF LargeResult (p.result) THEN result_id := 0 END;
    END;

    v := Scope.ToList (p.formals);  n_formals := 0;
    WHILE (v # NIL) DO
      Formal.EmitDeclaration (v, TRUE, FALSE);
      INC (n_formals);
      v := v.next;
    END;
    n_raises := ESet.EmitTypes (p.raises);
    CG.Declare_proctype (Type.GlobalUID (p), n_formals, result_id, n_raises,
                         p.callConv);
    v := Scope.ToList (p.formals);
    WHILE (v # NIL) DO
      Formal.EmitDeclaration (v, FALSE, FALSE);
      v := v.next;
    END;
    ESet.EmitNames (p.raises);
  END Compiler;

PROCEDURE IsCompatible (procSig, objectType, methodSig: Type.T): BOOLEAN =
  VAR p := Reduce (procSig);  q := Reduce (methodSig);
  BEGIN
    IF (p = NIL) OR (q = NIL) THEN RETURN FALSE END;
    IF (p.nFormals # q.nFormals + 1) THEN RETURN FALSE END;
    IF (p.callConv.m3cg_id # q.callConv.m3cg_id) THEN RETURN FALSE END;
    IF (p.result = NIL) AND (q.result = NIL) THEN (* ok *)
    ELSIF NOT Type.IsEqual (p.result, q.result, NIL) THEN RETURN FALSE;
    END;
    IF NOT FirstArgOK (p.formals, objectType) THEN RETURN FALSE END;
    IF NOT FormalsMatch (p.formals, q.formals, FALSE, FALSE, NIL) THEN
      RETURN FALSE;
    END;

    IF q.isFunctional AND (NOT p.isFunctional) THEN
      RETURN FALSE;
    END;
    
    RETURN ESet.IsSubset (p.raises, q.raises);
  END IsCompatible;

PROCEDURE FirstArgOK (s: Scope.T;  t: Type.T): BOOLEAN =
  VAR v := Scope.ToList (s);  formal: Formal.Info;
  BEGIN
    WHILE (v # NIL) DO
      EVAL Formal.Split (v, formal);
      IF (formal.offset = 0) THEN
        RETURN (formal.mode = Formal.Mode.mVALUE)
           AND Type.IsSubtype (t, formal.type);
      END;
      v := v.next;
    END;
    RETURN FALSE;
  END FirstArgOK;

PROCEDURE EqualChkAlias (a: P; t: Type.T; x: Type.Assumption;
                         <*UNUSED*> canTruncate: BOOLEAN): BOOLEAN =
  BEGIN
    RETURN EqualChk (a, t, x);
  END EqualChkAlias;

PROCEDURE EqualChk (a: P;  t: Type.T;  x: Type.Assumption): BOOLEAN =
  VAR b: P := t;
  BEGIN
    IF (a.methods # b.methods) THEN RETURN FALSE END;
    IF (a.nFormals # b.nFormals) THEN RETURN FALSE END;
    IF (a.callConv.m3cg_id # b.callConv.m3cg_id) THEN RETURN FALSE END;
    IF (a.result = NIL) AND (b.result = NIL) THEN (* ok *)
    ELSIF NOT Type.IsEqual (a.result, b.result, x) THEN RETURN FALSE;
    END;
    IF NOT FormalsMatch (a.formals, b.formals, TRUE, TRUE, x) THEN
      RETURN FALSE;
    END;

    (* SPIN *)
    IF (a.isBounded # b.isBounded) THEN
      RETURN FALSE;
    END;
    IF (a.isFunctional # b.isFunctional) THEN
      RETURN FALSE;
    END;

    RETURN ESet.IsEqual (a.raises, b.raises);
  END EqualChk;

PROCEDURE Subtyper (a: P;  t: Type.T): BOOLEAN =
  VAR b: P;
  BEGIN
    (* PROCEDURE <: PROCANY and PROCEDURE <: ADDRESS *)
    IF t = Procany.T OR t = Addr.T THEN RETURN TRUE END;

    IF (t.info.class # Type.Class.Procedure) THEN RETURN FALSE END;
    b := t;
    IF (a.nFormals # b.nFormals) THEN RETURN FALSE END;
    IF (a.callConv.m3cg_id # b.callConv.m3cg_id) THEN RETURN FALSE END;
    IF (a.result = NIL) AND (b.result = NIL) THEN (* ok *)
    ELSIF NOT Type.IsEqual (a.result, b.result, NIL) THEN RETURN FALSE;
    END;
    IF NOT FormalsMatch (a.formals, b.formals, FALSE, TRUE, NIL) THEN
      RETURN FALSE;
    END;
    IF (NOT a.isBounded) AND b.isBounded THEN
      RETURN FALSE;
    END;
    IF (NOT a.isFunctional) AND b.isFunctional THEN
      RETURN FALSE;
    END;
    RETURN ESet.IsSubset (a.raises, b.raises);
  END Subtyper;

PROCEDURE FormalsMatch (a, b: Scope.T;  strict, useFirst: BOOLEAN;
                         x: Type.Assumption): BOOLEAN =
  VAR
    va, vb : Value.T;
    ia, ib : Formal.Info;
    e1, e2 : Expr.T;
  BEGIN
    va := Scope.ToList (a);
    vb := Scope.ToList (b);
    IF (NOT useFirst) THEN
      IF (va = NIL) THEN RETURN FALSE END;
      va := va.next;
    END;

    WHILE (va # NIL) AND (vb # NIL) DO
      EVAL Formal.Split (va, ia);
      EVAL Formal.Split (vb, ib);
      IF (ia.mode # ib.mode) THEN RETURN FALSE END;
      IF NOT Type.IsEqual (ia.type, ib.type, x) THEN RETURN FALSE END;
      IF (strict) THEN
        IF (ia.name # ib.name) THEN RETURN FALSE END;
        e1 := Expr.ConstValue (ia.dfault);
        e2 := Expr.ConstValue (ib.dfault);
        IF NOT Expr.IsEqual (e1, e2, x) THEN RETURN FALSE END;
      END;
      va := va.next;  vb := vb.next;
    END;

    RETURN (va = NIL) AND (vb = NIL);
  END FormalsMatch;

PROCEDURE Reduce (t: Type.T): P =
  BEGIN
    IF (t = NIL) THEN RETURN NIL END;
    IF (t.info.class = Type.Class.Named) THEN t := Type.Strip (t) END;
    IF (t.info.class # Type.Class.Procedure) THEN RETURN NIL END;
    RETURN t;
  END Reduce;

PROCEDURE Is (t: Type.T): BOOLEAN =
  BEGIN
    RETURN (Reduce (t) # NIL);
  END Is;

PROCEDURE Result (t: Type.T): Type.T =
  VAR p := Reduce (t);
  BEGIN
    IF (p # NIL)
      THEN RETURN p.result;
      ELSE RETURN ErrType.T;
    END;
  END Result;

PROCEDURE CGResult (t: Type.T): CG.Type =
  VAR p := Reduce (t);
  BEGIN
    IF (p = NIL) OR (p.result = NIL) THEN
      RETURN CG.Type.Void;
    ELSIF NOT LargeResult (p.result) THEN
      RETURN Type.CGType (p.result);
    ELSIF p.callConv.standard_structs THEN
      RETURN CG.Type.Void;
    ELSE
      RETURN CG.Type.Struct;
    END;
  END CGResult;

PROCEDURE LargeResult (t: Type.T): BOOLEAN =
  BEGIN
    RETURN Type.IsStructured (t);
  END LargeResult;

PROCEDURE NFormals (t: Type.T): INTEGER =
  VAR p := Reduce (t);  v: Value.T;  n: INTEGER;
  BEGIN
    IF (p = NIL) THEN RETURN 0 END;
    v := Scope.ToList (p.formals);
    n := 0;
    WHILE (v # NIL) DO  v := v.next;  INC (n);  END;
    IF (p.result # NIL) AND LargeResult (p.result) THEN
      INC (n); (* large results are passed as an extra VAR parameter *)
    END;
    RETURN n;
  END NFormals;

PROCEDURE RealNFormals (t: Type.T): INTEGER =
  VAR p := Reduce (t);  v: Value.T;  n: INTEGER;
  BEGIN
    IF (p = NIL) THEN RETURN 0 END;
    v := Scope.ToList (p.formals);
    n := 0;
    WHILE (v # NIL) DO  v := v.next;  INC (n);  END;
    RETURN n;
  END RealNFormals;

PROCEDURE Formals (t: Type.T): Value.T =
  VAR p := Reduce (t);
  BEGIN
    IF (p # NIL)
      THEN RETURN Scope.ToList (p.formals);
      ELSE RETURN NIL;
    END;
  END Formals;

PROCEDURE Raises (t: Type.T): M3.ExSet =
  VAR p := Reduce (t);
  BEGIN
    IF (p # NIL)
      THEN RETURN p.raises;
      ELSE RETURN NIL;
    END;
  END Raises;

PROCEDURE Methods (t: Type.T): CallExpr.MethodList =
  VAR p := Reduce (t);
  BEGIN
    IF (p # NIL)
      THEN RETURN p.methods;
      ELSE RETURN NIL;
    END;
  END Methods;

PROCEDURE CallConv  (t: Type.T): CG.CallingConvention =
  VAR p := Reduce (t);
  BEGIN
    IF (p # NIL)
      THEN RETURN p.callConv;
      ELSE RETURN NIL;
    END;
  END CallConv;

PROCEDURE New (result: Type.T;  f0, f1, f2, f3: Value.T := NIL;
               isBounded: BOOLEAN := FALSE;
               isFunctional: BOOLEAN := FALSE): Type.T =
  VAR p: P;
  BEGIN
    p := Create (Scope.PushNew (FALSE, M3ID.NoID));
    IF (f0 # NIL) THEN  Scope.Insert (f0);  INC (p.nFormals);  END;
    IF (f1 # NIL) THEN  Scope.Insert (f1);  INC (p.nFormals);  END;
    IF (f2 # NIL) THEN  Scope.Insert (f2);  INC (p.nFormals);  END;
    IF (f3 # NIL) THEN  Scope.Insert (f3);  INC (p.nFormals);  END;
    p.result := result;
    p.isBounded := isBounded;
    p.isFunctional := isFunctional;
    Scope.PopNew ();
    RETURN p;
  END New;

PROCEDURE SetMethods (t: Type.T;  m: CallExpr.MethodList) =
  BEGIN
    NARROW (t, P).methods := m;
  END SetMethods;

PROCEDURE InitCoster (<*UNUSED*> p: P;  zeroed: BOOLEAN): INTEGER =
  BEGIN
    IF (zeroed) THEN RETURN 0 ELSE RETURN 1 END;
  END InitCoster;

PROCEDURE GenMap (<*UNUSED*> p: P; offset, size: INTEGER; refs_only: BOOLEAN) =
  BEGIN
    <*ASSERT size = Target.Address.size*>
    IF NOT refs_only THEN
      TipeMap.Add (offset, TipeMap.Op.Proc, 0);
    END;
  END GenMap;

PROCEDURE GenDesc (p: P) =
  BEGIN
    EVAL TipeDesc.AddO (TipeDesc.Op.Proc, p);
  END GenDesc;

PROCEDURE FPrinter (p: P;  VAR x: M3.FPInfo) =
  VAR v: Value.T;  n: INTEGER;
  BEGIN

    IF (p.isBounded) THEN
      M3Buf.PutText (x.buf, "EPHEMERAL ");
    END;

    IF (p.isFunctional) THEN
      M3Buf.PutText (x.buf, "FUNCTIONAL ");
    END;

    M3Buf.PutText (x.buf, "PROC(");

    IF (p.callConv.m3cg_id # 0) THEN
      M3Buf.PutText (x.buf, "<*CC=");
      M3Buf.PutInt  (x.buf, p.callConv.m3cg_id);
      M3Buf.PutText (x.buf, "*>");
    END;
    
    (* count the nodes *)
    v := Scope.ToList (p.formals);  n := 0;
    WHILE (v # NIL) DO  INC (n, Value.AddFPTag (v, x));  v := v.next;  END;
    M3Buf.PutChar (x.buf, ')');
    IF (p.result # NIL) THEN M3Buf.PutText (x.buf, " => ?"); INC (n) END;
    INC (n, ESet.AddFPTag (p.raises, x));
    x.n_nodes := n;

    IF (n <= NUMBER (x.nodes)) THEN
      v := Scope.ToList (p.formals);  n := 0;
      WHILE (v # NIL) DO  n := Value.AddFPEdges (v, x, n);  v := v.next;  END;
      IF (p.result # NIL) THEN  x.nodes[n] := p.result; INC (n);  END;
      n := ESet.AddFPEdges (p.raises, x, n);
    ELSE
      x.others := NEW (REF ARRAY OF Type.T, n);
      v := Scope.ToList (p.formals);  n := 0;
      WHILE (v # NIL) DO  n := Value.AddFPEdges (v, x, n);  v := v.next;  END;
      IF (p.result # NIL) THEN  x.others[n] := p.result; INC (n);  END;
      n := ESet.AddFPEdges (p.raises, x, n);
    END;
  END FPrinter;

  (* SPIN *)

PROCEDURE DoesCallInline (t: Type.T) =
  VAR p := Reduce (t);
  BEGIN
    IF (p # NIL) THEN p.callsInline := TRUE; END;
  END DoesCallInline;

PROCEDURE IsActuallyInline (t: Type.T) =
  VAR p := Reduce (t);
  BEGIN
    IF (p # NIL) THEN p.isInline := TRUE; END;
  END IsActuallyInline;

PROCEDURE IsBounded (t: Type.T) : BOOLEAN =
  VAR p := Reduce (t);
  BEGIN
    IF (p # NIL)
      THEN RETURN p.isBounded;
      ELSE RETURN FALSE;
    END;
  END IsBounded;

PROCEDURE IsFunctional (t: Type.T) : BOOLEAN =
  VAR p := Reduce (t);
  BEGIN
    IF (p # NIL)
      THEN RETURN p.isFunctional;
      ELSE RETURN FALSE;
    END;
  END IsFunctional;

PROCEDURE IsInline (t: Type.T) : BOOLEAN =
  VAR p := Reduce (t);
  BEGIN
    IF (p # NIL)
      THEN RETURN p.isInline;
      ELSE RETURN FALSE;
    END;
  END IsInline;

PROCEDURE CallsInline (t: Type.T) : BOOLEAN =
  VAR p := Reduce (t);
  BEGIN
    IF (p # NIL)
      THEN RETURN p.callsInline;
      ELSE RETURN FALSE;
    END;
  END CallsInline;

PROCEDURE ToText (p: P): TEXT =
  BEGIN
    IF p.isBounded AND p.isFunctional THEN
      RETURN "EPHEMERAL FUNCTIONAL PROCEDURE";
    ELSIF p.isBounded THEN
      RETURN "EPHEMERAL PROCEDURE"
    ELSIF p.isFunctional THEN
      RETURN "FUNCTIONAL PROCEDURE"
    ELSE
      RETURN "PROCEDURE";
    END;
  END ToText;

BEGIN
END ProcType.
