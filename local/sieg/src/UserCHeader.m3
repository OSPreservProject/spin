(*
 * Copyright 1994, 1995 University of Washington
 * All rights reserved.
 * See COPYRIGHT file for a full description
 *
 * HISTORY
 * 07-Nov-95  Yasushi Saito (yasushi) at the University of Washington
 *	created.
 *)
MODULE UserCHeader;
IMPORT Type, Module, Declaration;
IMPORT UserI3, ASCII, Text;
IMPORT IWr, Msg;

PROCEDURE OutputType (name : TEXT; t : Type.T; wr : IWr.T) =
  BEGIN
    (* Externalized references are just treated as word.
     Other refs fall through. *)
    TYPECASE t OF
    | Type.Ref(t) =>
      IF t.capabilityP THEN
	wr.put("typedef int ", name, ";\n");
	RETURN;
      END;
    ELSE
    END;

    TYPECASE t OF
    | Type.Opaque =>
      wr.put("typedef int  ", name, ";\n");
    | Type.Enum(et) =>
      VAR typeStr := t.toCText(name, FALSE);
      BEGIN
	(* Because toCText does not emit enum tags, we have to treat
	 *  it specially.
	 *)
	<* ASSERT typeStr # NIL *>
	wr.put("typedef ", typeStr, ";\n");
	wr.put("enum ", name, "{ ");
	FOR i := 0 TO LAST(et.values^) DO
	  IF i > 0 THEN wr.put(","); END;
	  wr.put(et.values[i]);
	END;
	wr.put("};\n");
      END;
    ELSE
      VAR typeStr := t.toCText(name, FALSE);
      BEGIN
	IF typeStr # NIL THEN
	  wr.put("typedef ", typeStr, ";\n");
	END;
      END;
    END;
  END OutputType;
    
    
PROCEDURE OutputProc (intf : TEXT; name : TEXT; p : Type.Proc; wr : IWr.T) =
VAR
  ExternalName := UserI3.ExternalName(intf, name, p);
  s : TEXT := NIL;
  j := 0;
BEGIN
  s := ExternalName &  "(";
    
  FOR i := 0 TO LAST(p.params^) DO
    WITH f = p.params[i] DO
      IF f.type.extensionOnly THEN
	(* ignore this *)
      ELSE 
	IF j > 0 THEN s := s & ", "; END;
	INC(j);
	VAR
	  pointer := "";
	BEGIN
	  IF f.type.toCText("", FALSE) = NIL THEN
	    (* If there's any type we can't recognize, just ignore
	     *  this procedure.
	     *)
	    wr.put("/* ", ExternalName, 
		   " is omitted its parameter can't be expressed in C.",
		   " */\n");
	    RETURN;
	  END;
	  CASE f.mode OF
	  | Type.Mode.Value =>
	    (* You can't pass array by value in C. In such case,
	     *  we just ignore this procedure.
	     *)
	    IF ISTYPE(f.type, Type.Array) THEN
	      wr.put("/* ", ExternalName,
		     " is omitted because array can't be passed by",
		     " value. */\n");
	    END;
	  ELSE
	    IF NOT ISTYPE(f.type, Type.Array) THEN
	      pointer := "*";
	    END;
	  END;
	  s := s & f.type.toCText(pointer & f.name);
	  (* Ignore default. we will support it in C++ version *)
	END;
      END;
    END;
  END;
  s := s & ")";

  (* Okay, finally Output the whole thing. *)
  IF p.retType = NIL THEN
    wr.put("void ", s, ";\n");
  ELSE
    VAR typeStr := p.retType.toCText(s);
    BEGIN
      IF typeStr # NIL THEN
	wr.put(typeStr, ";\n");
      END;
    END;
  END;
END OutputProc;

PROCEDURE Output (READONLY m : Module.T) = 
  VAR
    wr : IWr.T;
    nameBuf : ARRAY [0..255] OF CHAR;
    fileName : TEXT;
    fIdx := 0;
  BEGIN
    FOR i := 0 TO Text.Length(m.intf)-1 DO
      nameBuf[fIdx] := ASCII.Lower[Text.GetChar(m.intf, i)];
      INC(fIdx);
    END;
    fileName := Text.FromChars(SUBARRAY(nameBuf, 0, fIdx)) &"_user.h";
    Msg.Verbose(Msg.POS_VOID, "opening \"", fileName, "\"\n");
    wr := IWr.OpenWrite(fileName);
    
    wr.put("/* This file is produced by stubgen. Please do not edit this file directly.\n"
	   &"  Instead, kick yasushi@cs. */\n");
    
    FOR i := 0 TO m.names.size() -1 DO
      WITH genericDecl = m.names.get(i) DO
	TYPECASE genericDecl OF 
	| Declaration.Const(decl) =>
	  wr.put("#define ", m.intf , "_", decl.name, " ", decl.value, "\n");
	| Declaration.Type(decl) =>
	  OutputType(decl.name, decl.type, wr);
	| Declaration.Proc(decl) =>
	  OutputProc(m.intf, decl.name, decl.proc, wr);
	END;
      END;
    END;
    wr.close();
  END Output;

BEGIN
END UserCHeader.

