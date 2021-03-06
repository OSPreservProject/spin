(* Copyright (C) 1993, Digital Equipment Corporation           *)
(* All rights reserved.                                        *)
(* See the file COPYRIGHT for a full description.              *)
(*                                                             *)
(* Last modified on Tue Dec 20 14:12:06 PST 1994 by kalsow     *)
(*      modified on Tue May 25 14:14:24 PDT 1993 by muller     *)

(*  Modula-3 code generator operations

   This interface defines the myriad operations that are available
   on an M3CG.T.
*)

(*
 * HISTORY
 * 20-Jul-96  Wilson Hsieh (whsieh) at the University of Washington
 *	support for emitting debug info for ALIGNED FOR types
 *
 * 05-Feb-96  Wilson Hsieh (whsieh) at the University of Washington
 *	added check_align for VIEW alignment fault
 *
 * 13-Nov-95  Wilson Hsieh (whsieh) at the University of Washington
 *	added check_size for VIEW
 *
 *)

INTERFACE M3CG_Ops;

IMPORT Target, M3CG;
FROM M3CG IMPORT Type, MType, IType, RType, AType, ZType, Sign;
FROM M3CG IMPORT Name, Var, Proc, Alignment, TypeUID, Label;
FROM M3CG IMPORT Frequency, CallingConvention;
FROM M3CG IMPORT BitSize, ByteSize, BitOffset, ByteOffset;

TYPE
  ErrorHandler = PROCEDURE (msg: TEXT);

REVEAL
  M3CG.T <: Public;

TYPE
  Public = OBJECT
(*------------------------------------------------ READONLY configuration ---*)

child: M3CG.T := NIL;
(* The default methods simply call the corresponding method in 'child',
   hence a vanilla 'M3CG.T' can be used as a filter where you override
   only the methods of interest. *)

METHODS
(*----------------------------------------------------------- ID counters ---*)

next_label (n: INTEGER := 1): Label;
(* reserve 'n' consecutive labels and return the first one *)

(*------------------------------------------------ READONLY configuration ---*)

set_error_handler (p: ErrorHandler);
(* 'p' is called to communicate failures (i.e. creating a stack or module
   that's too big) back to the front-end.  Client or implementation
   programming errors (bugs) result in crashes. *)

(*----------------------------------------------------- compilation units ---*)

begin_unit (optimize: INTEGER := 0);
(* called before any other method to initialize the compilation unit. *)

end_unit ();
(* called after all other methods to finalize the unit and write the
   resulting object.  *)

import_unit (n: Name);
export_unit (n: Name);
(* note that the current compilation unit imports/exports the interface 'n' *)

(*------------------------------------------------ debugging line numbers ---*)

set_source_file (file: TEXT);
set_source_line (line: INTEGER);
(* Sets the current source file and line number.  Subsequent statements
   and expressions are associated with this source location. *)

(*------------------------------------------- debugging type declarations ---*)

(* The debugging information for a type is identified by a gloablly unique
   32-bit id generated by the front-end.  The following methods generate
   the symbol table entries needed to describe Modula-3 types to the
   debugger. *)

declare_typename (t: TypeUID;  n: Name);
(* associate the name 'n' with type 't' *)

declare_array (t, index, elt: TypeUID;  s: BitSize);

declare_open_array (t, elt: TypeUID;  s: BitSize);
(* s describes the dope vector *)

declare_enum (t: TypeUID; n_elts: INTEGER;  s: BitSize);
declare_enum_elt (n: Name);

declare_packed  (t: TypeUID;  s: BitSize;  base: TypeUID);
declare_aligned  (t: TypeUID; size, align: BitSize; base: TypeUID);

declare_record (t: TypeUID;  s: BitSize;  n_fields: INTEGER);
declare_field (n: Name;  o: BitOffset;  s: BitSize;  t: TypeUID);

declare_set (t, domain: TypeUID;  s: BitSize);

declare_subrange (t,domain: TypeUID; READONLY min,max: Target.Int; s: BitSize);

declare_pointer (t, target: TypeUID;  brand: TEXT;  traced: BOOLEAN);
(* brand=NIL ==> t is unbranded *)

declare_indirect (t, target: TypeUID);
(* an automatically dereferenced pointer! (WITH variables, VAR formals, ...) *)

declare_proctype (t: TypeUID;  n_formals: INTEGER;
                  result: TypeUID;  n_raises: INTEGER;
                  cc: CallingConvention);
(* n_raises < 0 => RAISES ANY *)

declare_formal (n: Name;  t: TypeUID);

declare_raises (n: Name);

declare_object (t, super: TypeUID;  brand: TEXT;
                traced: BOOLEAN;  n_fields, n_methods: INTEGER;
                field_size: BitSize);
(* brand=NIL ==> t is unbranded *)

declare_method (n: Name;  signature: TypeUID);

declare_opaque (t, super: TypeUID);
(* TYPE t <: super *)

reveal_opaque (lhs, rhs: TypeUID);
(* REVEAL lhs = rhs *)

declare_exception (n: Name;  arg_type: TypeUID;  raise_proc: BOOLEAN;
                     base: Var;  offset: INTEGER);
(* declares an exception named 'n' identified with the address 'base+offset'
   that carries an argument of type 'arg_type'.  If 'raise_proc', then
   'base+offset+BYTESIZE(ADDRESS)' is a pointer to the procedure that
   packages the argument and calls the runtime to raise the exception. *)
   

(*--------------------------------------------------------- runtime hooks ---*)

set_runtime_hook (n: Name;  v: Var;  o: ByteOffset);
(* declares 'n' as a runtime symbol at location 'ADR(v)+o' *)

get_runtime_hook (n: Name;  VAR v: Var; VAR o: ByteOffset);
(* returns the location of the runtime symbol 'n' *)

(*------------------------------------------------- variable declarations ---*)

(* Clients must declare a variable before generating any statements or
   expressions that refer to it;  declarations of global variables and
   temps can be intermixed with generation of statements and expressions.

   In the declarations that follow:

|    n: Name            is the name of the variable.  If it's M3ID.NoID, the
|                         the back-end is free to choose its own unique name.
|    s: ByteSize        is the size in bytes of the declared variable
|    a: Alignment       is the minimum required alignment of the variable
|    t: Type            is the machine reprentation type of the variable
|    m3t: TypeUID       is the UID of the Modula-3 type of the variable,
|                       zero is used to represent "void" or "no type"
|    in_memory: BOOLEAN specifies whether the variable must have an address
|    exported: BOOLEAN  specifies whether the variable must be visible in
|                         other compilation units
|    init: BOOLEAN      indicates whether an explicit static initialization
|                         immediately follows this declaration.
|    up_level: BOOLEAN  specifies whether the variable is accessed from
|                         nested procedures.
|    f: Frequency       is the front-end estimate of how frequently the
|                         variable is accessed.

*)

import_global (n: Name;  s: ByteSize;  a: Alignment;  t: Type;
               m3t: TypeUID): Var;
(* imports the specified global variable. *)

declare_segment (n: Name;  m3t: TypeUID): Var;
bind_segment (seg: Var;  s: ByteSize;  a: Alignment;  t: Type;
              exported, init: BOOLEAN);
(* Together declare_segment and bind_segment accomplish what
   declare_global does, but declare_segment gives the front-end a
   handle on the variable before its size, type, or initial values
   are known.  Every declared segment must be bound exactly once. *)

declare_global (n: Name;  s: ByteSize;  a: Alignment;  t: Type;
                m3t: TypeUID;  exported, init: BOOLEAN): Var;
(* declares a global variable. *)

declare_constant (n: Name;  s: ByteSize;  a: Alignment;  t: Type;
              m3t: TypeUID;  exported, init: BOOLEAN): Var;
(* declares a read-only global variable *)
 
declare_local (n: Name;  s: ByteSize;  a: Alignment;  t: Type;
               m3t: TypeUID;  in_memory, up_level: BOOLEAN;
               f: Frequency): Var;
(* declares a local variable.  Local variables must be declared in the
   procedure that contains them.  The lifetime of a local variable extends
   from the beginning to end of the closest enclosing begin_block/end_block. *)

declare_param (n: Name;  s: ByteSize;  a: Alignment;  t: Type;
               m3t: TypeUID;  in_memory, up_level: BOOLEAN;
               f: Frequency): Var;
(* declares a formal parameter.  Formals are declared in their lexical
   order immediately following the 'declare_procedure' or
   'import_procedure' that contains them.  *)

declare_temp (s: ByteSize;  a: Alignment;  t: Type;
              in_memory: BOOLEAN): Var;
(* declares an anonymous local variable.  Temps are declared
   and freed between their containing procedure's begin_procedure and
   end_procedure calls.  Temps are never referenced by nested procedures. *)

free_temp (v: Var);
(* releases the space occupied by temp 'v' so that it may be reused by
   other new temporaries. *)

(*---------------------------------------- static variable initialization ---*)

(* Global variables may be initialized only once.  All of their init_*
   calls must be bracketed by begin_init and end_init.  Within a begin/end
   pair, init_* calls must be made in ascending offset order.  Begin/end
   pairs may not be nested.  Any space in a global variable that's not
   explicitly initialized is zeroed.  *)

begin_init (v: Var);
end_init (v: Var);
(* must precede and follow any init calls *)

init_int (o: ByteOffset;  READONLY value: Target.Int;  t: Type);
(* initializes the integer static variable at 'ADR(v)+o' with
   the low order bits of 'value' which is of integer type 't'. *)

init_proc (o: ByteOffset;  value: Proc);
(* initializes the static variable at 'ADR(v)+o' with the address
   of procedure 'value'. *)

init_label (o: ByteOffset;  value: Label);
(* initializes the static variable at 'ADR(v)+o' with the address
   of the label 'value'.  *)

init_var (o: ByteOffset;  value: Var;  bias: ByteOffset);
(* initializes the static variable at 'ADR(v)+o' with the address
   of 'value+bias'.  *)

init_offset (o: ByteOffset;  var: Var);
(* initializes the static variable at 'ADR(v)+o' with the integer
   frame offset of the local variable 'var' relative to the frame
   pointers returned at runtime in RTStack.Frames *)

init_chars (o: ByteOffset;  value: TEXT);
(* initializes the static variable at 'ADR(v)+o' with the characters
   of 'value' *)

init_float (o: ByteOffset;  READONLY f: Target.Float);
(* initializes the static variable at 'ADR(v)+o' with the
   floating point value 'f' *)

(*------------------------------------------------------------ procedures ---*)

(* Clients compile a procedure by doing:

      proc := cg.declare_procedure (...)
        ...declare formals...
        ...declare locals...
      cg.begin_procedure (proc)
        ...generate statements of procedure...
      cg.end_procedure (...)

  Nested procedure bodies may be generated before their parent's
  begin_procedure, after their parent's end_procedure, or inline
  where they occur in the source.  If they are not inline,
  note_procedure_origin is used to mark their original source
  position.  Runtime flags passed to the front-end determine where
  nested procedure bodies are generated.  Back-ends are free to
  require any one of these three placements for nested procedures.
  (At the moment:  m3cc -> inline,  m3back -> after)
*)

import_procedure (n: Name;  n_params: INTEGER;  return: Type;
                  cc: CallingConvention): Proc;
(* declare and import the external procedure with name 'n' and 'n_params'
   formal parameters.  It must be a top-level (=0) procedure that returns
   values of type 'return'.  'lang' is the language specified in the
   procedure's <*EXTERNAL*> declaration.  The formal parameters are specified
   by the subsequent 'declare_param' calls. *)

declare_procedure (n: Name;  n_params: INTEGER;  return: Type;
                   lev: INTEGER;  cc: CallingConvention;
                   exported: BOOLEAN;  parent: Proc): Proc;
(* declare a procedure named 'n' with 'n_params' formal parameters
   at static level 'lev'.  Sets "current procedure" to this procedure.
   If the name n is M3ID.NoID, a new unique name will be supplied by the
   back-end.  The type of the procedure's result is specifed in 'return'.
   If the new procedure is a nested procedure (level > 1) then 'parent' is
   the immediately enclosing procedure, otherwise 'parent' is NIL.
   The formal parameters are specified by the subsequent 'declare_param'
   calls. *)

begin_procedure (p: Proc);
(* begin generating code for the procedure 'p'.  Sets "current procedure"
   to 'p'.  Implies a begin_block.  *)

end_procedure (p: Proc);
(* marks the end of the code for procedure 'p'.  Sets "current procedure"
   to NIL.  Implies an end_block.  *)

begin_block ();
end_block ();
(* marks the beginning and ending of nested anonymous blocks *)

note_procedure_origin (p: Proc);
(* note that nested procedure 'p's body occured at the current location
   in the source.  In particular, nested in whatever procedures,
   anonymous blocks, or exception scopes surround this point. *)

(*------------------------------------------------------------ statements ---*)

set_label (l: Label;  barrier: BOOLEAN := FALSE);
(* define 'l' to be at the current pc, if 'barrier', 'l' bounds an exception
   scope and no code is allowed to migrate past it. *)

jump (l: Label);
(* GOTO l *)

if_true  (l: Label;  f: Frequency);
(* tmp := s0.I; pop; IF (tmp # 0) GOTO l *)

if_false (l: Label;  f: Frequency);
(* tmp := s0.I; pop; IF (tmp = 0) GOTO l *)

if_eq (l: Label;  t: ZType;  f: Frequency); (*== eq(t); if_true(l,f)*)
if_ne (l: Label;  t: ZType;  f: Frequency); (*== ne(t); if_true(l,f)*)
if_gt (l: Label;  t: ZType;  f: Frequency); (*== gt(t); if_true(l,f)*)
if_ge (l: Label;  t: ZType;  f: Frequency); (*== ge(t); if_true(l,f)*)
if_lt (l: Label;  t: ZType;  f: Frequency); (*== lt(t); if_true(l,f)*)
if_le (l: Label;  t: ZType;  f: Frequency); (*== le(t); if_true(l,f)*)

case_jump (READONLY labels: ARRAY OF Label);
(* tmp := s0.I; pop; GOTO labels[tmp]  (NOTE: no range checking on s0.I) *)

exit_proc (t: Type);
(* Returns s0.t if t is not Void, otherwise returns no value. *)

(*------------------------------------------------------------ load/store ---*)
(* Note: When an Int_A..Int_D value is loaded, it is sign extended to
   full Int width.  When a Word_A..Word_D value is loaded, it is zero
   extended to full Word width.  When an Int_A..Int_D or Word_A..Word_D
   value is stored, it is truncated from full width to the indicated size.

   Note: all loads and stores are aligned according to the specified type.
*)

load (v: Var;  o: ByteOffset;  t: MType);
(* push; s0.t := Mem [ ADR(v) + o ].t *)

load_address (v: Var;  o: ByteOffset := 0);
(* push; s0.A := ADR(v) + o *)

load_indirect (o: ByteOffset;  t: MType);
(* s0.t := Mem [s0.A + o].t *)


store (v: Var;  o: ByteOffset;  t: MType);
(* Mem [ ADR(v) + o : s ].t := s0.t; pop *)

store_indirect (o: ByteOffset;  t: MType);
(* Mem [s1.A + o].t := s0.t; pop (2) *)


store_ref (v: Var;  o: ByteOffset := 0);
(* == store (v, o, Type.Addr), but also does reference counting *)

store_ref_indirect (o: ByteOffset;  var: BOOLEAN);
(* == store_indirect (o, Type.Addr), but also does reference counting.
     If "var" is true, then reference counting depends on whether the
     effective address is in the heap or stack. *)

(*----------------------------------------------------------- expressions ---*)

(*  The code to evaluate expressions is generated by calling the
    procedures listed below.  Each procedure corresponds to an
    instruction for a simple stack machine.  Values in the stack
    have a type and a size.  Operations on the stack values are
    also typed.  Type mismatches may cause bad code to be generated
    or an error to be signaled.  Explicit type conversions must be used.

    Integer values on the stack, regardless of how they are loaded,
    are sign-extended to full-width values.  Similarly, word values
    on the stack are always zero-extened to full-width values.
    
    The expression stack must be empty at each label, jump, or call.
    The stack must contain exactly one value prior to a conditional
    or indexed jump.

    All addresses are byte addresses.  There is no boolean type;  boolean
    operators yield [0..1].

    Operations on word values are performed MOD the word size and are
    not checked for overflow.  Operations on integer values may or may not
    cause checked runtime errors depending on the particular code generator.

    The operators are declared below with a definition in terms of
    what they do to the execution stack.  For example,  ceiling(Reel)
    returns the ceiling, an integer, of the top value on the stack,
    a real:  s0.I := CEILING (s0.R).

    Unless otherwise indicated, operators have the same meaning as in
    the Modula-3 report.
*)

(*-------------------------------------------------------------- literals ---*)

load_nil     ();                         (*push; s0.A := NIL*)
load_integer (READONLY i: Target.Int);   (*push; s0.I := i *)
load_float   (READONLY f: Target.Float); (*push; s0.t := f *)

(*------------------------------------------------------------ arithmetic ---*)

(* when any of these operators is passed t=Type.Word, the operator
   does the unsigned comparison or arithmetic, but the operands
   and the result are of type Integer *)
   
eq       (t: ZType);   (* s1.I := (s1.t = s0.t); pop *)
ne       (t: ZType);   (* s1.I := (s1.t # s0.t); pop *)
gt       (t: ZType);   (* s1.I := (s1.t > s0.t); pop *)
ge       (t: ZType);   (* s1.I := (s1.t >= s0.t); pop *)
lt       (t: ZType);   (* s1.I := (s1.t < s0.t); pop *)
le       (t: ZType);   (* s1.I := (s1.t <= s0.t); pop *)
add      (t: AType);   (* s1.t := s1.t + s0.t; pop *)
subtract (t: AType);   (* s1.t := s1.t - s0.t; pop *)
multiply (t: AType);   (* s1.t := s1.t * s0.t; pop *)
divide   (t: RType);   (* s1.t := s1.t / s0.t; pop *)
negate   (t: AType);   (* s0.t := - s0.t *)
abs      (t: AType);   (* s0.t := ABS (s0.t) (noop on Words) *)
max      (t: ZType);   (* s1.t := MAX (s1.t, s0.t); pop *)
min      (t: ZType);   (* s1.t := MIN (s1.t, s0.t); pop *)
round    (t: RType);   (* s0.I := ROUND (s0.t) *)
trunc    (t: RType);   (* s0.I := TRUNC (s0.t) *)
floor    (t: RType);   (* s0.I := FLOOR (s0.t) *)
ceiling  (t: RType);   (* s0.I := CEILING (s0.t) *)
cvt_float(t: AType;  u: RType);     (* s0.u := FLOAT (s0.t, u) *)
div      (t: IType;  a, b: Sign);   (* s1.t := s1.t DIV s0.t;pop*)
mod      (t: IType;  a, b: Sign);   (* s1.t := s1.t MOD s0.t;pop*)

(* In div and mod, "a" is the sign of s1 and "b" is the sign of s0. *)

(*------------------------------------------------------------------ sets ---*)

(* Sets are represented on the stack as addresses. *)

set_union (s: ByteSize);          (* s2.B := s1.B + s0.B; pop(3) *)
set_difference (s: ByteSize);     (* s2.B := s1.B - s0.B; pop(3) *)
set_intersection (s: ByteSize);   (* s2.B := s1.B * s0.B; pop(3) *)
set_sym_difference (s: ByteSize); (* s2.B := s1.B / s0.B; pop(3) *)
set_member (s: ByteSize);         (* s1.I := (s0.I IN s1.B); pop *)
set_eq (s: ByteSize);             (* s1.I := (s1.B = s0.B); pop *)
set_ne (s: ByteSize);             (* s1.I := (s1.B # s0.B); pop *)
set_lt (s: ByteSize);             (* s1.I := (s1.B < s0.B); pop *)
set_le (s: ByteSize);             (* s1.I := (s1.B <= s0.B); pop *)
set_gt (s: ByteSize);             (* s1.I := (s1.B > s0.B); pop *)
set_ge (s: ByteSize);             (* s1.I := (s1.B >= s0.B); pop *)
set_range (s: ByteSize);          (* s2.A[s1.I..s0.I] := 1; pop(3) *)
set_singleton (s: ByteSize);      (* s1.A [s0.I] := 1; pop(2) *)

(*------------------------------------------------- Word.T bit operations ---*)

not ();  (* s0.I := Word.Not (s0.I) *)
and ();  (* s1.I := Word.And (s1.I, s0.I); pop *)
or  ();  (* s1.I := Word.Or  (s1.I, s0.I); pop *)
xor ();  (* s1.I := Word.Xor (s1.I, s0.I); pop *)

shift        ();  (* s1.I := Word.Shift  (s1.I, s0.I); pop *)
shift_left   ();  (* s1.I := Word.Shift  (s1.I, s0.I); pop *)
shift_right  ();  (* s1.I := Word.Shift  (s1.I, -s0.I); pop *)
rotate       ();  (* s1.I := Word.Rotate (s1.I, s0.I); pop *)
rotate_left  ();  (* s1.I := Word.Rotate (s1.I, s0.I); pop *)
rotate_right ();  (* s1.I := Word.Rotate (s1.I, -s0.I); pop *)

extract (sign: BOOLEAN);
(* s2.I := Word.Extract(s2.I, s1.I, s0.I);
   IF sign THEN SignExtend s2; pop(2) *)

extract_n (sign: BOOLEAN;  n: INTEGER);
(* s1.I := Word.Extract(s1.I, s0.I, n);
   IF sign THEN SignExtend s1; pop(1) *)

extract_mn (sign: BOOLEAN;  m, n: INTEGER);
(* s0.I := Word.Extract(s0.I, m, n);
   IF sign THEN SignExtend s0 *)

insert ();
(* s3.I := Word.Insert (s3.I, s2.I, s1.I, s0.I); pop(3) *)

insert_n (n: INTEGER);
(* s2.I := Word.Insert (s2.I, s1.I, s0.I, n); pop(2) *)

insert_mn (m, n: INTEGER);
(* s1.I := Word.Insert (s1.I, s0.I, m, n); pop(1) *)

(*------------------------------------------------ misc. stack/memory ops ---*)

swap (a, b: Type);
(* tmp := s1.a; s1.b := s0.b; s0.a := tmp *)

pop (t: Type);
(* pop(1) discard s0, not its side effects *)

copy_n (t: MType;  overlap: BOOLEAN);
(* copy s0.I units with 't's size and alignment from s1.A to s2.A; pop(3).
   'overlap' is true if the source and destination may partially overlap
   (ie. you need memmove, not just memcpy). *)

copy (n: INTEGER;  t: MType;  overlap: BOOLEAN);
(* copy 'n' units with 't's size and alignment from s0.A to s1.A; pop(2).
   'overlap' is true if the source and destination may partially overlap
   (ie. you need memmove, not just memcpy). *)

zero_n (t: MType);
(* zero s0.I units with 't's size and alignment starting at s1.A; pop(2) *)

zero (n: INTEGER;  t: MType);
(* zero 'n' units with 't's size and alignment starting at s0.A; pop(1) *)

(*----------------------------------------------------------- conversions ---*)

loophole (from, two: ZType);
(* s0.two := LOOPHOLE(s0.from, two) *)

(*------------------------------------------------ traps & runtime checks ---*)

assert_fault   ();
narrow_fault   ();
return_fault   ();
case_fault     ();
typecase_fault ();
(* Abort *)

check_nil ();
(* IF (s0.A = NIL) THEN Abort *)

check_lo (READONLY i: Target.Int);
(* IF (s0.I < i) THEN Abort *)

check_size (READONLY i: Target.Int);
(* IF (s0.I < i) THEN Abort; Pop (1) *)

check_align (READONLY i: Target.Int);
(* IF (s0.I BITAND i) THEN Abort; Pop (1) *)

check_hi (READONLY i: Target.Int);
(* IF (i < s0.I) THEN Abort *)

check_range (READONLY a, b: Target.Int);
(* IF (s0.I < a) OR (b < s0.I) THEN Abort *)

check_index ();
(* IF NOT (0 <= s1.I < s0.I) THEN Abort END; pop
   s0.I is guaranteed to be positive so the unsigned
   check (s0.W < s1.W) is sufficient. *)

check_eq ();
(* IF (s0.I # s1.I) THEN Abort;  Pop (2) *)

(*---------------------------------------------------- address arithmetic ---*)

add_offset (i: INTEGER);
(* s0.A := s0.A + i bytes *)

index_address (size: INTEGER);
(* s1.A := s1.A + s0.I * size; pop  -- where 'size' is in bytes *)

(*------------------------------------------------------- procedure calls ---*)

(* To generate a direct procedure call:
    
      cg.start_call_direct (proc, level, t);
    
      for each actual parameter i
          <generate value for parameter i>
          cg.pop_param ();  -or-  cg.pop_struct();
        
      cg.call_direct (proc, t);

   or to generate an indirect call:

      cg.start_call_indirect (t);
    
      for each actual parameter i
          <generate value for parameter i>
          cg.pop_param ();  -or-  cg.pop_struct();

      If the target is a nested procedure,
          <evaluate the static link to be used>
          cg.pop_static_link ();

      <evaluate the address of the procedure to call>
      cg.call_indirect (t);
*)

start_call_direct (p: Proc;  lev: INTEGER;  t: Type);
(* begin a procedure call to procedure 'p' at static level 'lev' that
   will return a value of type 't'. *)

call_direct (p: Proc;  t: Type);
(* call the procedure 'p'.  It returns a value of type t. *)

start_call_indirect (t: Type;  cc: CallingConvention);
(* begin an indirect procedure call that will return a value of type 't'. *)

call_indirect (t: Type;  cc: CallingConvention);
(* call the procedure whose address is in s0.A and pop s0.  The
   procedure returns a value of type t. *)

pop_param (t: ZType);
(* pop s0.t and make it the "next" parameter in the current call. *)

pop_struct (s: ByteSize;  a: Alignment);
(* pop s0.A, it's a pointer to a structure occupying 's' bytes that's
  'a' byte aligned; pass the structure by value as the "next" parameter
  in the current call. *)

pop_static_link ();
(* pop s0.A for the current indirect procedure call's static link  *)

(*------------------------------------------- procedure and closure types ---*)

load_procedure (p: Proc);
(* push; s0.A := ADDR (p's body) *)

load_static_link (p: Proc);
(* push; s0.A := (static link needed to call p, NIL for top-level procs) *)

(*----------------------------------------------------------------- misc. ---*)

comment (a, b, c, d: TEXT := NIL);
(* annotate the output with a&b&c&d as a comment.  Note that any of a,b,c or d
   may be NIL. *)

END; (* TYPE Public *)

END M3CG_Ops.



