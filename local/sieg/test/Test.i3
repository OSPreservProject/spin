
INTERFACE Test;
PROCEDURE CArray(<*AS CTEXT*>VAR x : ARRAY OF CHAR);
TYPE TaskT <: REFANY;
TYPE PROC = EPHEMERAL PROCEDURE (x : INTEGER);

<* PRAGMA INTERFACE_PROC_BASE *>

<* INTERFACE_PROC_BASE 10000 *>

PROCEDURE R2(x : INTEGER; VAR y : CHAR; VAR r1 : RSmall);
PROCEDURE TaskCreate(VAR parentTask : BOOLEAN) : BOOLEAN;
PROCEDURE TaskCreate2(parentTask : TaskT;
		      inheritMemory: BOOLEAN;
		      VAR ch : TaskT) : INTEGER;
  
TYPE RBig = RECORD x, y : INTEGER; END;
TYPE RSmall = RECORD x : INTEGER; END;

PROCEDURE R1(VAR r1 : RBig);

END Test.

