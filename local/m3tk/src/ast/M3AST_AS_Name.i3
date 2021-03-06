(* Copyright (C) 1990, Digital Equipment Corporation           *)
(* All rights reserved.                                        *)
(* See the file COPYRIGHT for a full description.              *)

INTERFACE M3AST_AS_Name;

IMPORT M3AST_AS_F;

PROCEDURE Whitespace(n: M3AST_AS_F.Whitespace): TEXT;
PROCEDURE Comment(n: M3AST_AS_F.Comment): TEXT;
PROCEDURE Pragma(n: M3AST_AS_F.Pragma): TEXT;
PROCEDURE BadChar(n: M3AST_AS_F.BadChar): TEXT;
PROCEDURE Token(n: M3AST_AS_F.Token): TEXT;
PROCEDURE Interface_id(n: M3AST_AS_F.Interface_id): TEXT;
PROCEDURE Module_id(n: M3AST_AS_F.Module_id): TEXT;
PROCEDURE F_Interface_id(n: M3AST_AS_F.F_Interface_id): TEXT;
PROCEDURE Interface_AS_id(n: M3AST_AS_F.Interface_AS_id): TEXT;
PROCEDURE F_Value_id(n: M3AST_AS_F.F_Value_id): TEXT;
PROCEDURE F_Var_id(n: M3AST_AS_F.F_Var_id): TEXT;
PROCEDURE F_Readonly_id(n: M3AST_AS_F.F_Readonly_id): TEXT;
PROCEDURE Type_id(n: M3AST_AS_F.Type_id): TEXT;
PROCEDURE Const_id(n: M3AST_AS_F.Const_id): TEXT;
PROCEDURE Var_id(n: M3AST_AS_F.Var_id): TEXT;
PROCEDURE Proc_id(n: M3AST_AS_F.Proc_id): TEXT;
PROCEDURE Enum_id(n: M3AST_AS_F.Enum_id): TEXT;
PROCEDURE Method_id(n: M3AST_AS_F.Method_id): TEXT;
PROCEDURE Override_id(n: M3AST_AS_F.Override_id): TEXT;
PROCEDURE Field_id(n: M3AST_AS_F.Field_id): TEXT;
PROCEDURE For_id(n: M3AST_AS_F.For_id): TEXT;
PROCEDURE Handler_id(n: M3AST_AS_F.Handler_id): TEXT;
PROCEDURE Tcase_id(n: M3AST_AS_F.Tcase_id): TEXT;
PROCEDURE With_id(n: M3AST_AS_F.With_id): TEXT;
PROCEDURE Exc_id(n: M3AST_AS_F.Exc_id): TEXT;
PROCEDURE Used_interface_id(n: M3AST_AS_F.Used_interface_id): TEXT;
PROCEDURE Used_def_id(n: M3AST_AS_F.Used_def_id): TEXT;
PROCEDURE Qual_used_id(n: M3AST_AS_F.Qual_used_id): TEXT;
PROCEDURE Compilation_Unit(n: M3AST_AS_F.Compilation_Unit): TEXT;
PROCEDURE Interface_gen_def(n: M3AST_AS_F.Interface_gen_def): TEXT;
PROCEDURE Module_gen_def(n: M3AST_AS_F.Module_gen_def): TEXT;
PROCEDURE Interface(n: M3AST_AS_F.Interface): TEXT;
PROCEDURE Module(n: M3AST_AS_F.Module): TEXT;
PROCEDURE Interface_gen_ins(n: M3AST_AS_F.Interface_gen_ins): TEXT;
PROCEDURE Module_gen_ins(n: M3AST_AS_F.Module_gen_ins): TEXT;
PROCEDURE Unsafe(n: M3AST_AS_F.Unsafe): TEXT;
PROCEDURE Import_item(n: M3AST_AS_F.Import_item): TEXT;
PROCEDURE Simple_import(n: M3AST_AS_F.Simple_import): TEXT;
PROCEDURE From_import(n: M3AST_AS_F.From_import): TEXT;
PROCEDURE Revelation_s(n: M3AST_AS_F.Revelation_s): TEXT;
PROCEDURE Const_decl_s(n: M3AST_AS_F.Const_decl_s): TEXT;
PROCEDURE Type_decl_s(n: M3AST_AS_F.Type_decl_s): TEXT;
PROCEDURE Var_decl_s(n: M3AST_AS_F.Var_decl_s): TEXT;
PROCEDURE Exc_decl_s(n: M3AST_AS_F.Exc_decl_s): TEXT;
PROCEDURE Proc_decl(n: M3AST_AS_F.Proc_decl): TEXT;
PROCEDURE Const_decl(n: M3AST_AS_F.Const_decl): TEXT;
PROCEDURE Var_decl(n: M3AST_AS_F.Var_decl): TEXT;
PROCEDURE Exc_decl(n: M3AST_AS_F.Exc_decl): TEXT;
PROCEDURE Subtype_decl(n: M3AST_AS_F.Subtype_decl): TEXT;
PROCEDURE Concrete_decl(n: M3AST_AS_F.Concrete_decl): TEXT;
PROCEDURE Subtype_reveal(n: M3AST_AS_F.Subtype_reveal): TEXT;
PROCEDURE Concrete_reveal(n: M3AST_AS_F.Concrete_reveal): TEXT;
PROCEDURE Named_type(n: M3AST_AS_F.Named_type): TEXT;
PROCEDURE Integer_type(n: M3AST_AS_F.Integer_type): TEXT;
PROCEDURE Real_type(n: M3AST_AS_F.Real_type): TEXT;
PROCEDURE LongReal_type(n: M3AST_AS_F.LongReal_type): TEXT;
PROCEDURE Extended_type(n: M3AST_AS_F.Extended_type): TEXT;
PROCEDURE Null_type(n: M3AST_AS_F.Null_type): TEXT;
PROCEDURE RefAny_type(n: M3AST_AS_F.RefAny_type): TEXT;
PROCEDURE ProcAny_type(n: M3AST_AS_F.ProcAny_type): TEXT;
PROCEDURE Address_type(n: M3AST_AS_F.Address_type): TEXT;
PROCEDURE Root_type(n: M3AST_AS_F.Root_type): TEXT;
PROCEDURE Enumeration_type(n: M3AST_AS_F.Enumeration_type): TEXT;
PROCEDURE Subrange_type(n: M3AST_AS_F.Subrange_type): TEXT;
PROCEDURE Array_type(n: M3AST_AS_F.Array_type): TEXT;
PROCEDURE Record_type(n: M3AST_AS_F.Record_type): TEXT;
PROCEDURE Object_type(n: M3AST_AS_F.Object_type): TEXT;
PROCEDURE Set_type(n: M3AST_AS_F.Set_type): TEXT;
PROCEDURE Procedure_type(n: M3AST_AS_F.Procedure_type): TEXT;
PROCEDURE Ref_type(n: M3AST_AS_F.Ref_type): TEXT;
PROCEDURE Packed_type(n: M3AST_AS_F.Packed_type): TEXT;
PROCEDURE Opaque_type(n: M3AST_AS_F.Opaque_type): TEXT;
PROCEDURE Brand(n: M3AST_AS_F.Brand): TEXT;
PROCEDURE Untraced(n: M3AST_AS_F.Untraced): TEXT;
PROCEDURE Fields(n: M3AST_AS_F.Fields): TEXT;
PROCEDURE Method(n: M3AST_AS_F.Method): TEXT;
PROCEDURE Override(n: M3AST_AS_F.Override): TEXT;
PROCEDURE Formal_param(n: M3AST_AS_F.Formal_param): TEXT;
PROCEDURE Raisees_some(n: M3AST_AS_F.Raisees_some): TEXT;
PROCEDURE Raisees_any(n: M3AST_AS_F.Raisees_any): TEXT;
PROCEDURE Range_EXP(n: M3AST_AS_F.Range_EXP): TEXT;
PROCEDURE Range(n: M3AST_AS_F.Range): TEXT;
PROCEDURE Integer_literal(n: M3AST_AS_F.Integer_literal): TEXT;
PROCEDURE Real_literal(n: M3AST_AS_F.Real_literal): TEXT;
PROCEDURE LongReal_literal(n: M3AST_AS_F.LongReal_literal): TEXT;
PROCEDURE Extended_literal(n: M3AST_AS_F.Extended_literal): TEXT;
PROCEDURE Text_literal(n: M3AST_AS_F.Text_literal): TEXT;
PROCEDURE Char_literal(n: M3AST_AS_F.Char_literal): TEXT;
PROCEDURE Nil_literal(n: M3AST_AS_F.Nil_literal): TEXT;
PROCEDURE Exp_used_id(n: M3AST_AS_F.Exp_used_id): TEXT;
PROCEDURE Constructor(n: M3AST_AS_F.Constructor): TEXT;
PROCEDURE RANGE_EXP_elem(n: M3AST_AS_F.RANGE_EXP_elem): TEXT;
PROCEDURE Actual_elem(n: M3AST_AS_F.Actual_elem): TEXT;
PROCEDURE Propagate(n: M3AST_AS_F.Propagate): TEXT;
PROCEDURE Plus(n: M3AST_AS_F.Plus): TEXT;
PROCEDURE Minus(n: M3AST_AS_F.Minus): TEXT;
PROCEDURE Times(n: M3AST_AS_F.Times): TEXT;
PROCEDURE Rdiv(n: M3AST_AS_F.Rdiv): TEXT;
PROCEDURE Textcat(n: M3AST_AS_F.Textcat): TEXT;
PROCEDURE Div(n: M3AST_AS_F.Div): TEXT;
PROCEDURE Mod(n: M3AST_AS_F.Mod): TEXT;
PROCEDURE Eq(n: M3AST_AS_F.Eq): TEXT;
PROCEDURE Ne(n: M3AST_AS_F.Ne): TEXT;
PROCEDURE Gt(n: M3AST_AS_F.Gt): TEXT;
PROCEDURE Lt(n: M3AST_AS_F.Lt): TEXT;
PROCEDURE Ge(n: M3AST_AS_F.Ge): TEXT;
PROCEDURE Le(n: M3AST_AS_F.Le): TEXT;
PROCEDURE And(n: M3AST_AS_F.And): TEXT;
PROCEDURE Or(n: M3AST_AS_F.Or): TEXT;
PROCEDURE In(n: M3AST_AS_F.In): TEXT;
PROCEDURE Select(n: M3AST_AS_F.Select): TEXT;
PROCEDURE Not(n: M3AST_AS_F.Not): TEXT;
PROCEDURE Unaryplus(n: M3AST_AS_F.Unaryplus): TEXT;
PROCEDURE Unaryminus(n: M3AST_AS_F.Unaryminus): TEXT;
PROCEDURE Deref(n: M3AST_AS_F.Deref): TEXT;
PROCEDURE Call(n: M3AST_AS_F.Call): TEXT;
PROCEDURE NEWCall(n: M3AST_AS_F.NEWCall): TEXT;
PROCEDURE Index(n: M3AST_AS_F.Index): TEXT;
PROCEDURE Actual(n: M3AST_AS_F.Actual): TEXT;
PROCEDURE Assign_st(n: M3AST_AS_F.Assign_st): TEXT;
PROCEDURE Call_st(n: M3AST_AS_F.Call_st): TEXT;
PROCEDURE Case_st(n: M3AST_AS_F.Case_st): TEXT;
PROCEDURE Eval_st(n: M3AST_AS_F.Eval_st): TEXT;
PROCEDURE Exit_st(n: M3AST_AS_F.Exit_st): TEXT;
PROCEDURE For_st(n: M3AST_AS_F.For_st): TEXT;
PROCEDURE If_st(n: M3AST_AS_F.If_st): TEXT;
PROCEDURE Lock_st(n: M3AST_AS_F.Lock_st): TEXT;
PROCEDURE Loop_st(n: M3AST_AS_F.Loop_st): TEXT;
PROCEDURE Raise_st(n: M3AST_AS_F.Raise_st): TEXT;
PROCEDURE Repeat_st(n: M3AST_AS_F.Repeat_st): TEXT;
PROCEDURE Return_st(n: M3AST_AS_F.Return_st): TEXT;
PROCEDURE Try_st(n: M3AST_AS_F.Try_st): TEXT;
PROCEDURE Typecase_st(n: M3AST_AS_F.Typecase_st): TEXT;
PROCEDURE While_st(n: M3AST_AS_F.While_st): TEXT;
PROCEDURE With_st(n: M3AST_AS_F.With_st): TEXT;
PROCEDURE Block(n: M3AST_AS_F.Block): TEXT;
PROCEDURE Case(n: M3AST_AS_F.Case): TEXT;
PROCEDURE Else_stm(n: M3AST_AS_F.Else_stm): TEXT;
PROCEDURE Elsif(n: M3AST_AS_F.Elsif): TEXT;
PROCEDURE Try_except(n: M3AST_AS_F.Try_except): TEXT;
PROCEDURE Try_finally(n: M3AST_AS_F.Try_finally): TEXT;
PROCEDURE Tcase(n: M3AST_AS_F.Tcase): TEXT;
PROCEDURE Handler(n: M3AST_AS_F.Handler): TEXT;
PROCEDURE Binding(n: M3AST_AS_F.Binding): TEXT;
PROCEDURE By(n: M3AST_AS_F.By): TEXT;
PROCEDURE Bad_EXP(n: M3AST_AS_F.Bad_EXP): TEXT;
PROCEDURE Bad_M3TYPE(n: M3AST_AS_F.Bad_M3TYPE): TEXT;
PROCEDURE Bad_STM(n: M3AST_AS_F.Bad_STM): TEXT;

END M3AST_AS_Name.
