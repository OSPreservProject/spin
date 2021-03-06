(* Copyright (C) 1994, Digital Equipment Corporation           *)
(* All rights reserved.                                        *)
(* See the file COPYRIGHT for a full description.              *)
(*                                                             *)
(* File: M3Compiler.m3                                         *)
(* Last modified on Tue Dec  6 08:16:20 PST 1994 by kalsow     *)
(*      modified on Sun Jan 21 06:56:46 1990 by muller         *)

(* HISTORY
 * 22-Feb-96  Charles Garrett (garrett) at the University of Washington
 *	Explicitly keeps track of the compilation phase.
 *
 *)

MODULE M3Compiler;

IMPORT Wr, Fmt, Thread(** , RTCollector, RTCollectorSRC **);
IMPORT Token, Error, Scanner, Value, Scope, M3String, RefType;
IMPORT Module, Type, BuiltinTypes, Host, Tracer, M3Header;
IMPORT BuiltinOps, WordModule, M3, Time, Coverage, Marker, TypeFP;
IMPORT Ident, TextExpr, Procedure, SetExpr, TipeDesc, Pathname;
IMPORT ESet, CG, TextWr, Target, ProcBody, Runtime, M3ID;

IMPORT SpinBuiltinOps, RTCodeModule; (* mef *)

VAR mu         : MUTEX    := NEW (MUTEX);
VAR builtins   : Module.T := NIL;

(* mef: create a module for all of the spin builtin operations *)
VAR spinbuiltins : Module.T := NIL;


PROCEDURE ParseImports (READONLY input : SourceFile;
                                 env   : Environment): IDList =
  VAR ids: IDList := NIL;
  BEGIN
    LOCK mu DO
      (* make the arguments globally visible *)
      Host.env      := env;
      Host.source   := input.contents;
      Host.filename := input.name;

      Scanner.Push (Host.filename, Host.source, is_main := TRUE);
        ids := M3Header.Parse ();
      Scanner.Pop ();
      RETURN ids;
    END;
  END ParseImports;

PROCEDURE Compile (READONLY input    : SourceFile;
                            env      : Environment;
                   READONLY options  : ARRAY OF TEXT): BOOLEAN =
  VAR ok: BOOLEAN;  start: Time.T;
  BEGIN
    LOCK mu DO
      start := Time.Now ();

      (* make the arguments globally visible *)
      Host.env      := env;
      Host.source   := input.contents;
      Host.filename := input.name;

      IF NOT Host.Initialize (options) THEN RETURN FALSE; END;

      IF NOT Host.stack_walker THEN
        (* command line override... *)
        Target.Has_stack_walker := FALSE;
      END;

      IF (builtins = NIL) THEN Initialize () END;

      (* mef *) 
      IF (spinbuiltins = NIL) THEN Initialize () END;

      Reset ();
      DoCompile ();
      ok := Finalize ();

      IF (Host.report_stats) THEN DumpStats (start, Time.Now ()); END;
    END;
    RETURN ok;
  END Compile;

PROCEDURE Initialize () =
  BEGIN
    (* this list is ordered! *)
    Type.Initialize ();
    TypeFP.Initialize ();

    Scanner.Push ("M3_BUILTIN", NIL, is_main := Host.emitBuiltins);
      builtins := Module.NewDefn ("M3_BUILTIN", TRUE, Scope.Initial);
      BuiltinTypes.Initialize ();
      BuiltinOps.Initialize ();
    Scanner.Pop ();

    Scanner.Push ("Word.i3", NIL, is_main := Host.emitBuiltins);
      WordModule.Initialize ();
    Scanner.Pop ();

    (* SPIN mod
       The RTCodeBuiltin interface defines the types which represent
       modules and interfaces at runtime. *)
    Scanner.Push("RTCodeBuiltin.i3", NIL, is_main := Host.emitBuiltins);
      RTCodeModule.Initialize();
    Scanner.Pop();

    Scanner.Push ("SPIN_BUILTIN", NIL, is_main := Host.emitBuiltins);
      spinbuiltins := Module.NewDefn ("M3_BUILTIN", TRUE, Scope.Initial);
      SpinBuiltinOps.Initialize ();
    Scanner.Pop ();
  END Initialize;

PROCEDURE Reset () =
  BEGIN
    (* this list is ordered! *)
    M3String.Reset ();
    Scanner.Reset ();
    Scope.Reset ();
    Coverage.Reset ();
    Error.Reset ();
    Marker.Reset ();
    ESet.Reset ();
    ProcBody.Reset ();
    Runtime.Reset ();
    TipeDesc.Reset ();
    Tracer.Reset ();
    Type.Reset ();
    TypeFP.Reset ();
    RefType.Reset ();
    Value.Reset ();
    Module.Reset ();
    Ident.Reset ();
    TextExpr.Reset ();
    Procedure.Reset ();
    SetExpr.Init ();
  END Reset;


PROCEDURE DoCompile () =
  VAR m: Module.T;  cs := M3.OuterCheckState;  m_name, filename: M3ID.T;
  BEGIN
(***
RTCollectorSRC.gcRatio := 0.5; (* don't bother collecting much *)
RTCollectorSRC.incremental := FALSE;
RTCollector.Disable ();
***)
    Scanner.Push (Host.filename, Host.source, is_main := TRUE);

    Host.StartPhase(Host.Phase.InitBuiltins);
    CheckBuiltins ();

    Host.StartPhase(Host.Phase.Parsing);
    m := Module.Parse ();

    (* check that the module name matches the file name *)
    m_name := Module.Name (m);
    filename := M3ID.Add (Pathname.LastBase (Host.filename));
    IF (m_name # filename) THEN
      Error.Warn (2, "file name (" & Pathname.Last (Host.filename)
                    & ") doesn't match module name ("
                    & M3ID.ToText (m_name) & ")");
    END;
(***
RTCollector.Enable ();
***)
    IF Failed () THEN RETURN END;

    Host.StartPhase(Host.Phase.TypeChecking);
    Module.TypeCheck (m, TRUE, cs);
    IF Failed () THEN RETURN END;

    Host.StartPhase(Host.Phase.EmittingCode);
    CG.Init ();
    IF Failed () THEN RETURN END;
    IF (Host.emitBuiltins) THEN
      Module.MakeCurrent (builtins);
      Module.MakeCurrent (spinbuiltins);
      Module.MakeCurrent (WordModule.M);
      Module.Compile (builtins);
      Module.Compile (spinbuiltins);
      Module.Compile (WordModule.M);
    ELSE
      Module.Compile (m);
    END;
    IF Failed () THEN RETURN END;
  END DoCompile;

PROCEDURE CheckBuiltins () =
  VAR cs := M3.OuterCheckState;
  BEGIN
    Value.TypeCheck (builtins, cs);
    Value.TypeCheck (spinbuiltins, cs);
    Value.TypeCheck (WordModule.M, cs);
  END CheckBuiltins;

PROCEDURE Failed (): BOOLEAN =
  VAR errs, warns: INTEGER;
  BEGIN
    Error.Count (errs, warns);
    RETURN (errs > 0);
  END Failed;

PROCEDURE DumpStats (start, stop: Time.T) =
  <*FATAL Wr.Failure, Thread.Alerted*>
  VAR
    wr      := TextWr.New ();
    elapsed := MAX (stop - start, 1.0d-6);
    speed   := FLOAT (Scanner.nLines, LONGREAL) / elapsed;
  BEGIN
    Wr.PutText (wr, "  ");
    Wr.PutText (wr, Fmt.Int (Scanner.nLines));
    Wr.PutText (wr, " lines (");
    Wr.PutText (wr, Fmt.Int (Scanner.nPushed));
    Wr.PutText (wr, " files) scanned, ");
    Wr.PutText (wr, Fmt.LongReal (elapsed, Fmt.Style.Fix, 2));
    Wr.PutText (wr, " seconds, ");
    Wr.PutText (wr, Fmt.LongReal (speed, Fmt.Style.Fix, 1));
    Wr.PutText (wr, " lines / second.");
    Host.env.report_error (NIL, 0, TextWr.ToText (wr));
  END DumpStats;

PROCEDURE Finalize (): BOOLEAN =
  <*FATAL Wr.Failure, Thread.Alerted*>
  VAR errs, warns: INTEGER;  wr: TextWr.T;
  BEGIN
    Scanner.Pop ();

    Error.Count (errs, warns);
    IF (errs + warns > 0) THEN
      wr := TextWr.New ();
      IF (errs > 0) THEN
        Wr.PutText (wr, Fmt.Int (errs));
        Wr.PutText (wr, " error");
        IF (errs > 1) THEN Wr.PutText (wr, "s") END;
      END;
      IF (warns > 0) THEN
        IF (errs > 0) THEN Wr.PutText (wr, " and ") END;
        Wr.PutText (wr, Fmt.Int (warns));
        Wr.PutText (wr, " warning");
        IF (warns > 1) THEN Wr.PutText (wr, "s") END;
      END;
      Wr.PutText (wr, " encountered");
      Host.env.report_error (NIL, 0, TextWr.ToText (wr));
    END;

    RETURN (errs <= 0);
  END Finalize;

BEGIN
  M3String.Initialize ();
  Token.Initialize ();
  Scanner.Initialize ();
  Scope.Initialize ();
END M3Compiler.
