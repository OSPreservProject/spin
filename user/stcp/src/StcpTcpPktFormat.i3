(*
 * Copyright 1994, University of Washington
 * All rights reserved.
 * See COPYRIGHT file for a full description
 *
 *
 * HISTORY
 * 09-Apr-97  Tsutomu Owa (owa) at the University of Washington
 *	Change interface names so that these don't conflict w/
 *	those used by user/net.
 *
 * 03-Feb-97  Tsutomu Owa (owa) at the University of Washington
 *	Copied from user/net/tcp/src.
 *
 * 13-Jun-96  Marc Fiuczynski (mef) at the University of Washington
 *	Changed type to use a BIT SET for tcp flags.
 *	General cleanup.
 *
 *)

INTERFACE StcpTcpPktFormat;
IMPORT Ctypes;
IMPORT StcpNet;
(* 
   Harbison p258: packed types only need to be packed in records,
   objects, and arrays.
*)
CONST
  TH_FIN  = 16_01;
  TH_SYN  = 16_02;
  TH_RST  = 16_04;
  TH_PUSH = 16_08;
  TH_ACK  = 16_10;
  TH_URG  = 16_20;

TYPE
  Flag = { fin, syn, rst, push, ack, urg, 
           garbage1, garbage2};
  Flags = BITS 8 FOR SET OF Flag;
  Seq = BITS 32 FOR Ctypes.unsigned_int;
(* XXX why should this be int?...
  Seq = BITS 32 FOR Ctypes.int;
 *)

TYPE Header = RECORD
  sport: BITS 16 FOR Ctypes.unsigned_short;
  dport: BITS 16 FOR Ctypes.unsigned_short;
  seq: Seq;
  ack_seq: Seq;
  (* 
     The order of the following fields are CPU dependent.
     resevered1: BITS 4 FOR [16_0 .. 16_f];
     doff: BITS 4 FOR [16_0 .. 16_f];
     fin: BITS 1 FOR [16_0 .. 16_1]; sender has reached end of its byte stream
     syn: BITS 1 FOR [16_0 .. 16_1]; synchronize sequence numbers
     rst: BITS 1 FOR [16_0 .. 16_1]; reset the connection
     psh: BITS 1 FOR [16_0 .. 16_1]; this segment requests a push
     ack: BITS 1 FOR [16_0 .. 16_1]; acknowledgement field is valid
     urg: BITS 1 FOR [16_0 .. 16_1]; urgent pointer field is valid
     resevered2: BITS 2 FOR [16_0 .. 16_2];
  *)
  (* little endian *)
  x2: StcpNet.nible;
  xoff: StcpNet.nible;
  flags: Flags;
  window: BITS 16 FOR Ctypes.unsigned_short;  
  check: BITS 16 FOR Ctypes.unsigned_short;  
  urg_ptr: BITS 16 FOR Ctypes.unsigned_short;  
END;

(* ????
<* OBSOLETE *> TYPE T = UNTRACED REF Header;
TYPE NewT = Header;
 *)
TYPE T = Header;
END StcpTcpPktFormat.
