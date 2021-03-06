(*
 * Copyright 1995-1996, University of Washington
 * All rights reserved.
 * See COPYRIGHT file for a full description
 *)
(* HISTORY
 * 09-Dec-97  David Becker at the University of Washington
 *	Add m_adj().  Use MbufMalloc() for arch dependencies.
 *	Move MclGetx to MbufDep.
 *
 * 24-Jul-97  Marc Fiuczynski (mef) at the University of Washington
 *	Various fixes: pktdat constant was wrong; counting of allocated
 *	mbufs corrected.
 *
 * 22-Nov-96  becker at the University of Washington
 *	Change to TrackStrand from Spy
 *
 * 24-Oct-96  Marc Fiuczynski (mef) at the University of Washington
 *	verify in checksum that an mbuf array is not zero length.
 *
 * 19-Oct-96  Marc Fiuczynski (mef) at the University of Washington
 *	Updated to be SAL independent.
 *
 * 19-Sep-96  Wilson Hsieh (whsieh) at the University of Washington
 *	make Array FUNCTIONAL so that net guards can call it
 *
 * 14-Aug-96  Frederick Gray (fgray) at the University of Washington
 *	New interface to interrupt handling.
 *
 * 13-Jun-96  Marc Fiuczynski (mef) at the University of Washington
 *	Added M_LEADINGSPACE procedure.
 *
 * 15-May-96  Marc Fiuczynski (mef) at the University of Washington
 *	Add Spy name to the mbuf isr thread.
 *
 * 26-Apr-96  Marc Fiuczynski (mef) at the University of Washington
 *	Restructured Mbuf.AsyncDeliver to more precisely capture exceptions
 *	generated by the upcall to the clients free method.
 *
 * 24-Apr-96  Marc Fiuczynski (mef) at the University of Washington
 *	Passing offset to the checksum method.
 *
 * 20-Apr-96  Marc Fiuczynski (mef) at the University of Washington
 *	Added support for mbuf method upcalls. Right now there is the
 *	"free" and "csum" upcall.  The plan for the future is for the
 *	Mbuf.T to become an object which can be extended to support
 *	arbitrary, application-specific upcalls.  This will happen when
 *	uncollectable and collectable heaps have been merged into one.
 *      M_M3FREE flag is now called M_M3METHODS.
 *
 * 12-Feb-96  Marc Fiuczynski (mef) at the University of Washington
 *	Setting M_M3FREE flag in mbuf so that mbuf free upcalls have
 *	correct parameters.
 *
 * 02-Feb-96  Marc Fiuczynski (mef) at the University of Washington
 *	Eliminated the need for some of the dependence on C code.
 *	
 * 31-Jan-96  Marc Fiuczynski (mef) at the University of Washington
 *	Made the Isr() function safe wrt ThreadExtra.
 *
 * 09-Jan-96  Emin Gun Sirer (egs) at the University of Washington
 *	Made it possible to use large arrays as containers of smaller
 *	amounts of information to be wrapped in an Mbuf.
 *
 * 04-Jan-96  Marc Fiuczynski (mef) at the University of Washington
 *	Added support to handle async mbuf free upcalls.
 *
 * 25-Jul-95  Marc Fiuczynski (mef) at the University of Washington
 *	Created. To cooperate with BSD style uipc_mbuf.c.
 *)

UNSAFE (* to import MbufExtern *)
MODULE Mbuf EXPORTS Mbuf, MbufPublic;
IMPORT TrackStrand; <*NOWARN*>

IMPORT Sema, IO, CPU, CPUPrivate, SpinException, Thread,
       ThreadExtra, Word, Ctypes, MbufExtern, MbufDep;
IMPORT StrongRef; <*NOWARN*>
IMPORT NetDev;

IMPORT Debugger;

CONST useStrongRef = TRUE;

CONST extOffset = BYTESIZE(pkthdrT);
      (* offset of ext in the mbuf M_Dat area *)

CONST pktdat = BYTESIZE(pkthdrT);
      (* offset to data portion of mbuf after pkthdr *)



<*INLINE*>
FUNCTIONAL PROCEDURE Array(m: T): UNTRACED REF ARRAY OF CHAR =
  TYPE OpenArrayHeader = UNTRACED REF RECORD
    start: ADDRESS;
    len  : INTEGER;
  END;
  VAR oah : OpenArrayHeader;
  BEGIN
    (* sanity check *)
    IF m = NIL THEN RETURN NIL; END;

    (* look at the mbuf mh_data and mh_len field as an OpenArrayHeader *)
    oah := LOOPHOLE(ADR(m.mh_hdr.mh_data),OpenArrayHeader);

    (* return the openarrayheader as m3 untraced array *)
    RETURN LOOPHOLE(oah,UNTRACED REF ARRAY OF CHAR);
  END Array;

PROCEDURE MclGetOa(
    buffer: REF ARRAY OF CHAR; 
    length: CARDINAL; 
    methods: Methods;
    desc: REFANY) : T 
  RAISES {LengthMismatch} =
  VAR 
    mbuf : T;
    userMethods: BOOLEAN := TRUE;
  BEGIN
    (* sanity checks *)
    IF buffer = NIL THEN RETURN NIL; END;
    IF NUMBER(buffer^) < length THEN RAISE LengthMismatch; END;

    IF methods = NIL THEN
      methods := globalMethods; 
      userMethods := FALSE;
    END;

    mbuf := MclGetx(
                LOOPHOLE(methods,Word.T), (* SafeConvert.RefAnyToWord(methods) *)
                LOOPHOLE(desc,Word.T),    (* SafeConvert.RefAnyToWord(desc) *)
                LOOPHOLE(buffer,Word.T),  (* SafeConvert.RefAnyToWord(buffer) *)
                LOOPHOLE(ADR(buffer[FIRST(buffer^)]), Word.T),
                length, 
                M_WAIT);

    IF mbuf = NIL THEN RETURN NIL; END;

    (* assumes GC will be fixed to unstrongref *)
    IF useStrongRef THEN 
      StrongRef.Add(buffer);
      StrongRef.Add(desc);
      StrongRef.Add(methods);
    END;

    (* set lenght field *)
    SetPktHdrLen(mbuf, length);

    (* set M3METHODS flag to free mbuf data area properly *)
    mbuf.mh_hdr.mh_flags := Word.Or(mbuf.mh_hdr.mh_flags,M_M3METHODS);
    mbuf.mh_hdr.mh_flags := Word.Or(mbuf.mh_hdr.mh_flags,M_FASTFREE);
    RETURN mbuf;
  END MclGetOa; 

(* Compute the amount of space available before the current start of
  data in an mbuf.  *)
<*UNUSED*>
PROCEDURE M_LEADINGSPACE(m:T): CARDINAL =
  BEGIN
    IF Word.And(m.mh_hdr.mh_flags, M_EXT) # 0 THEN
      <* ASSERT FALSE *>

    END;
    
    IF Word.And(m.mh_hdr.mh_flags, M_PKTHDR) # 0 THEN
      <* ASSERT FALSE *>      

    END;

    RETURN m.mh_hdr.mh_data - LOOPHOLE(ADR(m.M_dat[FIRST(m.M_dat)]),Word.T);
  END M_LEADINGSPACE;

<*INLINE*>
PROCEDURE M_PREPEND(m:T; len:CARDINAL; how:HowT):T =
  BEGIN
    IF MbufExtern.M_LEADINGSPACE(m) >= len THEN
      (* pointer arithmetic *)
      m.mh_hdr.mh_data := m.mh_hdr.mh_data - len;
      m.mh_hdr.mh_len  := m.mh_hdr.mh_len + len;
    ELSE
      m := MbufExtern.m_prepend(m,len,how)
    END;
    IF Word.And(m.mh_hdr.mh_flags, M_PKTHDR) # 0 THEN
      WITH pkthdr = LOOPHOLE(ADR(m.M_dat[FIRST(m.M_dat)]),
                             UNTRACED REF pkthdrT) DO
        INC(pkthdr.len,len);
      END;
    END;
    RETURN m;
  END M_PREPEND;

<*INLINE*>
PROCEDURE M_ALIGN(m:T;len:CARDINAL) =
  BEGIN
    m.mh_hdr.mh_data := m.mh_hdr.mh_data + Word.And((MLEN - len), Word.Not(BYTESIZE(ADDRESS)-1));
  END M_ALIGN;

<*INLINE*>
PROCEDURE MH_ALIGN(m:T;len:CARDINAL) =
  BEGIN
    m.mh_hdr.mh_data := m.mh_hdr.mh_data + Word.And((MHLEN - len), Word.Not(BYTESIZE(ADDRESS)-1));
  END MH_ALIGN;

<*INLINE*>
PROCEDURE m_length(m:T): CARDINAL = 
  VAR 
    t   :T;
    len :CARDINAL := 0;
  BEGIN
    t := m;
    WHILE t # NIL DO 
      INC(len, t.mh_hdr.mh_len);
      t := t.mh_hdr.mh_next;
    END;
    RETURN len;
  END m_length; 

PROCEDURE SetPktHdrLen(m:T; len: CARDINAL) = 
  BEGIN
    IF Word.And(m.mh_hdr.mh_flags, M_PKTHDR) # 0 THEN
      WITH pkthdr = LOOPHOLE(ADR(m.M_dat[FIRST(m.M_dat)]),
                             UNTRACED REF pkthdrT) DO
        pkthdr.len := len;
      END;
    ELSE
      Debugger.Enter();
    END;
  END SetPktHdrLen;

PROCEDURE SetPktHdrRcvIf(m:T; rcvif: NetDev.T) = 
  BEGIN
    IF Word.And(m.mh_hdr.mh_flags, M_PKTHDR) # 0 THEN
      WITH pkthdr = LOOPHOLE(ADR(m.M_dat[FIRST(m.M_dat)]),
                             UNTRACED REF pkthdrT) DO
        pkthdr.rcvif := LOOPHOLE(rcvif,ADDRESS);
      END;
    ELSE
      Debugger.Enter();
    END;
  END SetPktHdrRcvIf;

PROCEDURE GetPktHdrLen(m:T) : CARDINAL = 
  BEGIN 
    IF Word.And(m.mh_hdr.mh_flags, M_PKTHDR) # 0 THEN
      WITH pkthdr = LOOPHOLE(ADR(m.M_dat[FIRST(m.M_dat)]),
                             UNTRACED REF pkthdrT) DO
        RETURN pkthdr.len;
      END;
    ELSE
      Debugger.Enter();
      RETURN 0;
    END;
  END GetPktHdrLen;

PROCEDURE GetPktHdrRcvIf(m:T): NetDev.T =
  BEGIN
    IF Word.And(m.mh_hdr.mh_flags, M_PKTHDR) # 0 THEN
      WITH pkthdr = LOOPHOLE(ADR(m.M_dat[FIRST(m.M_dat)]),
                             UNTRACED REF pkthdrT) DO
        RETURN LOOPHOLE(pkthdr.rcvif, NetDev.T);
      END;
    ELSE
      Debugger.Enter();
      RETURN NIL;
    END;
  END GetPktHdrRcvIf;

PROCEDURE Deliver(mbuf: T) =
  VAR ext : UNTRACED REF MbufDep.m_extT;
  BEGIN
    TRY 
      IF Word.And(mbuf.mh_hdr.mh_flags,M_EXT) # 0 THEN
        ext :=
	LOOPHOLE(ADR(mbuf.M_dat[FIRST(mbuf.M_dat)])+extOffset,
                 UNTRACED REF MbufDep.m_extT);
        TRY
          IF FALSE (* MCLREFERENCED *) THEN
            IO.Put("Mbuf.Isr() mbuf ext without free function.\n");
            (* PANIC *)
          ELSIF Word.And(mbuf.mh_hdr.mh_flags,M_M3METHODS) # 0 THEN 
            TRY
              WITH methods = LOOPHOLE(ext.ext_methods, Methods) DO
                IF methods # NIL AND methods.free # NIL THEN
                  TRY
                    methods.free(LOOPHOLE(ext.ext_m3oa,REF ARRAY OF CHAR),
                                 ext.ext_size,
                                 LOOPHOLE(ext.ext_arg, REFANY));
                  EXCEPT
                  | SpinException.Exception =>
                    IO.Put("Mbuf.AsyncDeliver caught exception (1).\n");
                  END;
                END;
              END;
            FINALLY
              IF useStrongRef THEN
                StrongRef.Remove(LOOPHOLE(ext.ext_methods,REFANY));
                StrongRef.Remove(LOOPHOLE(ext.ext_arg,REFANY));
                StrongRef.Remove(LOOPHOLE(ext.ext_m3oa,REFANY));
              END;
            END;
          ELSE
            TRY
              WITH free = LOOPHOLE(ext.ext_methods, freeprocT) DO
                free(LOOPHOLE(ext.ext_buf,REF ARRAY OF CHAR),
                     ext.ext_size,
                     LOOPHOLE(ext.ext_arg, REFANY));
              END;
            EXCEPT
            | SpinException.Exception =>
              IO.Put("Mbuf.AsyncDeliver caught exception (2).\n");
            END;
          END;
        FINALLY

          (* Be nice to GC and get rid of ambiguous roots in 
             untraced heap by NILing out the references to 
             traced data.
          *)

          ext.ext_buf         := 0;
          ext.ext_arg         := 0;
          ext.ext_m3oa        := 0;
          ext.ext_methods     := 0;
          mbuf.mh_hdr.mh_data := 0;
        END;
      END
    FINALLY
      TRY
        (* turn off the EXT bit, so that m_free wont upcall. *)
        (* DEC(MbufExtern.mbstat.m_mtypes[mbuf.mh_hdr.mh_type]); *) (* XXX needs to be atomic *)
        (* mbuf.mh_hdr.mh_type := MT_FREE; *)
        mbuf.mh_hdr.mh_flags := 0;
        EVAL m_free(mbuf);
      EXCEPT
        SpinException.Exception =>
        IO.Put("Expception fault in Mbuf.AsyncDeliver finally handler.\n");
      END;
    END;
  END Deliver;


(* internal service functions *)
PROCEDURE AsyncDeliver(arg: ThreadExtra.ArgT) : ThreadExtra.ResultT =
  VAR mbuf: T;
  BEGIN
    mbuf := NARROW(arg,REF T)^;
    Deliver(mbuf);
    RETURN NIL;
  END AsyncDeliver;

PROCEDURE Isr(<* UNUSED *> r: ThreadExtra.ArgT) : ThreadExtra.ResultT = 
  CONST High = CPUPrivate.InterruptClass.High;
  VAR mbuf, m: T;
      spl: CPU.InterruptLevel;
  BEGIN
    LOOP
      (* NIL out stack variable to be GC nice. *)
      mbuf        := NIL;
      m           := NIL;

      Sema.P(processMbufs);

      (* dequeue operations has to be atomic wrt to interrupt handlers *)
      BEGIN spl:= CPUPrivate.SetInterruptMask(High);
        mbuf                  := MbufExtern.mfreelater;
        MbufExtern.mfreelater := NIL;
      END; CPUPrivate.RestoreInterruptMask(spl);        

      (* walk the mbuf list and call free *)
      WHILE mbuf # NIL DO
        m                := mbuf;
        mbuf             := mbuf.mh_hdr.mh_next;
        m.mh_hdr.mh_next := NIL;
        IF Word.And(m.mh_hdr.mh_flags,M_FASTFREE) = 0 THEN
          VAR mbufCarrier: REF T;
          BEGIN
            mbufCarrier := NIL;
            mbufCarrier := NEW(REF T);
            mbufCarrier^ := m;
            EVAL ThreadExtra.PFork(AsyncDeliver,mbufCarrier);
          END;
        ELSE
          Deliver(m);
        END;
      END;
    END;
  END Isr;

(* SchedIsr() 
 * Kick Isr thread. 
 * Called possible from interrupt handler in uipc_mbuf.c m_free().
 *)
PROCEDURE SchedIsr() = 
  BEGIN
    Sema.V(processMbufs);
  END SchedIsr;

VAR
  processMbufs : Sema.T;
  mbufThread   : Thread.T;

(* defined in bsd/uipc_mbuf.c *)
<* INLINE *>
PROCEDURE m_copydata(m:T; off:CARDINAL; len:CARDINAL; cp:T) =
  BEGIN
    MbufExtern.m_copydata(m,off,len, cp.mh_hdr.mh_data);
  END m_copydata;

<*INLINE*>
PROCEDURE m_copym(m:T; off0:CARDINAL; len:CARDINAL; wait:HowT):T =
  BEGIN
    RETURN MbufExtern.m_copym(m,off0,len,wait);
  END m_copym;

PROCEDURE m_free(m:T):T =
  BEGIN
    RETURN MbufExtern.m_free(m);
  END m_free;

<*INLINE*>
PROCEDURE m_freem(m:T) =
  BEGIN
    MbufExtern.m_freem(m);
  END m_freem;

<*INLINE*>
PROCEDURE m_getclr(canwait: HowT; type: Ctypes.int):T =
  BEGIN
    RETURN MbufExtern.m_getclr(canwait,type);
  END m_getclr;

<* INLINE *>
PROCEDURE m_get_internal(canwait: HowT; type: Ctypes.int): T =
  BEGIN
    WITH addr = MbufMalloc(canwait),
         m = LOOPHOLE(addr,T),
         mh = m.mh_hdr
     DO
      IF m # NIL THEN
        mh.mh_next    := NIL;
        mh.mh_nextpkt := NIL;
        mh.mh_data    := LOOPHOLE(ADR(m.M_dat[FIRST(m.M_dat)]),Word.T);
        mh.mh_len     := 0;
        mh.mh_type    := type;
        mh.mh_flags   := 0;
      END;
      RETURN m;
    END;
  END m_get_internal;

<*INLINE*>
PROCEDURE m_get   (canwait: HowT; type: Ctypes.int):T =
  VAR m : T;
  BEGIN
    m := m_get_internal(canwait,type);
    IF m # NIL THEN

      INC(MbufExtern.mbstat.m_mbufs);              (* XXX needs to be atomic *)
      (* INC(MbufExtern.mbstat.m_mtypes[type]); *) (* XXX needs to be atomic *)
    ELSE
      m := m_retry(canwait,type);
    END;
    RETURN m;
    (* RETURN MbufExtern.m_get   (canwait,type);*)
  END m_get;

<* INLINE *>
PROCEDURE m_gethdr_internal(canwait: HowT; type: Ctypes.int):T =
  BEGIN
    WITH addr = MbufMalloc(canwait),
         m = LOOPHOLE(addr,T),
         mh = m.mh_hdr
     DO
      IF m # NIL THEN
        mh.mh_next    := NIL;
        mh.mh_nextpkt := NIL;
        mh.mh_data    := LOOPHOLE(ADR(m.M_dat[FIRST(m.M_dat)+pktdat]),Word.T);
        mh.mh_len     := 0;
        mh.mh_type    := type;
        mh.mh_flags   := M_PKTHDR;
      END;
      RETURN m;
    END;
    (* <*NOWARN *> RETURN MbufExtern.m_gethdr(canwait,type); *)
  END m_gethdr_internal;

<*INLINE*>
PROCEDURE m_gethdr(canwait: HowT; type: Ctypes.int):T =
  VAR m: T;
  BEGIN
    m := m_gethdr_internal(canwait,type);
    IF m # NIL THEN
      INC(MbufExtern.mbstat.m_mbufs);              (* XXX needs to be atomic *)
      (* INC(MbufExtern.mbstat.m_mtypes[type]); *) (* XXX needs to be atomic *)
    ELSE
      m := m_retryhdr(canwait,type);
    END;
    RETURN m;
    (* <*NOWARN *> RETURN MbufExtern.m_gethdr(canwait,type); *)
  END m_gethdr;

(* When MGET fails, ask someone to free space when short of memory
   and then re-attempt to allocate an mbuf. *)
PROCEDURE m_retry(canwait: HowT; type: Ctypes.int):T = 
  VAR m: T := NIL;
  BEGIN
    IF canwait # M_DONTWAIT THEN

      (* RECLAIM MBUFS and maintain stats that we reclaimed
         something. *)

      m := m_get_internal(canwait,type);

      (* IF m = NIL THEN maintain stats on dropped mbuf. END; *)

    END;
    RETURN m;
  END m_retry;

PROCEDURE m_retryhdr(canwait: HowT; type: Ctypes.int):T =
  VAR m: T;
  BEGIN
    m := m_retry(canwait,type);
    IF m # NIL THEN
      m.mh_hdr.mh_flags := Word.Or(m.mh_hdr.mh_flags, M_PKTHDR);
      m.mh_hdr.mh_data  := LOOPHOLE(ADR(m.M_dat[FIRST(m.M_dat)+pktdat]),Word.T);
    END;
    RETURN m;
  END m_retryhdr;

<*INLINE*>
PROCEDURE m_prepend(m:T; len:CARDINAL; how:HowT):T =
  BEGIN
    m := MbufExtern.m_prepend(m,len,how);
    IF Word.And(m.mh_hdr.mh_flags, M_PKTHDR) # 0 THEN
      WITH pkthdr = LOOPHOLE(ADR(m.M_dat[FIRST(m.M_dat)]),UNTRACED REF pkthdrT) DO
        INC(pkthdr.len,len);
      END;
    END;
    RETURN m;
  END m_prepend;

PROCEDURE m_adj(n:T; len: CARDINAL) =
  BEGIN
    MbufExtern.m_adj(n,len);
  END m_adj;

PROCEDURE m_pullup(n:T; len: CARDINAL):T =
  BEGIN
    RETURN MbufExtern.m_pullup(n,len);
  END m_pullup;

EPHEMERAL
PROCEDURE FreeProc(
    <* UNUSED *> ext_buf  : REF ARRAY OF CHAR; 
    <* UNUSED *> ext_size : CARDINAL; 
    <* UNUSED *> ext_arg  : REFANY) = 
  BEGIN
    (* DOES NOTHING *)
  END FreeProc;

VAR globalMethods : Methods;
PROCEDURE Init() = 
  BEGIN
    processMbufs := Sema.Alloc();
    mbufThread := ThreadExtra.PFork(Isr, NIL);
    TrackStrand.SetName(ThreadExtra.GetTracker(mbufThread),"MbufReaper");
    
    MbufExtern.sal_mbuf_free := SchedIsr;
    globalMethods := NEW(Methods);
    globalMethods.free := FreeProc;
    globalMethods.csum := NIL;  (* LOOPHOLE(CsumProc,csumprocT);  *)
  END Init;

BEGIN
END Mbuf.
