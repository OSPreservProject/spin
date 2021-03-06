(* Copyright (C) 1989, Digital Equipment Corporation           *)
(* All rights reserved.                                        *)
(* See the file COPYRIGHT for a full description.              *)
(*                                                             *)
(* Last modified on Tue Aug 24 08:45:26 PDT 1993 by kalsow     *)
(*      modified on Fri Apr 30 14:59:04 PDT 1993 by swart      *)

(*
 * HISTORY
 * 15-May-96  Wilson Hsieh (whsieh) at the University of Washington
 *	align T to 64 bits
 *
 *)

INTERFACE TimeStamp;

IMPORT Time, RTMachine;

TYPE
  T     = ALIGNED RTMachine.PreferredAlignment FOR RECORD r: Bytes; END;
  Bytes = ARRAY [0 .. 15] OF Byte;
  Byte  = BITS 8 FOR [0 .. 255];

(* Each TimeStamp.T is unique globally.  TimeStamp.Ts are totally ordered
   in a relation that approximates the real time when the value was
   generated.  If two TimeStamp.Ts are generated in the same process then
   the ordering of the TimeStamp.Ts is consistent with the order that New
   was called. *)

CONST
  First = T{r := Bytes{0, .. }};
  (* All time stamps generated by New are larger than First. *)

CONST
  Last = T{r := Bytes{255, .. }};
  (* All time stamps generated by New are smaller than Last *)

PROCEDURE New(): T;
  (* Returns a new TimeStamp.T, unequal to any other produced by New, anywhere,
     anytime. *)

(*****************************************************************************)
(* A note on uniqueness: The implementation of 'New' and uses the
real-time clock and assume that time flows monotonically and that this
machine cannot reboot in less than one second.  Consequently, if the
real-time clock moves "backwards in time", the uniqueness guarantee of
this interface may be compromised.  *)
(*****************************************************************************)


PROCEDURE Compare(READONLY t1, t2: T): [-1..1];
  (* Compares two time stamps according the the total order relationship. *)

PROCEDURE Max(READONLY t1, t2: T): T;
PROCEDURE Min(READONLY t1, t2: T): T;
  (* Convenience procedures *)

PROCEDURE Equal(READONLY t1, t2: T): BOOLEAN;
  (* Returns TRUE if the two time stamps were generated by the same
     call  to New.  Equivalent to "=" for use by generic modules. *)

PROCEDURE Hash(READONLY t: T): INTEGER;
  (* Returns a hash function of the timestamp usable by generic table
     packages. Note that unlike some other hash functions this
     hash function is invariant over byte order and word size.  As
     such the return value is always such that it fits in a 32
     bit integer *)

PROCEDURE ToTime(READONLY t: T): Time.T;
  (* Returns an approximation to the time the time stamp was generated.
     This can be compared with Time.Now for validating time stamps.
     Returns -1.0D0 if the time stamp is out of the range of times
     that can be represented by this machine.   This normally means
     that the TimeStamp was not generated by New.  *)

END TimeStamp.
