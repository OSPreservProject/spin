(* Copyright (C) 1993, Digital Equipment Corporation           *)
(* All rights reserved.                                        *)
(* See the file COPYRIGHT for a full description.              *)
(*                                                             *)
(* Last modified on Thu Jan 26 14:37:38 PST 1995 by kalsow     *)
(*      modified on Tue May 25 14:22:35 PDT 1993 by muller     *)

(*
 * HISTORY
 * 20-Jul-96  Wilson Hsieh (whsieh) at the University of Washington
 *	support for emitting debug info for ALIGNED FOR types
 *
 * 13-Feb-96  Wilson Hsieh (whsieh) at the University of Washington
 *	fixed comments in check_align and check_size -- they need to pop
 *	 the codegen stack an extra time
 *
 * 06-Feb-96  Wilson Hsieh (whsieh) at the University of Washington
 *	renamed align_fault IR opcode to check_align
 *
 * 05-Feb-96  Wilson Hsieh (whsieh) at the University of Washington
 *	added check_align for VIEW alignment fault
 *
 * 26-Jan-96  Wilson Hsieh (whsieh) at the University of Washington
 *	changed check_size so that it calls a different IR routine,
 *	so that VIEW size errors generate a distinct fault
 *
 * 13-Nov-95  Wilson Hsieh (whsieh) at the University of Washington
 *	added check_size for VIEW
 *
 *)

MODULE M3CG_Wr;

IMPORT Wr, Text, IntRefTbl;
IMPORT M3Buf, M3ID, M3CG, M3CG_Ops, Target, TInt AS TargetInt, TFloat;

FROM M3CG IMPORT Name, ByteOffset, TypeUID, CallingConvention;
FROM M3CG IMPORT BitSize, ByteSize, Alignment, Frequency;
FROM M3CG IMPORT Var, Proc, Label, Sign, BitOffset, No_label;
FROM M3CG IMPORT Type, ZType, AType, RType, IType, MType;

TYPE WrVar    = Var    OBJECT tag: INTEGER END;
TYPE WrProc   = Proc   OBJECT tag: INTEGER END;

TYPE
  RuntimeHook = REF RECORD  name: Name;  var: Var;  offset: ByteOffset;  END;

TYPE
  U = M3CG.T OBJECT
        wr            : Wr.T := NIL;
        buf           : M3Buf.T := NIL;
        buf_len       : INTEGER := 0;
        runtime       : IntRefTbl.T := NIL;  (* Name -> RuntimeHook *)
        next_label_id := 1;
        next_var      := 1;
        next_proc     := 1;
        next_scope    := 1;
      OVERRIDES
        next_label := next_label;
        set_error_handler := set_error_handler;
        begin_unit := begin_unit;
        end_unit   := end_unit;
        import_unit := import_unit;
        export_unit := export_unit;
        set_source_file := set_source_file;
        set_source_line := set_source_line;
        declare_typename := declare_typename;
        declare_array := declare_array;
        declare_open_array := declare_open_array;
        declare_enum := declare_enum;
        declare_enum_elt := declare_enum_elt;
        declare_packed  := declare_packed;
        declare_aligned  := declare_aligned;
        declare_record := declare_record;
        declare_field := declare_field;
        declare_set := declare_set;
        declare_subrange := declare_subrange;
        declare_pointer := declare_pointer;
        declare_indirect := declare_indirect;
        declare_proctype := declare_proctype;
        declare_formal := declare_formal;
        declare_raises := declare_raises;
        declare_object := declare_object;
        declare_method := declare_method;
        declare_opaque := declare_opaque;
        reveal_opaque := reveal_opaque;
        set_runtime_hook := set_runtime_hook;
        get_runtime_hook := get_runtime_hook;
        import_global  := import_global;
        declare_segment := declare_segment;
        bind_segment := bind_segment;
        declare_global := declare_global;
        declare_constant := declare_constant;
        declare_local  := declare_local;
        declare_param  := declare_param;
        declare_temp   := declare_temp;
        free_temp := free_temp;
        declare_exception := declare_exception;
        begin_init := begin_init;
        end_init := end_init;
        init_int := init_int;
        init_proc := init_proc;
        init_label := init_label;
        init_var := init_var;
        init_offset := init_offset;
        init_chars := init_chars;
        init_float := init_float;
        import_procedure := import_procedure;
        declare_procedure := declare_procedure;
        begin_procedure := begin_procedure;
        end_procedure := end_procedure;
        begin_block := begin_block;
        end_block := end_block;
        note_procedure_origin := note_procedure_origin;
        set_label := set_label;
        jump := jump;
        if_true  := if_true;
        if_false := if_false;
        if_eq := if_eq;
        if_ne := if_ne;
        if_gt := if_gt;
        if_ge := if_ge;
        if_lt := if_lt;
        if_le := if_le;
        case_jump := case_jump;
        exit_proc := exit_proc;
        load  := load;
        store := store;
        store_ref := store_ref;
        load_address := load_address;
        load_indirect := load_indirect;
        store_indirect := store_indirect;
        store_ref_indirect := store_ref_indirect;
        load_nil      := load_nil;
        load_integer  := load_integer;
        load_float    := load_float;
        eq       := eq;
        ne       := ne;
        gt       := gt;
        ge       := ge;
        lt       := lt;
        le       := le;
        add      := add;
        subtract := subtract;
        multiply := multiply;
        divide   := divide;
        div      := div;
        mod      := mod;
        negate   := negate;
        abs      := abs;
        max      := max;
        min      := min;
        round    := round;
        trunc    := trunc;
        floor    := floor;
        ceiling  := ceiling;
        cvt_float := cvt_float;
        set_union          := set_union;
        set_difference     := set_difference;
        set_intersection   := set_intersection;
        set_sym_difference := set_sym_difference;
        set_member         := set_member;
        set_eq       := set_eq;
        set_ne       := set_ne;
        set_gt       := set_gt;
        set_ge       := set_ge;
        set_lt       := set_lt;
        set_le       := set_le;
        set_range    := set_range;
        set_singleton := set_singleton;
        not := not;
        and := and;
        or  := or;
        xor := xor;
        shift        := shift;
        shift_left   := shift_left;
        shift_right  := shift_right;
        rotate       := rotate;
        rotate_left  := rotate_left;
        rotate_right := rotate_right;
        extract := extract;
        extract_n := extract_n;
        extract_mn := extract_mn;
        insert  := insert;
        insert_n  := insert_n;
        insert_mn  := insert_mn;
        swap := swap;
        pop  := pop;
        copy := copy;
        copy_n := copy_n;
        zero := zero;
        zero_n := zero_n;
        loophole := loophole;
        assert_fault := assert_fault;
        narrow_fault := narrow_fault;
        return_fault := return_fault;
        case_fault := case_fault;
        typecase_fault := typecase_fault;
        check_nil := check_nil;
        check_lo := check_lo;
        check_size := check_size;
        check_align := check_align;
        check_hi := check_hi;
        check_range := check_range;
        check_index := check_index;
        check_eq := check_eq;
        add_offset := add_offset;
        index_address := index_address;
        start_call_direct := start_call_direct;
        call_direct := call_direct;
        start_call_indirect := start_call_indirect;
        call_indirect := call_indirect;
        pop_param := pop_param;
        pop_struct := pop_struct;
        pop_static_link := pop_static_link;
        load_procedure := load_procedure;
        load_static_link := load_static_link;
        comment := comment;
      END;
        

(*------------------------------------------------------------------- I/O ---*)

PROCEDURE NL (u: U) =
  BEGIN
    OutT (u, Target.EOL);
  END NL;

PROCEDURE Cmd (u: U; cmd: TEXT) =
  VAR len := Text.Length (cmd);
  BEGIN
    OutC (u, '\t');
    OutT (u, cmd);
    OutC (u, '\t');
    IF (len < 8) THEN OutC (u, '\t'); END;

    (****
    FOR i := 0 TO 14-len DO OutC (u, ' ') END;
    OutC (u, ' ');
    OutC (u, ' ');
    ***)
  END Cmd;

PROCEDURE ZName (u: U;  n: Name) =
  BEGIN
    OutC (u, ' ');
    IF (n = M3ID.NoID)
      THEN OutC (u, '*');
      ELSE OutN (u, n);
    END;
  END ZName;

PROCEDURE VName (u: U;  v: Var) =
  BEGIN
    TYPECASE v OF
    | NULL     => OutT (u, " *");
    | WrVar(x) => OutT (u, " v.");  OutI (u, x.tag);
    ELSE          OutT (u, " v.???");
    END;
  END VName;

PROCEDURE PName (u: U;  p: Proc) =
  BEGIN
    TYPECASE p OF
    | NULL      => OutT (u, " *");
    | WrProc(x) => OutT (u, " p.");  OutI (u, x.tag);
    ELSE           OutT (u, " p.???");
    END;
  END PName;

PROCEDURE TName (u: U;  t: Type) =
  CONST type_names = ARRAY Type OF TEXT {
                       " Addr", " Word", " Int",
                       " Reel", " LReel", " XReel",
                       " Int.8", " Int.16", " Int.32", " Int.32D",
                       " Word.8", " Word.16", " Word.32", " Word.32D",
                       " Struct", " Void"
                     };
  BEGIN
    OutT (u, type_names[t]);
  END TName;

PROCEDURE Flt (u: U;  READONLY f: Target.Float) =
  CONST FType = ARRAY Target.Precision OF TEXT { " R ", " L ", " X " };
  VAR
    buf : ARRAY [0..BITSIZE (Target.Extended)] OF CHAR;
    len := TFloat.ToChars (f, buf);
  BEGIN
    OutT (u, FType [TFloat.Prec (f)]);
    OutS (u, SUBARRAY (buf, 0, len));
  END Flt;

PROCEDURE Bool (u: U;  b: BOOLEAN) =
  CONST Tags = ARRAY BOOLEAN OF CHAR { 'F', 'T' };
  BEGIN
    OutC (u, ' ');
    OutC (u, Tags[b]);
  END Bool;

PROCEDURE Lab (u: U;  i: Label) =
  BEGIN
    OutC (u, ' ');
    IF (i = No_label)
      THEN OutC (u, '*');
      ELSE OutT (u, "L."); OutI (u, i);
    END;
  END Lab;

PROCEDURE Tipe (u: U;  t: TypeUID) =
  BEGIN
    OutT (u, " ");
    OutI (u, t);
  END Tipe;

PROCEDURE Int (u: U;  i: INTEGER) =
  BEGIN
    OutC (u, ' ');
    OutI (u, i);
  END Int;

PROCEDURE TInt (u: U;  READONLY i: Target.Int) =
  VAR
    buf : ARRAY [0..BITSIZE (Target.Integer)] OF CHAR;
    len := TargetInt.ToChars (i, buf);
  BEGIN
    OutC (u, ' ');
    OutS (u, SUBARRAY (buf, 0, len));
  END TInt;

PROCEDURE BInt (u: U;  i: INTEGER) =
  BEGIN
    Int (u, i);
     (* since the reader doesn't know how to read 'bytes+bits' *)
  END BInt;

(*********
PROCEDURE BInt (u: U;  i: INTEGER) =
  VAR x := i MOD Target.Byte;
      y := i DIV Target.Byte;
  BEGIN
    IF (x = 0)
      THEN Int (u, y);
      ELSE Int (u, y);  OutC (u, '+');  OutI (u, x);
    END;
  END BInt;
***************)

CONST
  VanillaChars = SET OF CHAR { ' ', '!', '#' .. '[', ']' .. '~' };
  Digits = ARRAY [0..7] OF CHAR { '0', '1', '2', '3', '4', '5', '6', '7' };

PROCEDURE Txt (u: U;  t: TEXT) =
  VAR c: CHAR;
  BEGIN
    OutC (u, ' ');
    IF (t = NIL) THEN
      OutC (u, '*');
      RETURN;
    END;
    OutC (u, '"');
    FOR i := 0 TO Text.Length (t)-1 DO
      c := Text.GetChar (t, i);
      IF (c IN VanillaChars) THEN
        OutC (u, c);
      ELSE
        OutC (u, '\\');
        OutC (u, Digits [ORD(c) DIV 64]);
        OutC (u, Digits [ORD(c) MOD 64 DIV 8]);
        OutC (u, Digits [ORD(c) MOD 8]);
      END;
    END;
    OutC (u, '"');
  END Txt;

(*--------------------------------------------------------- low level I/O ---*)

PROCEDURE Flush (u: U) =
  BEGIN
    M3Buf.Flush (u.buf, u.wr);
    u.buf_len := 0;
  END Flush;

PROCEDURE OutC (u: U;  c: CHAR) =
  BEGIN
    M3Buf.PutChar (u.buf, c);
    INC (u.buf_len);
    IF (u.buf_len >= 1024) THEN Flush (u) END;
  END OutC;

PROCEDURE OutT (u: U;  txt: TEXT) =
  BEGIN
    M3Buf.PutText (u.buf, txt);
    INC (u.buf_len, Text.Length (txt));
    IF (u.buf_len >= 1024) THEN Flush (u) END;
  END OutT;

PROCEDURE OutN (u: U;  n: Name) =
  BEGIN
    M3ID.Put (u.buf, n);
    INC (u.buf_len, 10); (* we don't really care if it's accurate *)
    IF (u.buf_len >= 1024) THEN Flush (u) END;
  END OutN;

PROCEDURE OutS (u: U;  READONLY buf: ARRAY OF CHAR) =
  BEGIN
    M3Buf.PutSub (u.buf, buf);
    INC (u.buf_len, NUMBER (buf));
    IF (u.buf_len >= 1024) THEN Flush (u) END;
  END OutS;

PROCEDURE OutI  (u: U;  i: INTEGER) =
  BEGIN
    M3Buf.PutInt (u.buf, i);
    INC (u.buf_len, 4); (* we don't really care if it's accurate *)
    IF (u.buf_len >= 1024) THEN Flush (u) END;
  END OutI;

(*---------------------------------------------------------------------------*)

PROCEDURE New (output: Wr.T): M3CG.T =
  VAR mbuf := M3Buf.New ();
  BEGIN
    M3Buf.AttachDrain (mbuf, output);
    RETURN NEW (U, wr := output, buf := mbuf, buf_len := 0,
                runtime := NEW (IntRefTbl.Default).init (20));
  END New;

(*----------------------------------------------------------- ID counters ---*)

PROCEDURE next_label (u: U;  n: INTEGER := 1): Label =
  VAR x := u.next_label_id;
  BEGIN
    INC (u.next_label_id, n);
    RETURN x;
  END next_label;

(*------------------------------------------------ READONLY configuration ---*)

PROCEDURE set_error_handler (<*UNUSED*> u: U;
                             <*UNUSED*> p: M3CG_Ops.ErrorHandler) =
  BEGIN
    (* skip -- we don't generate any errors *)
  END set_error_handler;

(*----------------------------------------------------- compilation units ---*)

PROCEDURE begin_unit (u: U;  optimize : INTEGER) =
  (* called before any other method to initialize the compilation unit *)
  BEGIN
    Cmd (u, "begin_unit");
    Int (u, optimize);
    NL  (u);
  END begin_unit;

PROCEDURE end_unit   (u: U) =
  (* called after all other methods to finalize the unit and write the
     resulting object *)
  BEGIN
    Cmd (u, "end_unit");
    NL  (u);
    Flush (u);
  END end_unit;

PROCEDURE import_unit (u: U;  n: Name) =
  (* note that the current compilation unit imports the interface 'n' *)
  BEGIN
    Cmd   (u, "import_unit");
    ZName (u, n);
    NL    (u);
  END import_unit;

PROCEDURE export_unit (u: U;  n: Name) =
  (* note that the current compilation unit exports the interface 'n' *)
  BEGIN
    Cmd   (u, "export_unit");
    ZName (u, n);
    NL    (u);
  END export_unit;

(*------------------------------------------------ debugging line numbers ---*)

PROCEDURE set_source_file (u: U; file: TEXT) =
  (* Sets the current source file name.  Subsequent statements
     and expressions are associated with this source location. *)
  BEGIN
    OutT (u, "\t\t\t\t\t-----FILE ");
    OutT (u, file);
    OutT (u, "  -----");
    OutT (u, Target.EOL);
  END set_source_file;

PROCEDURE set_source_line (u: U; line: INTEGER) =
  (* Sets the current source line number.  Subsequent statements
   and expressions are associated with this source location. *)
  BEGIN
    OutT (u, "\t\t\t\t\t-----LINE");
    Int  (u, line);
    OutT (u, "  -----");
    OutT (u, Target.EOL);
  END set_source_line;


(*------------------------------------------- debugging type declarations ---*)

PROCEDURE declare_typename (u: U;  t: TypeUID;  n: Name) =
  BEGIN
    Cmd   (u, "declare_typename");
    Tipe  (u, t);
    ZName (u, n);
    NL    (u);
  END declare_typename;

PROCEDURE declare_array (u: U;  t, index, elt: TypeUID;  s: BitSize) =
  BEGIN
    Cmd  (u, "declare_array");
    Tipe (u, t);
    Tipe (u, index);
    Tipe (u, elt);
    BInt (u, s);
    NL   (u);
  END declare_array;

PROCEDURE declare_open_array (u: U;  t, elt: TypeUID;  s: BitSize) =
  BEGIN
    Cmd  (u, "declare_open_array");
    Tipe (u, t);
    Tipe (u, elt);
    BInt (u, s);
    NL   (u);
  END declare_open_array;

PROCEDURE declare_enum (u: U;  t: TypeUID;  n_elts: INTEGER;  s: BitSize) =
  BEGIN
    Cmd  (u, "declare_enum");
    Tipe (u, t); 
    Int  (u, n_elts);
    BInt (u, s);
    NL   (u);
  END declare_enum;

PROCEDURE declare_enum_elt (u: U;  n: Name) =
  BEGIN
    Cmd   (u, "declare_enum_elt");
    ZName (u, n);
    NL    (u);
  END declare_enum_elt;

PROCEDURE declare_packed  (u: U;  t: TypeUID;  s: BitSize;  base: TypeUID) =
  BEGIN
    Cmd  (u, "declare_packed");
    Tipe (u, t);
    BInt (u, s);
    Tipe (u, base);
    NL   (u);
  END declare_packed;

PROCEDURE declare_aligned  (u: U;  t: TypeUID;  size, align: BitSize;
                            base: TypeUID) =
  BEGIN
    Cmd  (u, "declare_aligned");
    Tipe (u, t);
    BInt (u, size);
    BInt (u, align);
    Tipe (u, base);
    NL   (u);
  END declare_aligned;

PROCEDURE declare_record (u: U; t: TypeUID;  s: BitSize;
                          n_fields: INTEGER)=
  BEGIN
    Cmd  (u, "declare_record");
    Tipe (u, t);
    BInt (u, s);
    Int  (u, n_fields);
    NL   (u);
  END declare_record;

PROCEDURE declare_field (u: U;  n: Name;  o: BitOffset;  s: BitSize;
                         t: TypeUID)=
  BEGIN
    Cmd   (u, "declare_field");
    ZName (u, n);
    BInt  (u, o);
    BInt  (u, s);
    Tipe  (u, t);
    NL    (u);
  END declare_field;

PROCEDURE declare_set (u: U;  t, domain: TypeUID;  s: BitSize) =
  BEGIN
    Cmd  (u, "declare_set");
    Tipe (u, t);
    Tipe (u, domain);
    BInt (u, s);
    NL    (u);
  END declare_set;

PROCEDURE declare_subrange (u: U; t, domain: TypeUID;
                            READONLY min, max: Target.Int;
                            s: BitSize) =
  BEGIN
    Cmd  (u, "declare_subrange");
    Tipe (u, t);
    Tipe (u, domain);
    TInt (u, min);
    TInt (u, max); 
    BInt (u, s);
    NL   (u);
  END declare_subrange;

PROCEDURE declare_pointer (u: U;  t, target: TypeUID;  brand: TEXT;
                           traced: BOOLEAN) =
  BEGIN
    Cmd  (u, "declare_pointer");
    Tipe (u, t);
    Tipe (u, target);
    Txt  (u, brand);
    Bool (u, traced);
    NL   (u);
  END declare_pointer;


PROCEDURE declare_indirect (u: U;  t, target: TypeUID) =
  BEGIN
    Cmd  (u, "declare_indirect");
    Tipe (u, t);
    Tipe (u, target);
    NL   (u);
  END declare_indirect;


PROCEDURE declare_proctype (u: U;  t: TypeUID;  n_formals: INTEGER;
                            result: TypeUID;  n_raises: INTEGER;
                            cc: CallingConvention) =
  BEGIN
    Cmd  (u, "declare_proctype");
    Tipe (u, t);
    Int  (u, n_formals);
    Tipe (u, result);
    Int  (u, n_raises);
    Int  (u, cc.m3cg_id);
    NL   (u);
  END declare_proctype;

PROCEDURE declare_formal (u: U;  n: Name;  t: TypeUID) =
  BEGIN
    Cmd   (u, "declare_formal");
    ZName (u, n);
    Tipe  (u, t);
    NL    (u);
  END declare_formal;

PROCEDURE declare_raises (u: U;  n: Name) =
  BEGIN
    Cmd   (u, "declare_raises");
    ZName (u, n);
    NL    (u);
  END declare_raises;


PROCEDURE declare_object (u: U;  t, super: TypeUID;
                          brand: TEXT;  traced: BOOLEAN;
                          n_fields, n_methods: INTEGER;
                          field_size: BitSize) =
  BEGIN
    Cmd  (u, "declare_object");
    Tipe (u, t);
    Tipe (u, super);
    Txt  (u, brand);
    Bool (u, traced);
    Int  (u, n_fields);  
    Int  (u, n_methods);
    BInt (u, field_size);
    NL   (u);
  END declare_object;

PROCEDURE declare_method (u: U;  n: Name;  signature: TypeUID) =
  BEGIN
    Cmd   (u, "declare_method");
    ZName (u, n);
    Tipe  (u, signature);
    NL    (u);
  END declare_method;

PROCEDURE declare_opaque (u: U;  t, super: TypeUID) =
  BEGIN
    Cmd   (u, "declare_opaque");
    Tipe  (u, t);
    Tipe  (u, super);
    NL    (u);
  END declare_opaque;

PROCEDURE reveal_opaque (u: U;  lhs, rhs: TypeUID) =
  BEGIN
    Cmd   (u, "reveal_opaque");
    Tipe  (u, lhs);
    Tipe  (u, rhs);
    NL    (u);
  END reveal_opaque;

PROCEDURE declare_exception (u: U;  n: Name;  arg_type: TypeUID;
                           raise_proc: BOOLEAN;  base: Var;  offset: INTEGER) =
  BEGIN
    Cmd   (u, "declare_exception");
    ZName (u, n);
    Tipe  (u, arg_type);
    Bool  (u, raise_proc);
    VName (u, base);
    Int   (u, offset);
    NL    (u);
  END declare_exception;

(*--------------------------------------------------------- runtime hooks ---*)

PROCEDURE set_runtime_hook (u: U;  n: Name;  v: Var;  o: ByteOffset) =
  VAR e := NEW (RuntimeHook, name := n, var := v,  offset := o);
  BEGIN
    Cmd   (u, "set_runtime_hook");
    ZName (u, n);
    VName (u, v);
    Int   (u, o);
    NL    (u);
    EVAL u.runtime.put (n, e);
  END set_runtime_hook;

PROCEDURE get_runtime_hook (u: U;  n: Name; VAR v: Var; VAR o: ByteOffset) =
  VAR ref: REFANY;  e: RuntimeHook;
  BEGIN
    (* no ASCII output is generated ... *)
    IF u.runtime.get (n, ref) THEN
      e := ref;
      v := e.var;
      o := e.offset;
    ELSE
      v := NIL;
      o := 0;
    END;
  END get_runtime_hook;

(*------------------------------------------------- variable declarations ---*)

PROCEDURE NewVar (u: U): Var =
  VAR v := NEW (WrVar, tag := u.next_var);
  BEGIN
    INC (u.next_var);
    RETURN v;
  END NewVar;

PROCEDURE import_global (u: U;  n: Name;  s: ByteSize;  a: Alignment;
                         t: Type;  m3t: TypeUID): Var =
  VAR v := NewVar (u);
  BEGIN
    Cmd   (u, "import_global");
    ZName (u, n);
    Int   (u, s);
    Int   (u, a);
    TName (u, t);
    Tipe  (u, m3t);
    VName (u, v);
    NL    (u);
    RETURN v;
  END import_global;

PROCEDURE declare_segment (u: U;  n: Name;  m3t: TypeUID): Var =
  VAR v := NewVar (u);
  BEGIN
    Cmd   (u, "declare_segment");
    ZName (u, n);
    Tipe  (u, m3t);
    VName (u, v);
    NL    (u);
    RETURN v;
  END declare_segment;

PROCEDURE bind_segment (u: U;  seg: Var;  s: ByteSize;  a: Alignment;
                        t: Type;  exported, inited: BOOLEAN) =
  BEGIN
    Cmd   (u, "bind_segment");
    VName (u, seg);
    Int   (u, s);
    Int   (u, a);
    TName (u, t);
    Bool  (u, exported);
    Bool  (u, inited);
    NL    (u);
  END bind_segment;

PROCEDURE declare_global (u: U;  n: Name;  s: ByteSize;  a: Alignment;
                     t: Type;  m3t: TypeUID;  exported, inited: BOOLEAN): Var =
  VAR v := NewVar (u);
  BEGIN
    Cmd   (u, "declare_global");
    ZName (u, n);
    Int   (u, s);
    Int   (u, a);
    TName (u, t);
    Tipe  (u, m3t);
    Bool  (u, exported);
    Bool  (u, inited);
    VName (u, v);
    NL    (u);
    RETURN v;
  END declare_global;

PROCEDURE declare_constant (u: U;  n: Name;  s: ByteSize;  a: Alignment;
                     t: Type;  m3t: TypeUID;  exported, inited: BOOLEAN): Var =
  VAR v := NewVar (u);
  BEGIN
    Cmd   (u, "declare_constant");
    ZName (u, n);
    Int   (u, s);  
    Int   (u, a);  
    TName (u, t);
    Tipe  (u, m3t);
    Bool  (u, exported);
    Bool  (u, inited);
    VName (u, v);
    NL    (u);
    RETURN v;
  END declare_constant;

PROCEDURE declare_local (u: U;  n: Name;  s: ByteSize;  a: Alignment;
                         t: Type;  m3t: TypeUID;  in_memory, up_level: BOOLEAN;
                         f: Frequency): Var =
  VAR v := NewVar (u);
  BEGIN
    Cmd   (u, "declare_local");
    ZName (u, n);
    Int   (u, s);  
    Int   (u, a);  
    TName (u, t);
    Tipe  (u, m3t);
    Bool  (u, in_memory);
    Bool  (u, up_level);
    Int   (u, f);
    VName (u, v);
    NL    (u);
    RETURN v;
  END declare_local;

PROCEDURE declare_param (u: U;  n: Name;  s: ByteSize;  a: Alignment;
                         t: Type;  m3t: TypeUID;  in_memory, up_level: BOOLEAN;
                         f: Frequency): Var =
  VAR v := NewVar (u);
  BEGIN
    Cmd   (u, "declare_param");
    ZName (u, n);
    Int   (u, s);  
    Int   (u, a);  
    TName (u, t);
    Tipe  (u, m3t);
    Bool  (u, in_memory);
    Bool  (u, up_level);
    Int   (u, f);
    VName (u, v);
    NL    (u);
    RETURN v;
  END declare_param;

PROCEDURE declare_temp   (u: U;  s: ByteSize;  a: Alignment;  t: Type;
                          in_memory:BOOLEAN): Var =
  VAR v := NewVar (u);
  BEGIN
    Cmd   (u, "declare_temp");
    Int   (u, s);  
    Int   (u, a);
    TName (u, t);
    Bool  (u, in_memory);
    VName (u, v);
    NL    (u);
    RETURN v;
  END declare_temp;

PROCEDURE free_temp (u: U;  v: Var) =
  BEGIN
    Cmd   (u, "free_temp");
    VName (u, v);
    NL    (u);
  END free_temp;

(*---------------------------------------- static variable initialization ---*)

PROCEDURE begin_init (u: U;  v: Var) =
  BEGIN
    Cmd   (u, "begin_init");
    VName (u, v);
    NL    (u);
  END begin_init;

PROCEDURE end_init (u: U;  v: Var) =
  BEGIN
    Cmd   (u, "end_init");
    VName (u, v);
    NL    (u);
  END end_init;

PROCEDURE init_int (u: U;  o: ByteOffset;  READONLY value: Target.Int;
                    t: Type) =
  BEGIN
    Cmd   (u, "init_int");
    Int   (u, o);
    TInt  (u, value);
    TName (u, t);
    NL    (u);
  END init_int;

PROCEDURE init_proc (u: U;  o: ByteOffset;  value: Proc) =
  BEGIN
    Cmd   (u, "init_proc");
    Int   (u, o);
    PName (u, value);
    NL    (u);
  END init_proc;

PROCEDURE init_label (u: U;  o: ByteOffset;  value: Label) =
  BEGIN
    Cmd   (u, "init_label");
    Int   (u, o);
    Lab   (u, value);
    NL    (u);
  END init_label;

PROCEDURE init_var (u: U;  o: ByteOffset;  value: Var;  bias: ByteOffset) =
  BEGIN
    Cmd   (u, "init_var");
    Int   (u, o);
    VName (u, value);
    Int   (u, bias);
    NL    (u);
  END init_var;

PROCEDURE init_offset (u: U;  o: ByteOffset;  value: Var) =
  BEGIN
    Cmd   (u, "init_offset");
    Int   (u, o);
    VName (u, value);
    NL    (u);
  END init_offset;

PROCEDURE init_chars (u: U;  o: ByteOffset;  value: TEXT) =
  BEGIN
    Cmd   (u, "init_chars");
    Int   (u, o);
    Txt   (u, value);
    NL    (u);
  END init_chars;

PROCEDURE init_float (u: U;  o: ByteOffset;  READONLY f: Target.Float) =
  BEGIN
    Cmd   (u, "init_float");
    Int   (u, o);
    Flt   (u, f);
    NL    (u);
  END init_float;

(*------------------------------------------------------------ procedures ---*)

PROCEDURE NewProc (u: U): Proc =
  VAR p := NEW (WrProc, tag := u.next_proc);
  BEGIN
    INC (u.next_proc);
    RETURN p;
  END NewProc;

PROCEDURE import_procedure (u: U;  n: Name;  n_params: INTEGER;
                          ret_type: Type;  cc: CallingConvention): Proc =
  VAR p := NewProc (u);
  BEGIN
    Cmd   (u, "import_procedure");
    ZName (u, n);
    Int   (u, n_params);
    TName (u, ret_type);
    Int   (u, cc.m3cg_id);
    PName (u, p);
    NL    (u);
    RETURN p;
  END import_procedure;

PROCEDURE declare_procedure (u: U;  n: Name;  n_params: INTEGER;
                             return_type: Type;  lev: INTEGER;
                             cc: CallingConvention;
                             exported: BOOLEAN;  parent: Proc): Proc =
  VAR p := NewProc (u);
  BEGIN
    Cmd   (u, "declare_procedure");
    ZName (u, n);
    Int   (u, n_params);
    TName (u, return_type);
    Int   (u, lev);
    Int   (u, cc.m3cg_id);
    Bool  (u, exported);
    PName (u, parent);
    PName (u, p);
    NL    (u);
    RETURN p;
  END declare_procedure;

PROCEDURE begin_procedure (u: U;  p: Proc) =
  BEGIN
    Cmd   (u, "begin_procedure");
    PName (u, p);
    NL    (u);
  END begin_procedure;


PROCEDURE end_procedure (u: U;  p: Proc) =
  BEGIN
    Cmd   (u, "end_procedure");
    PName (u, p);
    NL    (u);
  END end_procedure;

PROCEDURE begin_block (u: U) =
  (* marks the beginning of a nested anonymous block *)
  BEGIN
    Cmd   (u, "begin_block");
    NL    (u);
  END begin_block;

PROCEDURE end_block (u: U) =
  (* marks the ending of a nested anonymous block *)
  BEGIN
    Cmd   (u, "end_block");
    NL    (u);
  END end_block;

PROCEDURE note_procedure_origin (u: U;  p: Proc) =
  BEGIN
    Cmd   (u, "note_procedure_origin");
    PName (u, p);
    NL    (u);
  END note_procedure_origin;

(*------------------------------------------------------------ statements ---*)

PROCEDURE set_label (u: U;  l: Label;  barrier: BOOLEAN) =
  (* define 'l' to be at the current pc *)
  BEGIN
    OutT  (u, ".");
    Lab   (u, l);
    Bool  (u, barrier);
    NL    (u);
  END set_label;

PROCEDURE jump (u: U; l: Label) =
  (* GOTO l *)
  BEGIN
    Cmd   (u, "jump");
    Lab   (u, l);
    NL    (u);
  END jump;

PROCEDURE if_true  (u: U; l: Label;  f: Frequency) =
  (* IF (s0.I # 0) GOTO l ; pop *)
  BEGIN
    Cmd   (u, "if_true");
    Lab   (u, l);
    Int   (u, f);
    NL    (u);
  END if_true;

PROCEDURE if_false (u: U; l: Label;  f: Frequency) =
  (* IF (s0.I = 0) GOTO l ; pop *)
  BEGIN
    Cmd   (u, "if_false");
    Lab   (u, l);
    Int   (u, f);
    NL    (u);
  END if_false;

PROCEDURE if_eq (u: U;  l: Label;  t: ZType;  f: Frequency) =
  (* IF (s1.t = s0.t) GOTO l ; pop(2) *)
  BEGIN
    Cmd   (u, "if_eq");
    Lab   (u, l);
    TName (u, t);
    Int   (u, f);
    NL    (u);
  END if_eq;

PROCEDURE if_ne (u: U;  l: Label;  t: ZType;  f: Frequency) =
  (* IF (s1.t # s0.t) GOTO l ; pop(2) *)
  BEGIN
    Cmd   (u, "if_ne");
    Lab   (u, l);
    TName (u, t);
    Int   (u, f);
    NL    (u);
  END if_ne;

PROCEDURE if_gt (u: U;  l: Label;  t: ZType;  f: Frequency) =
  (* IF (s1.t > s0.t) GOTO l ; pop(2) *)
  BEGIN
    Cmd   (u, "if_gt");
    Lab   (u, l);
    TName (u, t);
    Int   (u, f);
    NL    (u);
  END if_gt;

PROCEDURE if_ge (u: U;  l: Label;  t: ZType;  f: Frequency) =
  (* IF (s1.t >= s0.t) GOTO l ; pop(2) *)
  BEGIN
    Cmd   (u, "if_ge");
    Lab   (u, l);
    TName (u, t);
    Int   (u, f);
    NL    (u);
  END if_ge;

PROCEDURE if_lt (u: U;  l: Label;  t: ZType;  f: Frequency) =
  (* IF (s1.t < s0.t) GOTO l ; pop(2) *)
  BEGIN
    Cmd   (u, "if_lt");
    Lab   (u, l);
    TName (u, t);
    Int   (u, f);
    NL    (u);
  END if_lt;

PROCEDURE if_le (u: U;  l: Label;  t: ZType;  f: Frequency) =
  (* IF (s1.t <= s0.t) GOTO l ; pop(2) *)
  BEGIN
    Cmd   (u, "if_le");
    Lab   (u, l);
    TName (u, t);
    Int   (u, f);
    NL    (u);
  END if_le;

PROCEDURE case_jump (u: U; READONLY labels: ARRAY OF Label) =
  (* "GOTO labels[s0.I] ; pop" with no range checking on s0.I *)
  BEGIN
    Cmd   (u, "case_jump");
    Int   (u, NUMBER(labels));
    FOR i := FIRST (labels) TO LAST (labels) DO  Lab (u, labels [i]);  END;
    NL    (u);
  END case_jump;

PROCEDURE exit_proc (u: U; t: Type) =
  (* Returns s0.t if the stack is non-empty, otherwise returns no value. *)
  BEGIN
    Cmd   (u, "exit_proc");
    TName (u, t);
    NL    (u);
  END exit_proc;

(*------------------------------------------------------------ load/store ---*)

PROCEDURE load  (u: U;  v: Var;  o: ByteOffset;  t: MType) =
  BEGIN
    Cmd   (u, "load");
    VName (u, v);
    Int   (u, o);  
    TName (u, t);
    NL    (u);
  END load;

PROCEDURE store  (u: U;  v: Var;  o: ByteOffset;  t: MType) =
  BEGIN
    Cmd   (u, "store");
    VName (u, v);
    Int   (u, o);  
    TName (u, t);
    NL    (u);
  END store;

PROCEDURE store_ref (u: U;  v: Var;  o: ByteOffset) =
  BEGIN
    Cmd   (u, "store_ref");
    VName (u, v);
    Int   (u, o);
    NL    (u);
  END store_ref;

PROCEDURE load_address (u: U;  v: Var;  o: ByteOffset) =
  BEGIN
    Cmd   (u, "load_address");
    VName (u, v);
    Int   (u, o);
    NL    (u);
  END load_address;

PROCEDURE load_indirect (u: U;  o: ByteOffset;  t: MType) =
  BEGIN
    Cmd   (u, "load_indirect");
    Int   (u, o);  
    TName (u, t);
    NL    (u);
  END load_indirect;

PROCEDURE store_indirect (u: U;  o: ByteOffset;  t: MType) =
  BEGIN
    Cmd   (u, "store_indirect");
    Int   (u, o);  
    TName (u, t);
    NL    (u);
  END store_indirect;


PROCEDURE store_ref_indirect (u: U;  o: ByteOffset;  var: BOOLEAN) =
  BEGIN
    Cmd   (u, "store_ref_indirect");
    Int   (u, o);
    Bool  (u, var);
    NL    (u);
  END store_ref_indirect;


(*-------------------------------------------------------------- literals ---*)

PROCEDURE load_nil (u: U) =
  (* push ; s0.A := a *)
  BEGIN
    Cmd   (u, "load_nil");
    NL    (u);
  END load_nil;

PROCEDURE load_integer  (u: U;  READONLY i: Target.Int) =
  (* push ; s0.I := i *)
  BEGIN
    Cmd   (u, "load_integer");
    TInt  (u, i);
    NL    (u);
  END load_integer;

PROCEDURE load_float    (u: U;  READONLY f: Target.Float) =
  (* push ; s0.t := f *)
  BEGIN
    Cmd   (u, "load_float");
    Flt   (u, f);
    NL    (u);
  END load_float;

(*------------------------------------------------------------ arithmetic ---*)

PROCEDURE eq (u: U;  t: ZType) =
  (* s1.I := (s1.t = s0.t)  ; pop *)
  BEGIN
    Cmd   (u, "eq");
    TName (u, t);
    NL    (u);
  END eq;

PROCEDURE ne (u: U;  t: ZType) =
  (* s1.I := (s1.t # s0.t)  ; pop *)
  BEGIN
    Cmd   (u, "ne");
    TName (u, t);
    NL    (u);
  END ne;

PROCEDURE gt (u: U;  t: ZType) =
  (* s1.I := (s1.t > s0.t)  ; pop *)
  BEGIN
    Cmd   (u, "gt");
    TName (u, t);
    NL    (u);
  END gt;

PROCEDURE ge (u: U;  t: ZType) =
  (* s1.I := (s1.t >= s0.t) ; pop *)
  BEGIN
    Cmd   (u, "ge");
    TName (u, t);
    NL    (u);
  END ge;

PROCEDURE lt (u: U;  t: ZType) =
  (* s1.I := (s1.t < s0.t)  ; pop *)
  BEGIN
    Cmd   (u, "lt");
    TName (u, t);
    NL    (u);
  END lt;

PROCEDURE le (u: U;  t: ZType) =
  (* s1.I := (s1.t <= s0.t) ; pop *)
  BEGIN
    Cmd   (u, "le");
    TName (u, t);
    NL    (u);
  END le;

PROCEDURE add (u: U;  t: AType) =
  (* s1.t := s1.t + s0.t ; pop *)
  BEGIN
    Cmd   (u, "add");
    TName (u, t);
    NL    (u);
  END add;

PROCEDURE subtract (u: U;  t: AType) =
  (* s1.t := s1.t - s0.t ; pop *)
  BEGIN
    Cmd   (u, "subtract");
    TName (u, t);
    NL    (u);
  END subtract;

PROCEDURE multiply (u: U;  t: AType) =
  (* s1.t := s1.t * s0.t ; pop *)
  BEGIN
    Cmd   (u, "multiply");
    TName (u, t);
    NL    (u);
  END multiply;

PROCEDURE divide (u: U;  t: RType) =
  (* s1.t := s1.t / s0.t ; pop *)
  BEGIN
    Cmd   (u, "divide");
    TName (u, t);
    NL    (u);
  END divide;

CONST SignName = ARRAY Sign OF TEXT { " P", " N", " X" };

PROCEDURE div (u: U;  t: IType;  a, b: Sign) =
  (* s1.t := s1.t DIV s0.t ; pop *)
  BEGIN
    Cmd   (u, "div");
    TName (u, t);
    OutT  (u, SignName [a]);
    OutT  (u, SignName [b]);
    NL    (u);
  END div;

PROCEDURE mod (u: U;  t: IType;  a, b: Sign) =
  (* s1.t := s1.t MOD s0.t ; pop *)
  BEGIN
    Cmd   (u, "mod");
    TName (u, t);
    OutT  (u, SignName [a]);
    OutT  (u, SignName [b]);
    NL    (u);
  END mod;

PROCEDURE negate (u: U;  t: AType) =
  (* s0.t := - s0.t *)
  BEGIN
    Cmd   (u, "negate");
    TName (u, t);
    NL    (u);
  END negate;

PROCEDURE abs      (u: U;  t: AType) =
  (* s0.t := ABS (s0.t) (noop on Words) *)
  BEGIN
    Cmd   (u, "abs");
    TName (u, t);
    NL    (u);
  END abs;

PROCEDURE max      (u: U;  t: ZType) =
  (* s1.t := MAX (s1.t, s0.t) ; pop *)
  BEGIN
    Cmd   (u, "max");
    TName (u, t);
    NL    (u);
  END max;

PROCEDURE min      (u: U;  t: ZType) =
  (* s1.t := MIN (s1.t, s0.t) ; pop *)
  BEGIN
    Cmd   (u, "min");
    TName (u, t);
    NL    (u);
  END min;

PROCEDURE round    (u: U;  t: RType) =
  (* s0.I := ROUND (s0.t) *)
  BEGIN
    Cmd   (u, "round");
    TName (u, t);
    NL    (u);
  END round;

PROCEDURE trunc    (u: U;  t: RType) =
  (* s0.I := TRUNC (s0.t) *)
  BEGIN
    Cmd   (u, "trunc");
    TName (u, t);
    NL    (u);
  END trunc;

PROCEDURE floor    (u: U;  t: RType) =
  (* s0.I := FLOOR (s0.t) *)
  BEGIN
    Cmd   (u, "floor");
    TName (u, t);
    NL    (u);
  END floor;

PROCEDURE ceiling  (u: U;  t: RType) =
  (* s0.I := CEILING (s0.t) *)
  BEGIN
    Cmd   (u, "ceiling");
    TName (u, t);
    NL    (u);
  END ceiling;

PROCEDURE cvt_float (u: U;  t: AType;  x: RType) =
  (* s0.x := FLOAT (s0.t, x) *)
  BEGIN
    Cmd   (u, "cvt_float");
    TName (u, t);
    TName (u, x);
    NL    (u);
  END cvt_float;

(*------------------------------------------------------------------ sets ---*)

PROCEDURE set_union (u: U;  s: ByteSize) =
  (* s1.B := s1.B + s0.B ; pop *)
  BEGIN
    Cmd   (u, "set_union");
    Int   (u, s);
    NL    (u);
  END set_union;

PROCEDURE set_difference (u: U;  s: ByteSize) =
  (* s1.B := s1.B - s0.B ; pop *)
  BEGIN
    Cmd   (u, "set_difference");
    Int   (u, s);
    NL    (u);
  END set_difference;

PROCEDURE set_intersection (u: U;  s: ByteSize) =
  (* s1.B := s1.B * s0.B ; pop *)
  BEGIN
    Cmd   (u, "set_intersection");
    Int   (u, s);
    NL    (u);
  END set_intersection;

PROCEDURE set_sym_difference (u: U;  s: ByteSize) =
  (* s1.B := s1.B / s0.B ; pop *)
  BEGIN
    Cmd   (u, "set_sym_difference");
    Int   (u, s);
    NL    (u);
  END set_sym_difference;

PROCEDURE set_member       (u: U;  s: ByteSize) =
  (* s1.I := (s0.I IN s1.B) ; pop *)
  BEGIN
    Cmd   (u, "set_member");
    Int   (u, s);
    NL    (u);
  END set_member;

PROCEDURE set_eq       (u: U;  s: ByteSize) =
  (* s1.I := (s1.B = s0.B)  ; pop *)
  BEGIN
    Cmd   (u, "set_eq");
    Int   (u, s);
    NL    (u);
  END set_eq;

PROCEDURE set_ne (u: U;  s: ByteSize) =
  (* s1.I := (s1.B # s0.B)  ; pop *)
  BEGIN
    Cmd   (u, "set_ne");
    Int   (u, s);
    NL    (u);
  END set_ne;

PROCEDURE set_gt (u: U;  s: ByteSize) =
  (* s1.I := (s1.B > s0.B)  ; pop *)
  BEGIN
    Cmd   (u, "set_gt");
    Int   (u, s);
    NL    (u);
  END set_gt;

PROCEDURE set_ge (u: U;  s: ByteSize) =
  (* s1.I := (s1.B >= s0.B) ; pop *)
  BEGIN
    Cmd   (u, "set_ge");
    Int   (u, s);
    NL    (u);
  END set_ge;

PROCEDURE set_lt (u: U;  s: ByteSize) =
  (* s1.I := (s1.B < s0.B)  ; pop *)
  BEGIN
    Cmd   (u, "set_lt");
    Int   (u, s);
    NL    (u);
  END set_lt;

PROCEDURE set_le (u: U;  s: ByteSize) =
  (* s1.I := (s1.B <= s0.B) ; pop *)
  BEGIN
    Cmd   (u, "set_le");
    Int   (u, s);
    NL    (u);
  END set_le;

PROCEDURE set_range (u: U;  s: ByteSize) =
  (* s2.A [s1.I .. s0.I] := 1's; pop(3)*)
  BEGIN
    Cmd   (u, "set_range");
    Int   (u, s);
    NL    (u);
  END set_range;

PROCEDURE set_singleton (u: U;  s: ByteSize) =
  (* s1.A [s0.I] := 1; pop(2) *)
  BEGIN
    Cmd   (u, "set_singleton");
    Int   (u, s);
    NL    (u);
  END set_singleton;

(*------------------------------------------------- Word.T bit operations ---*)

PROCEDURE not (u: U) =
  (* s0.I := Word.Not (s0.I) *)
  BEGIN
    Cmd   (u, "not");
    TName (u, Type.Int);
    NL    (u);
  END not;

PROCEDURE and (u: U) =
  (* s1.I := Word.And (s1.I, s0.I) ; pop *)
  BEGIN
    Cmd   (u, "and");
    TName (u, Type.Int);
    NL    (u);
  END and;

PROCEDURE or  (u: U) =
  (* s1.I := Word.Or  (s1.I, s0.I) ; pop *)
  BEGIN
    Cmd   (u, "or");
    TName (u, Type.Int);
    NL    (u);
  END or;

PROCEDURE xor (u: U) =
  (* s1.I := Word.Xor (s1.I, s0.I) ; pop *)
  BEGIN
    Cmd   (u, "xor");
    TName (u, Type.Int);
    NL    (u);
  END xor;

PROCEDURE shift        (u: U) =
  (* s1.I := Word.Shift  (s1.I, s0.I) ; pop *)
  BEGIN
    Cmd   (u, "shift");
    TName (u, Type.Int);
    NL    (u);
  END shift;

PROCEDURE shift_left   (u: U) =
  (* s1.I := Word.Shift  (s1.I, s0.I) ; pop *)  
  BEGIN
    Cmd   (u, "shift_left");
    TName (u, Type.Int);
    NL    (u);
  END shift_left;

PROCEDURE shift_right  (u: U) =
  (* s1.I := Word.Shift  (s1.I, -s0.I) ; pop *)
  BEGIN
    Cmd   (u, "shift_right");
    TName (u, Type.Int);
    NL    (u);
  END shift_right;

PROCEDURE rotate       (u: U) =
  (* s1.I := Word.Rotate (s1.I, s0.I) ; pop *)
  BEGIN
    Cmd   (u, "rotate");
    TName (u, Type.Int);
    NL    (u);
  END rotate;

PROCEDURE rotate_left  (u: U) =
  (* s1.I := Word.Rotate (s1.I, s0.I) ; pop *)
  BEGIN
    Cmd   (u, "rotate_left");
    TName (u, Type.Int);
    NL    (u);
  END rotate_left;

PROCEDURE rotate_right (u: U) =
  (* s1.I := Word.Rotate (s1.I, -s0.I) ; pop *)
  BEGIN
    Cmd   (u, "rotate_right");
    TName (u, Type.Int);
    NL    (u);
  END rotate_right;

PROCEDURE extract (u: U;  sign: BOOLEAN) =
  (* s2.I := Word.Extract(s2.I, s1.I, s0.I);
     IF sign THEN SignExtend s2 END; pop(2) *)
  BEGIN
    Cmd   (u, "extract");
    Bool  (u, sign);
    NL    (u);
  END extract;

PROCEDURE extract_n (u: U;  sign: BOOLEAN;  n: INTEGER) =
  (* s1.I := Word.Extract(s1.I, s0.I, n);
     IF sign THEN SignExtend s1 END; pop(1) *)
  BEGIN
    Cmd   (u, "extract_n");
    Bool  (u, sign);
    Int   (u, n);
    NL    (u);
  END extract_n;

PROCEDURE extract_mn (u: U;  sign: BOOLEAN;  m, n: INTEGER) =
  (* s0.I := Word.Extract(s0.I, m, n);
     IF sign THEN SignExtend s0 END; *)
  BEGIN
    Cmd   (u, "extract_mn");
    Bool  (u, sign);
    Int   (u, m); 
    Int   (u, n);
    NL    (u);
  END extract_mn;

PROCEDURE insert  (u: U) =
  (* s3.I := Word.Insert (s3.I, s2.I, s1.I, s0.I) ; pop(3) *)
  BEGIN
    Cmd   (u, "insert");
    NL    (u);
  END insert;

PROCEDURE insert_n  (u: U;  n: INTEGER) =
  (* s2.I := Word.Insert (s2.I, s1.I, s0.I, n) ; pop(2) *)
  BEGIN
    Cmd   (u, "insert_n");
    Int   (u, n);
    NL    (u);
  END insert_n;

PROCEDURE insert_mn  (u: U;  m, n: INTEGER) =
  (* s1.I := Word.Insert (s1.I, s0.I, m, n) ; pop(2) *)
  BEGIN
    Cmd   (u, "insert_mn");
    Int   (u, m); 
    Int   (u, n);
    NL    (u);
  END insert_mn;

(*------------------------------------------------ misc. stack/memory ops ---*)

PROCEDURE swap (u: U;  a, b: Type) =
  (* tmp := s1 ; s1 := s0 ; s0 := tmp *)
  BEGIN
    Cmd   (u, "swap");
    TName (u, a);
    TName (u, b);
    NL    (u);
  END swap;

PROCEDURE pop  (u: U;  t: Type) =
  (* pop(1) (i.e. discard s0) *)
  BEGIN
    Cmd   (u, "pop");
    TName (u, t);
    NL    (u);
  END pop;

PROCEDURE copy_n (u: U;  t: MType;  overlap: BOOLEAN) =
  (* Mem[s2.A:s0.I] := Mem[s1.A:s0.I]; pop(3)*)
  BEGIN
    Cmd   (u, "copy_n");
    TName (u, t);
    Bool  (u, overlap);
    NL    (u);
  END copy_n;

PROCEDURE copy (u: U;  n: INTEGER;  t: MType;  overlap: BOOLEAN) =
  (* Mem[s2.A:sz] := Mem[s1.A:sz]; pop(2)*)
  BEGIN
    Cmd   (u, "copy");
    Int   (u, n);
    TName (u, t);
    Bool  (u, overlap);
    NL    (u);
  END copy;

PROCEDURE zero_n (u: U;  t: MType) =
  (* Mem[s1.A:s0.I] := 0; pop(2) *)
  BEGIN
    Cmd   (u, "zero_n");
    TName (u, t);
    NL    (u);
  END zero_n;

PROCEDURE zero (u: U;  n: INTEGER;  t: MType) =
  (* Mem[s1.A:sz] := 0; pop(1) *)
  BEGIN
    Cmd   (u, "zero");
    Int   (u, n);
    TName (u, t);
    NL    (u);
  END zero;

(*----------------------------------------------------------- conversions ---*)

PROCEDURE loophole (u: U;  from, two: ZType) =
  (* s0.to := LOOPHOLE(s0.from, to) *)
  BEGIN
    Cmd   (u, "loophole");
    TName (u, from);
    TName (u, two);
    NL    (u);
  END loophole;

(*------------------------------------------------ traps & runtime checks ---*)

PROCEDURE assert_fault (u: U) =
  BEGIN
    Cmd   (u, "assert_fault");
    NL    (u);
  END assert_fault;

PROCEDURE narrow_fault (u: U) =
  BEGIN
    Cmd   (u, "narrow_fault");
    NL    (u);
  END narrow_fault;

PROCEDURE return_fault (u: U) =
  BEGIN
    Cmd   (u, "return_fault");
    NL    (u);
  END return_fault;

PROCEDURE case_fault (u: U) =
  BEGIN
    Cmd   (u, "case_fault");
    NL    (u);
  END case_fault;

PROCEDURE typecase_fault (u: U) =
  (* Abort *)
  BEGIN
    Cmd   (u, "typecase_fault");
    NL    (u);
  END typecase_fault;


PROCEDURE check_nil (u: U) =
  (* IF (s0.A = NIL) THEN Abort *)
  BEGIN
    Cmd   (u, "check_nil");
    NL    (u);
  END check_nil;

PROCEDURE check_lo (u: U;  READONLY i: Target.Int) =
  (* IF (s0.I < i) THEN Abort *)
  BEGIN
    Cmd   (u, "check_lo");
    TInt (u, i);
    NL    (u);
  END check_lo;

PROCEDURE check_size (u: U;  READONLY i: Target.Int) =
  (* IF (s0.I < i) THEN Abort; Pop (1) *)
  BEGIN
    Cmd   (u, "check_size");
    TInt (u, i);
    NL    (u);
  END check_size;

PROCEDURE check_align (u: U;  READONLY i: Target.Int) =
  (* IF (s0.I BITAND i) THEN Abort; Pop (1) *)
  BEGIN
    Cmd   (u, "check_align");
    TInt (u, i);
    NL    (u);
  END check_align;

PROCEDURE check_hi (u: U;  READONLY i: Target.Int) =
  (* IF (i < s0.I) THEN Abort *)
  BEGIN
    Cmd   (u, "check_hi");
    TInt (u, i);
    NL    (u);
  END check_hi;

PROCEDURE check_range (u: U;  READONLY a, b: Target.Int) =
  (* IF (s0.I < a) OR (b < s0.I) THEN Abort *)
  BEGIN
    Cmd   (u, "check_range");
    TInt (u, a);
    TInt (u, b);
    NL    (u);
  END check_range;

PROCEDURE check_index (u: U) =
  BEGIN
    Cmd   (u, "check_index");
    NL    (u);
  END check_index;

PROCEDURE check_eq (u: U) =
  (* IF (s0.I # s1.I) THEN Abort;  Pop (2) *)
  BEGIN
    Cmd   (u, "check_eq");
    NL    (u);
  END check_eq;

(*---------------------------------------------------- address arithmetic ---*)

PROCEDURE add_offset (u: U; i: INTEGER) =
  (* s0.A := s0.A + i *)
  BEGIN
    Cmd   (u, "add_offset");
    Int   (u, i);
    NL    (u);
  END add_offset;

PROCEDURE index_address (u: U;  size: INTEGER) =
  (* s1.A := s1.A + s0.I * size ; pop *)
  BEGIN
    Cmd   (u, "index_address");
    Int   (u, size);
    NL    (u);
  END index_address;

(*------------------------------------------------------- procedure calls ---*)

PROCEDURE start_call_direct (u: U;  p: Proc;  lev: INTEGER;  t: Type) =
  (* begin a procedure call to a procedure at static level 'lev'. *)
  BEGIN
    Cmd   (u, "start_call_direct");
    PName (u, p);
    Int   (u, lev);  
    TName (u, t);
    NL    (u);
  END start_call_direct;

PROCEDURE start_call_indirect (u: U;  t: Type;  cc: CallingConvention) =
  (* begin a procedure call to a procedure at static level 'lev'. *)
  BEGIN
    Cmd   (u, "start_call_indirect");
    TName (u, t);
    Int   (u, cc.m3cg_id);
    NL    (u);
  END start_call_indirect;

PROCEDURE pop_param (u: U;  t: ZType) =
  (* pop s0 and make it the "next" paramter in the current call *)
  BEGIN
    Cmd   (u, "pop_param");
    TName (u, t);
    NL    (u);
  END pop_param;

PROCEDURE pop_struct (u: U;  s: ByteSize;  a: Alignment) =
  (* pop s0 and make it the "next" paramter in the current call *)
  BEGIN
    Cmd   (u, "pop_struct");
    Int   (u, s);
    Int   (u, a);
    NL    (u);
  END pop_struct;

PROCEDURE pop_static_link (u: U) =
  BEGIN
    Cmd   (u, "pop_static_link");
    NL    (u);
  END pop_static_link;

PROCEDURE call_direct (u: U; p: Proc;  t: Type) =
  (* call the procedure identified by block b.  The procedure
     returns a value of type t. *)
  BEGIN
    Cmd   (u, "call_direct");
    PName (u, p);
    TName (u, t);
    NL    (u);
  END call_direct;

PROCEDURE call_indirect (u: U;  t: Type;  cc: CallingConvention) =
  (* call the procedure whose address is in s0.A and pop s0.  The
     procedure returns a value of type t. *)
  BEGIN
    Cmd   (u, "call_indirect");
    TName (u, t);
    Int   (u, cc.m3cg_id);
    NL    (u);
  END call_indirect;

(*------------------------------------------- procedure and closure types ---*)

PROCEDURE load_procedure (u: U;  p: Proc) =
  (* push; s0.A := ADDR (p's body) *)
  BEGIN
    Cmd   (u, "load_procedure");
    PName (u, p);
    NL    (u);
  END load_procedure;

PROCEDURE load_static_link (u: U;  p: Proc) =
  (* push; s0.A := (static link needed to call p, NIL for top-level procs) *)
  BEGIN
    Cmd   (u, "load_static_link");
    PName (u, p);
    NL    (u);
  END load_static_link;

(*----------------------------------------------------------------- misc. ---*)

PROCEDURE comment (u: U;  a, b, c, d: TEXT := NIL) =
  VAR i: INTEGER := -1;
  BEGIN
    Cmt (u, a, i);
    Cmt (u, b, i);
    Cmt (u, c, i);
    Cmt (u, d, i);
    Cmt (u, Target.EOL, i);
  END comment;

PROCEDURE Cmt (u: U;  t: TEXT;  VAR width: INTEGER) =
  VAR ch: CHAR;
  BEGIN
    IF (t = NIL) THEN RETURN END;
    FOR i := 0 TO Text.Length (t) - 1 DO
      ch := Text.GetChar (t, i);
      IF (width = -1) THEN OutT (u, "\t# "); width := 0; END;
      IF (ch = '\r') THEN
        (* eat carriage returns *)
      ELSIF (ch = '\n') THEN
        OutT (u, Target.EOL);
        width := -1;
      ELSE
        OutC (u, ch);
      END;
    END;
  END Cmt;


BEGIN
END M3CG_Wr.
